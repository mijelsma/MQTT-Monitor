#!/usr/bin/env python3
"""Generate ``lib/generated/git_info.dart`` from git state.

Run before building:

    python3 scripts/generate_git_info.py

For a tagged desktop release, also derive and inject the native app version
after Git metadata has been captured:

    python3 scripts/generate_git_info.py --prepare-release-version

The derived values come from git:

* ``git describe --tags --dirty``  → describe string, version, build number, dirty flag
* ``git rev-parse --short HEAD``   → short commit hash
* ``git rev-parse HEAD``           → full commit hash
"""

from __future__ import annotations

import re
import subprocess
import sys
from argparse import ArgumentParser
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
GIT_INFO_PATH = PROJECT_ROOT / "lib" / "generated" / "git_info.dart"
PUBSPEC_PATH = PROJECT_ROOT / "pubspec.yaml"

# Tags may be 2- or 3-component (e.g. ``0.1`` or ``0.1.0``). We capture the
# numeric prefix and normalize to a full ``X.Y.Z`` for the generated file.
TAG_VERSION_RE = re.compile(r"^v?(\d+\.\d+(?:\.\d+)?)")
COMMITS_SINCE_TAG_RE = re.compile(r"^\D*\d+\.\d+(?:\.\d+)?-(\d+)-g")
RELEASE_TAG_RE = re.compile(r"^v?(\d+\.\d+\.\d+)(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$")
PUBSPEC_VERSION_RE = re.compile(r"^version:\s*.*$", re.MULTILINE)


class GenerationError(RuntimeError):
    """Raised when a git command fails or output cannot be parsed."""


def run(command: list[str]) -> str:
    try:
        result = subprocess.run(
            command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError as error:
        raise GenerationError(
            f"Command not found: {command[0]}. Is git installed and on PATH?"
        ) from error

    if result.returncode != 0:
        details = (result.stderr or result.stdout).strip()
        suffix = f"\n{details}" if details else ""
        raise GenerationError(
            f"Command failed: {' '.join(command)}{suffix}"
        )
    return result.stdout.strip()


def parse_tag_version(describe: str) -> str:
    match = TAG_VERSION_RE.match(describe)
    if not match:
        return "0.0.0"
    parts = match.group(1).split(".")
    # Pad to three components so ``0.1`` becomes ``0.1.0``.
    while len(parts) < 3:
        parts.append("0")
    return ".".join(parts)


def parse_commits_since_tag(describe: str) -> int:
    match = COMMITS_SINCE_TAG_RE.match(describe)
    count = int(match.group(1)) if match else 0
    return count if count > 0 else 1


def write_git_info(
    describe: str,
    tag_version: str,
    build_number: int,
    commit_hash: str,
    full_hash: str,
    is_dirty: bool,
) -> None:
    GIT_INFO_PATH.parent.mkdir(parents=True, exist_ok=True)
    GIT_INFO_PATH.write_text(
        "// GENERATED FILE — DO NOT EDIT.\n"
        "// Run: python3 scripts/generate_git_info.py\n"
        "\n"
        "class GitInfo {\n"
        "  const GitInfo._();\n"
        "\n"
        '  /// Full `git describe --tags --dirty` output (e.g. "v0.1.0-3-gabcdef-dirty").\n'
        f"  static const String describe = '{describe}';\n"
        "\n"
        '  /// Semantic version from the nearest tag (e.g. "0.1.0").\n'
        f"  static const String version = '{tag_version}';\n"
        "\n"
        "  /// Build number (commits since last tag, or 1 if on the tag).\n"
        f"  static const int buildNumber = {build_number};\n"
        "\n"
        '  /// Short commit hash (e.g. "abcdef0").\n'
        f"  static const String commitHash = '{commit_hash}';\n"
        "\n"
        "  /// Full commit hash.\n"
        f"  static const String fullHash = '{full_hash}';\n"
        "\n"
        "  /// Whether the working tree had uncommitted changes at build time.\n"
        f"  static const bool dirty = {'true' if is_dirty else 'false'};\n"
        "}\n",
        encoding="utf-8",
    )


def prepare_release_version() -> tuple[str, int]:
    """Writes a valid native version from the exact release tag.

    macOS requires a numeric three-component CFBundleShortVersionString. The
    beta/stable channel belongs in the Git tag, not in pubspec's native build
    name. The commit count is automatic and monotonically increases for normal
    release history, so developers never need to maintain ``+<build>``.
    """

    tag = run(["git", "describe", "--tags", "--exact-match", "HEAD"])
    match = RELEASE_TAG_RE.match(tag)
    if not match:
        raise GenerationError(
            "Release tags must look like vX.Y.Z or vX.Y.Z-beta.N; "
            f"got {tag!r}."
        )

    version = match.group(1)
    build_number = max(1, int(run(["git", "rev-list", "--count", "HEAD"])))
    content = PUBSPEC_PATH.read_text(encoding="utf-8")
    updated, replacements = PUBSPEC_VERSION_RE.subn(
        f"version: {version}+{build_number}", content, count=1
    )
    if replacements != 1:
        raise GenerationError("Could not find one version: line in pubspec.yaml.")
    PUBSPEC_PATH.write_text(updated, encoding="utf-8")
    return version, build_number


def main() -> int:
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        "--prepare-release-version",
        action="store_true",
        help="derive the numeric pubspec version from the exact Git release tag",
    )
    args = parser.parse_args()

    try:
        # Read every Git value before writing generated files. This preserves
        # clean Git metadata even though the release version is injected next.
        describe = run(["git", "describe", "--tags", "--dirty"])
        commit_hash = run(["git", "rev-parse", "--short", "HEAD"])
        full_hash = run(["git", "rev-parse", "HEAD"])

        tag_version = parse_tag_version(describe)
        build_number = parse_commits_since_tag(describe)
        is_dirty = describe.endswith("-dirty")

        write_git_info(
            describe, tag_version, build_number, commit_hash, full_hash, is_dirty
        )

        print(f"Generated git_info.dart  (describe: {describe})")
        if args.prepare_release_version:
            release_version, release_build_number = prepare_release_version()
            print(
                "Prepared pubspec.yaml for release: "
                f"{release_version}+{release_build_number}"
            )
        else:
            print(f"version: {tag_version}+{build_number}  (pubspec.yaml left untouched)")
        return 0
    except GenerationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
