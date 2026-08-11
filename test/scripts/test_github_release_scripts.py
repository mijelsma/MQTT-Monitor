from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


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
                    "packageId": "com.mijelsma.mqtt-monitor",
                    "appName": "MQTT Monitor.app"
                    if platform == "macos"
                    else "Mqtt Monitor"
                    if platform == "windows"
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
                    "install": {"strategy": "test"},
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


if __name__ == "__main__":
    unittest.main()
