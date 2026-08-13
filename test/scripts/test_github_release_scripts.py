from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY_ROOT / "scripts"))

from desktop_release_contract import (  # noqa: E402
    PACKAGE_IDS,
    parse_release_tag,
    validate_release_descriptor,
)


class GitHubReleaseScriptsTest(unittest.TestCase):
    def test_prepares_and_assembles_complete_release(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary = Path(temporary_directory)
            assets = temporary / "assets"

            for platform, kind, extension in (
                ("windows", "innoInstaller", ".exe"),
                ("macos", "dmg", ".dmg"),
                ("linux", "zip", ".zip"),
            ):
                input_root = temporary / platform
                release_directory = input_root / "0.3.0" / platform
                release_directory.mkdir(parents=True)
                artifact = release_directory / f"original{extension}"
                artifact.write_bytes(f"artifact-{platform}".encode())
                descriptor = {
                    "schemaVersion": 3,
                    "packageId": PACKAGE_IDS[platform],
                    "appName": "MQTT Monitor.app"
                    if platform == "macos"
                    else "MQTT Monitor",
                    "version": "0.3.0",
                    "buildNumber": 42,
                    "platform": platform,
                    "channel": "stable",
                    "artifact": {
                        "kind": kind,
                        "url": f"https://old.invalid/{artifact.name}",
                        "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
                        "length": artifact.stat().st_size,
                    },
                    "install": {
                        "strategy": "innoInstaller",
                        "inno": {},
                    }
                    if platform == "windows"
                    else {"strategy": "test"},
                    "minimumUpdaterVersion": "2.0.0",
                    "generatedAt": "2026-08-11T10:00:00Z",
                }
                (release_directory / "release.json").write_text(
                    json.dumps(descriptor), encoding="utf-8"
                )

                subprocess.run(
                    [
                        sys.executable,
                        str(REPOSITORY_ROOT / "scripts/prepare_github_release.py"),
                        "--platform",
                        platform,
                        "--tag",
                        "v0.3.0",
                        "--repository",
                        "mijelsma/MQTT-Monitor",
                        "--input-root",
                        str(input_root),
                        "--output",
                        str(assets),
                    ],
                    check=True,
                )

            subprocess.run(
                [
                    sys.executable,
                    str(REPOSITORY_ROOT / "scripts/assemble_github_release.py"),
                    "--tag",
                    "v0.3.0",
                    "--repository",
                    "mijelsma/MQTT-Monitor",
                    "--assets",
                    str(assets),
                ],
                check=True,
            )

            archive = json.loads(
                (assets / "app-archive.json").read_text(encoding="utf-8")
            )
            self.assertEqual(archive["schemaVersion"], 3)
            self.assertEqual(archive["appName"], "MQTT Monitor")
            self.assertEqual(
                [item["platform"] for item in archive["items"]],
                ["windows", "macos", "linux"],
            )
            self.assertEqual(
                archive["items"][0]["release"],
                "https://github.com/mijelsma/MQTT-Monitor/releases/download/"
                "v0.3.0/release-windows.json",
            )
            self.assertTrue((assets / "mqtt-monitor-0.3.0-windows-setup.exe").is_file())
            self.assertTrue((assets / "mqtt-monitor-0.3.0-macos.dmg").is_file())
            self.assertTrue((assets / "mqtt-monitor-0.3.0-linux.zip").is_file())

    def test_release_tag_determines_exact_version_and_channel(self) -> None:
        self.assertEqual(parse_release_tag("v1.0.0"), ("1.0.0", "stable"))
        self.assertEqual(
            parse_release_tag("v1.0.0-beta.2"),
            ("1.0.0-beta.2", "beta"),
        )
        for invalid in (
            "0.3.0",
            "v0.3",
            "v0.3.0-",
            "v0.3.0-beta.",
            "nightly",
        ):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    parse_release_tag(invalid)

    def test_descriptor_contract_rejects_cross_platform_or_channel_drift(self) -> None:
        descriptor = {
            "schemaVersion": 3,
            "packageId": PACKAGE_IDS["linux"],
            "appName": "MQTT Monitor",
            "version": "1.0.0",
            "buildNumber": 42,
            "platform": "linux",
            "channel": "stable",
            "artifact": {
                "kind": "zip",
                "url": "https://github.com/mijelsma/MQTT-Monitor/releases/download/v1.0.0/mqtt-monitor-1.0.0-linux.zip",
                "sha256": "a" * 64,
                "length": 200,
            },
            "install": {"strategy": "test"},
            "minimumUpdaterVersion": "2.0.0",
        }

        validate_release_descriptor(
            descriptor,
            platform="linux",
            tag="v1.0.0",
            repository="mijelsma/MQTT-Monitor",
            require_hosted_url=True,
        )

        invalid_cases = {
            "channel": {**descriptor, "channel": "beta"},
            "package": {**descriptor, "packageId": "mqtt_monitor"},
            "version": {**descriptor, "version": "1.0.1"},
            "digest": {
                **descriptor,
                "artifact": {**descriptor["artifact"], "sha256": "not-a-hash"},
            },
        }
        for name, invalid in invalid_cases.items():
            with self.subTest(name=name):
                with self.assertRaises(ValueError):
                    validate_release_descriptor(
                        invalid,
                        platform="linux",
                        tag="v1.0.0",
                        repository="mijelsma/MQTT-Monitor",
                        require_hosted_url=True,
                    )

    def test_windows_release_contract_rejects_portable_zip(self) -> None:
        descriptor = {
            "schemaVersion": 3,
            "packageId": PACKAGE_IDS["windows"],
            "appName": "MQTT Monitor",
            "version": "1.0.0",
            "buildNumber": 42,
            "platform": "windows",
            "channel": "stable",
            "artifact": {
                "kind": "zip",
                "url": "https://github.com/mijelsma/MQTT-Monitor/releases/"
                "download/v1.0.0/mqtt-monitor-1.0.0-windows.zip",
                "sha256": "a" * 64,
                "length": 200,
            },
            "install": {"strategy": "wholeDirectoryReplace"},
            "minimumUpdaterVersion": "2.0.0",
        }

        with self.assertRaises(ValueError):
            validate_release_descriptor(
                descriptor,
                platform="windows",
                tag="v1.0.0",
                repository="mijelsma/MQTT-Monitor",
                require_hosted_url=True,
            )


if __name__ == "__main__":
    unittest.main()
