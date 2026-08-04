#!/usr/bin/env python3
"""Generate all Flutter launcher icons from an SVG source.

Examples:
    python3 scripts/generate_app_icons.py
    python3 scripts/generate_app_icons.py ~/Downloads/new_icon.svg --name icon_green
    python3 scripts/generate_app_icons.py new_icon.svg -n icon_green -b '#102030'

The SVG defaults to assets/icon_purple.svg. The name is used for the preserved
source copy in assets/<name>.svg; native launcher-icon filenames stay fixed.
"""

from __future__ import annotations

import argparse
import html
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SVG = PROJECT_ROOT / "assets" / "icon_purple.svg"
DEFAULT_BACKGROUND = "#1A0A2E"
MASTER_SIZE = 1024


class GenerationError(RuntimeError):
    """Raised when an external renderer or converter fails."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate Android, iOS, macOS, web, and Windows app icons from an SVG."
    )
    parser.add_argument(
        "svg",
        nargs="?",
        type=Path,
        default=DEFAULT_SVG,
        help=f"source SVG (default: {DEFAULT_SVG.relative_to(PROJECT_ROOT)})",
    )
    parser.add_argument(
        "-n",
        "--name",
        help="source-copy name in assets/ without .svg (default: input filename)",
    )
    parser.add_argument(
        "-b",
        "--background",
        default=DEFAULT_BACKGROUND,
        help=(
            "opaque background used for iOS and maskable web icons "
            f"(default: {DEFAULT_BACKGROUND})"
        ),
    )
    return parser.parse_args()


def validate_inputs(args: argparse.Namespace) -> tuple[Path, str, str]:
    source = args.svg.expanduser().resolve()
    if not source.is_file():
        raise GenerationError(f"SVG not found: {source}")
    if source.suffix.lower() != ".svg":
        raise GenerationError(f"Expected an .svg file, got: {source.name}")

    name = args.name or source.stem
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        raise GenerationError(
            "Name may contain only letters, numbers, underscores, and hyphens."
        )

    background = args.background.upper()
    if not re.fullmatch(r"#[0-9A-F]{6}", background):
        raise GenerationError("Background must be a hex color such as #1A0A2E.")

    return source, name, background


def find_chrome() -> Path:
    configured = os.environ.get("MQTT_MONITOR_CHROME")
    if configured:
        candidate = Path(configured).expanduser()
        if candidate.is_file():
            return candidate
        raise GenerationError(
            f"MQTT_MONITOR_CHROME does not point to a file: {candidate}"
        )

    command_names = (
        "google-chrome",
        "google-chrome-stable",
        "chromium",
        "chromium-browser",
        "microsoft-edge",
    )
    for command_name in command_names:
        executable = shutil.which(command_name)
        if executable:
            return Path(executable)

    known_paths = (
        Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
        Path("/Applications/Chromium.app/Contents/MacOS/Chromium"),
        Path("/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"),
        Path(os.environ.get("PROGRAMFILES", "C:/Program Files"))
        / "Google/Chrome/Application/chrome.exe",
        Path(os.environ.get("PROGRAMFILES(X86)", "C:/Program Files (x86)"))
        / "Google/Chrome/Application/chrome.exe",
    )
    for candidate in known_paths:
        if candidate.is_file():
            return candidate

    raise GenerationError(
        "Chrome, Chromium, or Edge is required to render the SVG. "
        "Install one or set MQTT_MONITOR_CHROME to its executable path."
    )


def find_magick() -> Path:
    executable = shutil.which("magick")
    if executable:
        return Path(executable)
    raise GenerationError(
        "ImageMagick is required to resize and package the icons. "
        "Install it so the `magick` command is available."
    )


def run(command: list[str], description: str, timeout: int = 60) -> None:
    try:
        result = subprocess.run(
            command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as error:
        raise GenerationError(f"Timed out while {description}.") from error

    if result.returncode != 0:
        details = (result.stderr or result.stdout).strip()
        suffix = f"\n{details}" if details else ""
        raise GenerationError(f"Failed while {description}.{suffix}")


def preserve_source(source: Path, name: str) -> Path:
    destination = PROJECT_ROOT / "assets" / f"{name}.svg"
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source != destination.resolve():
        shutil.copy2(source, destination)
    return destination


def render_svg(chrome: Path, source: Path, output: Path, temp_dir: Path) -> None:
    wrapper = temp_dir / "render.html"
    source_url = html.escape(source.as_uri(), quote=True)
    wrapper.write_text(
        "<!doctype html>\n"
        '<html><head><meta charset="utf-8"><style>\n'
        "html,body{width:100%;height:100%;margin:0;background:transparent;overflow:hidden}\n"
        "img{display:block;width:100%;height:100%;object-fit:contain}\n"
        "</style></head><body>\n"
        f'<img src="{source_url}">\n'
        "</body></html>\n",
        encoding="utf-8",
    )

    profile = temp_dir / "chrome-profile"
    command = [
        str(chrome),
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--allow-file-access-from-files",
        "--no-first-run",
        "--no-default-browser-check",
        "--force-device-scale-factor=1",
        f"--window-size={MASTER_SIZE},{MASTER_SIZE}",
        "--default-background-color=00000000",
        f"--user-data-dir={profile}",
        f"--screenshot={output}",
        wrapper.as_uri(),
    ]
    log_path = temp_dir / "chrome.log"
    with log_path.open("w+", encoding="utf-8") as log:
        process = subprocess.Popen(
            command,
            cwd=PROJECT_ROOT,
            stdout=log,
            stderr=subprocess.STDOUT,
            text=True,
            start_new_session=os.name != "nt",
        )
        deadline = time.monotonic() + 45
        previous_size = -1
        stable_since: float | None = None

        try:
            while time.monotonic() < deadline:
                if output.is_file():
                    current_size = output.stat().st_size
                    if current_size > 0 and current_size == previous_size:
                        stable_since = stable_since or time.monotonic()
                        if time.monotonic() - stable_since >= 0.5:
                            break
                    else:
                        previous_size = current_size
                        stable_since = None

                if process.poll() is not None:
                    break
                time.sleep(0.1)
        finally:
            stop_process(process)

        if not output.is_file() or output.stat().st_size == 0:
            log.seek(0)
            details = log.read().strip()
            suffix = f"\n{details}" if details else ""
            raise GenerationError(
                f"The browser did not produce the rendered PNG.{suffix}"
            )


def stop_process(process: subprocess.Popen[str]) -> None:
    """Stop Chrome and the isolated child-process group it created."""
    if process.poll() is not None:
        return

    try:
        if os.name == "nt":
            process.terminate()
        else:
            os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=5)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        if process.poll() is not None:
            return
        if os.name == "nt":
            process.kill()
        else:
            os.killpg(process.pid, signal.SIGKILL)
        process.wait(timeout=5)


def resize_png(magick: Path, source: Path, size: int, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    run(
        [
            str(magick),
            str(source),
            "-filter",
            "Lanczos",
            "-resize",
            f"{size}x{size}",
            str(destination),
        ],
        f"creating {destination.relative_to(PROJECT_ROOT)}",
    )


def generate_icons(magick: Path, transparent: Path, background: str, temp_dir: Path) -> int:
    opaque = temp_dir / "master_opaque.png"
    run(
        [
            str(magick),
            str(transparent),
            "-background",
            background,
            "-alpha",
            "remove",
            "-alpha",
            "off",
            str(opaque),
        ],
        "creating the opaque icon master",
    )

    outputs: list[tuple[Path, int, Path]] = []

    ios_dir = PROJECT_ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_icons = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    outputs.extend((ios_dir / filename, size, opaque) for filename, size in ios_icons.items())

    macos_dir = PROJECT_ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        outputs.append((macos_dir / f"app_icon_{size}.png", size, transparent))

    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for directory, size in android_sizes.items():
        outputs.append(
            (
                PROJECT_ROOT / f"android/app/src/main/res/{directory}/ic_launcher.png",
                size,
                transparent,
            )
        )

    outputs.extend(
        (
            (PROJECT_ROOT / "web/icons/Icon-192.png", 192, transparent),
            (PROJECT_ROOT / "web/icons/Icon-512.png", 512, transparent),
            (PROJECT_ROOT / "web/icons/Icon-maskable-192.png", 192, opaque),
            (PROJECT_ROOT / "web/icons/Icon-maskable-512.png", 512, opaque),
            (PROJECT_ROOT / "web/favicon.png", 32, transparent),
        )
    )

    for destination, size, master in outputs:
        resize_png(magick, master, size, destination)

    windows_icon = PROJECT_ROOT / "windows/runner/resources/app_icon.ico"
    windows_icon.parent.mkdir(parents=True, exist_ok=True)
    run(
        [
            str(magick),
            str(transparent),
            "-define",
            "icon:auto-resize=256,128,64,48,32,16",
            str(windows_icon),
        ],
        f"creating {windows_icon.relative_to(PROJECT_ROOT)}",
    )

    return len(outputs) + 1


def main() -> int:
    try:
        args = parse_args()
        source, name, background = validate_inputs(args)
        chrome = find_chrome()
        magick = find_magick()
        stored_source = preserve_source(source, name)

        with tempfile.TemporaryDirectory(prefix="mqtt-monitor-icons-") as directory:
            temp_dir = Path(directory)
            transparent_master = temp_dir / "master_transparent.png"
            render_svg(chrome, stored_source, transparent_master, temp_dir)
            output_count = generate_icons(
                magick, transparent_master, background, temp_dir
            )

        print(f"Source: {stored_source.relative_to(PROJECT_ROOT)}")
        print(f"Generated {output_count} launcher-icon files.")
        print("Platforms: Android, iOS, macOS, web, and Windows.")
        return 0
    except GenerationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
