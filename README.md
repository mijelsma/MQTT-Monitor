# MQTT-Monitor

A fast, cross-platform desktop MQTT client built with Flutter. Connect to any broker, subscribe to topics, watch live messages update in real time, inspect and publish payloads — all from a clean, responsive UI that adapts to your system light / dark theme.

Runs natively on macOS, Windows, and Linux from a single codebase.

---

## Contents

- [Getting Started in VS Code](#getting-started-in-vs-code)
- [Credits](#credits)

---

## Getting Started in VS Code

### Prerequisites

- **Visual Studio Code** installed — [code.visualstudio.com](https://code.visualstudio.com/)
- Repository cloned and the `mqtt_monitor` repo opened in VS Code


### 1. Install recommended extensions

This repository ships a `.vscode/extensions.json` file. When you open the project VS Code will show a prompt — click **Install All**. Or install them manually via the **Extensions: Show Recommended Extensions** command (`Cmd+Shift+P` / `Ctrl+Shift+P`)

### 2. Set up Flutter & the Dart SDK

Follow the official Flutter guide for VS Code — it installs the Flutter SDK, Dart SDK, and all platform toolchains (Xcode on macOS, Visual Studio on Windows, etc.):

**[docs.flutter.dev/install/with-vs-code](https://docs.flutter.dev/install/with-vs-code)**

Once done, verify your setup:

```bash
flutter doctor -v
```

### 3. Build the application

Use the built-in VS Code task to compile a release build for your platform.

Open the **Command Palette** (`Cmd+Shift+P` / `Ctrl+Shift+P`), run **Tasks: Run Build Task**, and select the task that matches your OS:

| Platform | Task name |
|----------|-----------|
| macOS    | `Build — macOS (release)` |
| Windows  | `Build — Windows (release)` |
| Linux    | `Build — Linux (release)` |

Alternatively, run it directly from the terminal:

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

---

## Credits
The tree-style topic explorer UI was inspired by MQTT Explorer:
https://mqtt-explorer.com