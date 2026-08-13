from __future__ import annotations

import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


def _read(relative_path: str) -> str:
    return (REPOSITORY_ROOT / relative_path).read_text(encoding="utf-8")


class DesktopPlatformContractsTest(unittest.TestCase):
    def test_supported_desktop_identity_is_consistent(self) -> None:
        macos_config = _read("macos/Runner/Configs/AppInfo.xcconfig")
        linux_config = _read("linux/CMakeLists.txt")
        windows_resources = _read("windows/runner/Runner.rc")

        self.assertIn(
            "PRODUCT_BUNDLE_IDENTIFIER = com.micheljelsma.mqttmonitor",
            macos_config,
        )
        self.assertIn(
            'set(APPLICATION_ID "com.micheljelsma.mqttmonitor")',
            linux_config,
        )
        self.assertIn('VALUE "ProductName", "MQTT Monitor"', windows_resources)
        self.assertIn('VALUE "CompanyName", "Michel Jelsma"', windows_resources)
        self.assertIn("Licensed under the GNU AGPL v3.0", windows_resources)

    def test_native_window_chrome_handlers_match_the_dart_contract(self) -> None:
        sources = {
            "dart": _read("lib/core/platform/window_chrome.dart"),
            "macos": _read("macos/Runner/MainFlutterWindow.swift"),
            "windows": _read("windows/runner/flutter_window.cpp"),
        }
        for platform, source in sources.items():
            with self.subTest(platform=platform):
                self.assertIn("mqtt_monitor/window_chrome", source)
                self.assertIn("setAppearance", source)

    def test_macos_release_lane_keeps_all_apple_trust_gates(self) -> None:
        release_contract = _read(".github/workflows/release.yml") + _read(
            "scripts/publish_desktop_update.sh"
        )
        entitlements = _read("macos/Runner/Release.entitlements")

        for contract in (
            "MACOS_DEVELOPER_ID_APPLICATION",
            "notarize: true",
            "staple: true",
            "gatekeeperAssess: true",
        ):
            self.assertIn(contract, release_contract)
        self.assertIn("com.apple.security.network.client", entitlements)
        self.assertNotIn("com.apple.security.get-task-allow", entitlements)

    def test_windows_release_lane_builds_a_real_installer(self) -> None:
        workflow = _read(".github/workflows/release.yml")
        publish_script = _read("scripts/publish_desktop_update.sh")
        installer = _read("windows/installer/mqtt_monitor.iss")

        self.assertIn("Inno Setup 6\\ISCC.exe", workflow)
        for contract in (
            "kind: inno",
            "mode: script",
            "windows/installer/mqtt_monitor.iss",
            "requiresElevation: never",
        ):
            self.assertIn(contract, publish_script)
        for contract in (
            "AppId={{E733335C-5020-45E9-A145-935CDC3FF42A}",
            '#define AppExecutable "mqtt_monitor.exe"',
            "WizardStyle=modern",
            "PrivilegesRequired=lowest",
            "UninstallDisplayIcon=",
            "VersionInfoVersion={#InstallerFileVersion}",
            'Name: "desktopicon"',
        ):
            self.assertIn(contract, installer)

    def test_desktop_updater_privacy_manifest_is_packaged_as_a_resource(self) -> None:
        podfile = _read("macos/Podfile")

        self.assertIn("target.name == 'desktop_updater'", podfile)
        self.assertIn("PrivacyInfo.xcprivacy", podfile)
        self.assertIn("target.resources_build_phase.add_file_reference", podfile)

    def test_normal_ci_is_scoped_to_main_and_develop_quality_checks(self) -> None:
        workflow = _read(".github/workflows/desktop-ci.yml")
        analysis_options = _read("analysis_options.yaml")

        self.assertIn("branches: [main, develop]", workflow)
        self.assertNotIn("improvement/refactor", workflow)
        self.assertNotIn("desktop-build:", workflow)
        self.assertNotIn("runs-on: windows", workflow)
        self.assertNotIn("runs-on: macos", workflow)
        self.assertNotIn("apt-get", workflow)
        self.assertIn("cancel-in-progress: true", workflow)
        self.assertIn("python3 scripts/generate_git_info.py", workflow)
        self.assertLess(
            workflow.index("python3 scripts/generate_git_info.py"),
            workflow.index("flutter analyze"),
        )
        self.assertIn("flutter analyze", workflow)
        self.assertNotIn("--no-fatal", workflow)
        self.assertIn("flutter test", workflow)
        self.assertIn("test_*.py", workflow)
        self.assertIn("lib/generated/intl/**", analysis_options)

    def test_tagged_release_builds_every_supported_desktop_target(self) -> None:
        workflow = _read(".github/workflows/release.yml")

        self.assertIn("tags:", workflow)
        self.assertIn("- 'v*'", workflow)
        for platform in ("windows", "macos", "linux"):
            self.assertIn(f"  {platform}:", workflow)
        self.assertIn("needs: [windows, macos, linux]", workflow)
        self.assertIn("python3 scripts/generate_git_info.py", workflow)

    def test_mobile_and_web_scaffolds_are_explicitly_dormant(self) -> None:
        support_policy = _read("docs/platform-support.md")

        self.assertIn("supported release matrix is macOS", support_policy)
        self.assertIn("Windows, and Linux", support_policy)
        self.assertIn("Android, iOS, and web", support_policy)
        self.assertIn("not supported release targets", support_policy)


if __name__ == "__main__":
    unittest.main()
