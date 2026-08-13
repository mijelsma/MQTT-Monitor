#!/usr/bin/env bash

# Builds one platform and prepares flat, release-scoped GitHub assets. The
# workflow publishes all platforms together only after every build succeeds.
set -euo pipefail

platform="${1:?Usage: publish_desktop_update.sh <windows|macos|linux> <stable|beta>}"
channel="${2:?Usage: publish_desktop_update.sh <windows|macos|linux> <stable|beta>}"

case "$platform" in
  windows) flutter config --enable-windows-desktop ;;
  macos) flutter config --enable-macos-desktop ;;
  linux) flutter config --enable-linux-desktop ;;
  *) echo "Unsupported platform: $platform" >&2; exit 64 ;;
esac

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "GITHUB_REPOSITORY must be set (for example mijelsma/MQTT-Monitor)." >&2
  exit 64
fi

if [[ "$platform" == "macos" ]]; then
  for required in MACOS_DEVELOPER_ID_APPLICATION MACOS_NOTARY_PROFILE MACOS_KEYCHAIN; do
    if [[ -z "${!required:-}" ]]; then
      echo "$required must be set for macOS releases." >&2
      exit 64
    fi
  done
fi

if [[ "$platform" == "windows" ]]; then
  if [[ -z "${INNO_COMPILER:-}" || ! -f "$INNO_COMPILER" ]]; then
    echo "INNO_COMPILER must point to the Inno Setup ISCC.exe compiler." >&2
    exit 64
  fi
fi

# Reject malformed or mismatched tags before a build mutates pubspec metadata.
release_tag="$(git describe --tags --exact-match HEAD)"
python scripts/desktop_release_contract.py \
  --tag "$release_tag" \
  --expect-channel "$channel"

# Capture clean Git metadata before the release helper writes the numeric
# native version required by macOS. Public labels keep the original tag so
# SemVer prereleases remain distinguishable.
python scripts/generate_git_info.py --prepare-release-version
release_version="${release_tag#v}"
release_build_number="$(git rev-list --count HEAD)"
release_download_base="https://github.com/${GITHUB_REPOSITORY}/releases/download/${release_tag}"
github_releases_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases"
flutter pub get

output_directory="dist/desktop_updater"
config_file=".desktop_updater.ci.yaml"

mkdir -p "$output_directory"
trap 'rm -f "$config_file"' EXIT

# desktop_updater still creates the signed/verified platform descriptor. The
# prepare step below flattens its paths for GitHub Release assets.
cat > "$config_file" <<EOF
updates:
  baseUrl: "$release_download_base"
  channel: "$channel"
EOF

if [[ "$platform" == "windows" ]]; then
  if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    windows_project_root="$GITHUB_WORKSPACE"
  else
    windows_project_root="$(pwd -W)"
  fi
  export MQTT_MONITOR_PROJECT_ROOT="$windows_project_root"
  export MQTT_MONITOR_RELEASE_VERSION="$release_version"
  export MQTT_MONITOR_INSTALLER_FILE_VERSION="${release_version%%-*}.$release_build_number"

  cat >> "$config_file" <<EOF
windows:
  installer:
    kind: inno
    mode: script
    script: windows/installer/mqtt_monitor.iss
    isccPath: '$INNO_COMPILER'
    outputBaseName: MQTT-Monitor-Setup
    privilegesRequired: lowest
    requiresElevation: never
EOF
fi

if [[ "$platform" == "macos" ]]; then
  cat >> "$config_file" <<EOF
macos:
  notarize: true
  developerIdApplication: "$MACOS_DEVELOPER_ID_APPLICATION"
  notaryProfile: "$MACOS_NOTARY_PROFILE"
  keychain: "$MACOS_KEYCHAIN"
  staple: true
  gatekeeperAssess: true
  artifact:
    kind: dmg
EOF
fi

dart run desktop_updater:release publish \
  --config "$config_file" \
  --app-name "MQTT Monitor" \
  --platform "$platform" \
  --channel "$channel" \
  --version "$release_version" \
  --build-number "$release_build_number" \
  --dart-define="GITHUB_RELEASES_URL=$github_releases_url"

python scripts/prepare_github_release.py \
  --platform "$platform" \
  --tag "$release_tag" \
  --repository "$GITHUB_REPOSITORY" \
  --input-root "$output_directory/releases" \
  --output "dist/github-release"
