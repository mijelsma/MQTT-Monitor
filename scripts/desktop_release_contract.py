#!/usr/bin/env python3
"""Shared validation rules for MQTT Monitor desktop releases."""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from urllib.parse import unquote, urlparse


SUPPORTED_PLATFORMS = ("windows", "macos", "linux")
CANONICAL_APP_NAME = "MQTT Monitor"
PACKAGE_IDS = {
    "windows": "mqtt_monitor",
    "macos": "com.micheljelsma.mqttmonitor",
    "linux": "com.micheljelsma.mqttmonitor",
}

_TAG_PATTERN = re.compile(
    r"^v(?P<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?)$"
)
_REPOSITORY_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
_SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
_VERSION_PATTERN = re.compile(
    r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
)


def parse_release_tag(tag: str) -> tuple[str, str]:
    """Returns the exact version and stable/beta channel for a release tag."""

    match = _TAG_PATTERN.fullmatch(tag)
    if match is None:
        raise ValueError(
            "Release tags must use vX.Y.Z or vX.Y.Z-prerelease syntax."
        )
    version = match.group("version")
    return version, "beta" if "-" in version else "stable"


def validate_repository(repository: str) -> None:
    if _REPOSITORY_PATTERN.fullmatch(repository) is None:
        raise ValueError("Repository must use OWNER/REPOSITORY syntax.")


def display_name(value: str) -> str:
    for suffix in (".app", ".exe"):
        if value.endswith(suffix):
            return value[: -len(suffix)]
    return value


def validate_release_descriptor(
    descriptor: object,
    *,
    platform: str,
    tag: str,
    repository: str,
    require_hosted_url: bool,
) -> dict[str, object]:
    """Validates one package-produced schema-v3 release descriptor."""

    if platform not in SUPPORTED_PLATFORMS:
        raise ValueError(f"Unsupported desktop platform: {platform}")
    validate_repository(repository)
    version, channel = parse_release_tag(tag)
    if not isinstance(descriptor, dict):
        raise ValueError("Release descriptor must be a JSON object.")
    if descriptor.get("schemaVersion") != 3:
        raise ValueError("Release descriptor must use schema version 3.")
    if descriptor.get("platform") != platform:
        raise ValueError(f"Release descriptor must target {platform}.")
    if descriptor.get("version") != version:
        raise ValueError(f"Release descriptor does not match tag {tag}.")
    if descriptor.get("channel") != channel:
        raise ValueError(
            f"Release descriptor channel must be {channel} for tag {tag}."
        )
    if display_name(str(descriptor.get("appName", ""))) != CANONICAL_APP_NAME:
        raise ValueError("Release descriptor has the wrong application name.")
    if descriptor.get("packageId") != PACKAGE_IDS[platform]:
        raise ValueError(
            f"Release descriptor has the wrong {platform} package identifier."
        )

    build_number = descriptor.get("buildNumber")
    if (
        not isinstance(build_number, int)
        or isinstance(build_number, bool)
        or build_number < 1
    ):
        raise ValueError(
            "Release descriptor buildNumber must be a positive integer."
        )
    minimum_updater = descriptor.get("minimumUpdaterVersion")
    if (
        not isinstance(minimum_updater, str)
        or _VERSION_PATTERN.fullmatch(minimum_updater) is None
    ):
        raise ValueError("Release descriptor has an invalid minimumUpdaterVersion.")
    if not isinstance(descriptor.get("install"), dict):
        raise ValueError("Release descriptor must include install metadata.")

    artifact = descriptor.get("artifact")
    if not isinstance(artifact, dict):
        raise ValueError("Release descriptor must include one artifact.")
    allowed_kinds = {
        "windows": {"innoInstaller"},
        "macos": {"dmg", "pkgInstaller"},
        "linux": {"zip"},
    }[platform]
    if artifact.get("kind") not in allowed_kinds:
        raise ValueError(f"Unsupported {platform} artifact kind.")
    install = descriptor["install"]
    if artifact.get("kind") == "innoInstaller":
        if install.get("strategy") != "innoInstaller" or not isinstance(
            install.get("inno"), dict
        ):
            raise ValueError(
                "Windows installer releases require Inno install metadata."
            )
    length = artifact.get("length")
    if not isinstance(length, int) or isinstance(length, bool) or length < 1:
        raise ValueError("Release artifact length must be a positive integer.")
    digest = artifact.get("sha256")
    if not isinstance(digest, str) or _SHA256_PATTERN.fullmatch(digest) is None:
        raise ValueError("Release artifact must have a lowercase SHA-256 digest.")
    raw_url = artifact.get("url")
    if not isinstance(raw_url, str):
        raise ValueError("Release artifact URL must be a string.")
    parsed_url = urlparse(raw_url)
    artifact_name = unquote(Path(parsed_url.path).name)
    if not artifact_name:
        raise ValueError("Release artifact URL must name a file.")
    if require_hosted_url:
        release_base = f"https://github.com/{repository}/releases/download/{tag}"
        if raw_url != f"{release_base}/{artifact_name}":
            raise ValueError(
                "Release artifact URL is outside the tagged GitHub release."
            )

    return descriptor


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--print", choices=("version", "channel"))
    parser.add_argument("--expect-channel", choices=("stable", "beta"))
    args = parser.parse_args()

    version, channel = parse_release_tag(args.tag)
    if args.expect_channel is not None and args.expect_channel != channel:
        raise ValueError(
            f"Tag {args.tag} belongs to {channel}, not {args.expect_channel}."
        )
    if args.print == "version":
        print(version)
    elif args.print == "channel":
        print(channel)


if __name__ == "__main__":
    main()
