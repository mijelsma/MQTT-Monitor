#!/usr/bin/env python3
"""Validate platform assets and create a release-scoped app archive."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import unquote, urlparse


PLATFORMS = ("windows", "macos", "linux")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _display_name(value: str) -> str:
    for suffix in (".app", ".exe"):
        if value.endswith(suffix):
            return value[: -len(suffix)]
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--assets", type=Path, required=True)
    args = parser.parse_args()

    release_base = f"https://github.com/{args.repository}/releases/download/{args.tag}"
    expected_version = args.tag[1:] if args.tag.startswith("v") else args.tag
    items: list[dict[str, object]] = []
    app_names: set[str] = set()
    channels: set[str] = set()

    for platform in PLATFORMS:
        descriptor_path = args.assets / f"release-{platform}.json"
        descriptor = json.loads(descriptor_path.read_text(encoding="utf-8"))
        if descriptor.get("schemaVersion") != 3:
            raise ValueError(f"{descriptor_path} is not a schema-v3 descriptor")
        if descriptor.get("platform") != platform:
            raise ValueError(f"{descriptor_path} has the wrong platform")
        if descriptor.get("version") != expected_version:
            raise ValueError(f"{descriptor_path} does not match tag {args.tag}")

        app_names.add(_display_name(descriptor["appName"]))
        channels.add(descriptor["channel"])
        artifact = descriptor["artifact"]
        artifact_name = unquote(Path(urlparse(artifact["url"]).path).name)
        artifact_path = args.assets / artifact_name
        if not artifact_path.is_file():
            raise FileNotFoundError(f"Missing release asset {artifact_name}")
        if artifact_path.stat().st_size != artifact["length"]:
            raise ValueError(f"Length mismatch for {artifact_name}")
        if _sha256(artifact_path) != artifact["sha256"]:
            raise ValueError(f"SHA-256 mismatch for {artifact_name}")
        if artifact["url"] != f"{release_base}/{artifact_name}":
            raise ValueError(f"Unexpected download URL for {artifact_name}")

        item: dict[str, object] = {
            "version": descriptor["version"],
            "platform": platform,
            "channel": descriptor["channel"],
            "mandatory": False,
            "release": f"{release_base}/release-{platform}.json",
        }
        if descriptor.get("buildNumber") is not None:
            item["buildNumber"] = descriptor["buildNumber"]
        items.append(item)

    if len(app_names) != 1:
        raise ValueError(f"Platform descriptors disagree on app name: {sorted(app_names)}")
    if len(channels) != 1:
        raise ValueError(f"Platform descriptors disagree on channel: {sorted(channels)}")

    archive = {
        "schemaVersion": 3,
        "appName": app_names.pop(),
        "items": items,
    }
    (args.assets / "app-archive.json").write_text(
        json.dumps(archive, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
