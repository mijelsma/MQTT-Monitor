#!/usr/bin/env python3
"""Generate ``lib/generated/git_info.dart`` and update ``pubspec.yaml``'s
``version`` field from git tags.

Run before building:

    python3 scripts/generate_git_info.py

The derived values come from git:

* ``git describe --tags --dirty``  → describe string, version, build number, dirty flag
* ``git rev-parse --short HEAD``   → short commit hash
* ``git rev-parse HEAD``           → full commit hash
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
GIT_INFO_PATH = PROJECT_ROOT / "lib" / "generated" / "git_info.dart"
PUBSPEC_PATH = PROJECT_ROOT / "pubspec.yaml"

TAG_VERSION_RE = re.compile(r"^v?(\d+\.\d+\.\d+)")
COMMITS_SINCE_TAG_RE = re.compile(r"^\D*\d+\.\d+\.\d+-(\d+)-g")
PUBSPEC_VERSION_RE = re.compile(r"version:\s*\S+")


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
    return match.group(1) if match else "0.0.0"


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


def update_pubspec_version(tag_version: str, build_number: int) -> None:
    content = PUBSPEC_PATH.read_text(encoding="utf-8")
    updated = PUBSPEC_VERSION_RE.sub(
        f"version: {tag_version}+{build_number}",
        content,
        count=1,
    )
    PUBSPEC_PATH.write_text(updated, encoding="utf-8")


def main() -> int:
    try:
        describe = run(["git", "describe", "--tags", "--dirty"])
        commit_hash = run(["git", "rev-parse", "--short", "HEAD"])
        full_hash = run(["git", "rev-parse", "HEAD"])

        tag_version = parse_tag_version(describe)
        build_number = parse_commits_since_tag(describe)
        is_dirty = describe.endswith("-dirty")

        write_git_info(
            describe, tag_version, build_number, commit_hash, full_hash, is_dirty
        )
        update_pubspec_version(tag_version, build_number)

        print(f"Generated git_info.dart  (describe: {describe})")
        print(f"Updated pubspec.yaml     (version: {tag_version}+{build_number})")
        return 0
    except GenerationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())