#!/usr/bin/env python3
"""Prepare one desktop_updater package as flat GitHub Release assets."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path
from urllib.parse import unquote, urlparse


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _artifact_name(version: str, platform: str, kind: str) -> str:
    suffix = {
        "innoInstaller": "windows-setup.exe",
        "dmg": "macos.dmg",
        "pkgInstaller": "macos.pkg",
        "zip": f"{platform}.zip",
    }.get(kind)
    if suffix is None:
        raise ValueError(f"Unsupported artifact kind: {kind}")
    return f"mqtt-monitor-{version}-{suffix}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--input-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    descriptors = list(args.input_root.rglob("release.json"))
    if len(descriptors) != 1:
        raise ValueError(
            f"Expected one release.json below {args.input_root}, found {len(descriptors)}"
        )

    source_descriptor = descriptors[0]
    descriptor = json.loads(source_descriptor.read_text(encoding="utf-8"))
    if descriptor.get("platform") != args.platform:
        raise ValueError(
            f"Descriptor platform is {descriptor.get('platform')!r}, expected {args.platform!r}"
        )

    artifact = descriptor["artifact"]
    source_name = unquote(Path(urlparse(artifact["url"]).path).name)
    source_artifact = source_descriptor.parent / source_name
    if not source_artifact.is_file():
        candidates = [
            path for path in source_descriptor.parent.iterdir() if path.is_file() and path != source_descriptor
        ]
        if len(candidates) != 1:
            raise FileNotFoundError(f"Could not identify artifact next to {source_descriptor}")
        source_artifact = candidates[0]

    actual_length = source_artifact.stat().st_size
    actual_digest = _sha256(source_artifact)
    if artifact.get("length") != actual_length:
        raise ValueError("Generated descriptor has the wrong artifact length")
    if artifact.get("sha256") != actual_digest:
        raise ValueError("Generated descriptor has the wrong artifact SHA-256")

    args.output.mkdir(parents=True, exist_ok=True)
    destination_name = _artifact_name(
        descriptor["version"], args.platform, artifact["kind"]
    )
    destination_artifact = args.output / destination_name
    shutil.copy2(source_artifact, destination_artifact)

    release_base = f"https://github.com/{args.repository}/releases/download/{args.tag}"
    artifact["url"] = f"{release_base}/{destination_name}"
    destination_descriptor = args.output / f"release-{args.platform}.json"
    destination_descriptor.write_text(
        json.dumps(descriptor, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
