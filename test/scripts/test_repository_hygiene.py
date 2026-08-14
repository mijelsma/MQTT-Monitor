from __future__ import annotations

import re
import unittest
from pathlib import Path
from urllib.parse import unquote


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
MARKDOWN_FILES = [
    REPOSITORY_ROOT / "README.md",
    *sorted((REPOSITORY_ROOT / "docs").glob("*.md")),
]


def _local_targets(markdown: Path) -> set[Path]:
    source = markdown.read_text(encoding="utf-8")
    raw_targets = {
        *re.findall(r"\[[^\]]+\]\(([^)]+)\)", source),
        *re.findall(r"(?:src|href)=[\"']([^\"']+)[\"']", source),
    }
    targets: set[Path] = set()
    for raw_target in raw_targets:
        target = raw_target.strip().strip("<>").split("#", 1)[0]
        if not target or target.startswith(("http://", "https://", "mailto:")):
            continue
        targets.add((markdown.parent / unquote(target)).resolve())
    return targets


class RepositoryHygieneTest(unittest.TestCase):
    def test_local_documentation_links_resolve_inside_the_repository(self) -> None:
        for markdown in MARKDOWN_FILES:
            for target in _local_targets(markdown):
                with self.subTest(document=markdown.name, target=target):
                    self.assertTrue(target.is_relative_to(REPOSITORY_ROOT))
                    self.assertTrue(target.exists())

    def test_documentation_images_have_a_current_reference(self) -> None:
        referenced = set().union(*(_local_targets(path) for path in MARKDOWN_FILES))
        screenshots = set((REPOSITORY_ROOT / "docs" / "images").iterdir())

        self.assertEqual(screenshots, screenshots.intersection(referenced))

    def test_removed_dependencies_and_placeholders_stay_removed(self) -> None:
        pubspec = (REPOSITORY_ROOT / "pubspec.yaml").read_text(encoding="utf-8")
        for dependency in ("cupertino_icons", "build_runner", "arb_generator", "dmg"):
            with self.subTest(dependency=dependency):
                self.assertNotRegex(pubspec, rf"(?m)^\s+{dependency}:")
        self.assertNotIn("generate: true", pubspec)

        for relative_path in (
            "lib/core/broker/broker_storage_migrator.dart",
            "lib/shared/widgets/ui_navigation_row.dart",
            "test/widget_test.dart",
        ):
            with self.subTest(path=relative_path):
                self.assertFalse((REPOSITORY_ROOT / relative_path).exists())

    def test_generated_inputs_and_commands_are_documented(self) -> None:
        architecture = (REPOSITORY_ROOT / "docs" / "architecture.md").read_text(
            encoding="utf-8"
        )
        updates = (REPOSITORY_ROOT / "docs" / "updates.md").read_text(
            encoding="utf-8"
        )
        icon_generator = (
            REPOSITORY_ROOT / "scripts" / "generate_app_icons.py"
        ).read_text(encoding="utf-8")

        for contract in (
            "dart run intl_utils:generate",
            "python3 scripts/generate_git_info.py",
            "python3 scripts/generate_app_icons.py",
        ):
            self.assertIn(contract, architecture)
        self.assertIn("assets/icon_purple.svg", architecture)
        self.assertIn('"assets" / "icon_purple.svg"', icon_generator)
        self.assertIn("desktop_updater.example.yaml", updates)


if __name__ == "__main__":
    unittest.main()
