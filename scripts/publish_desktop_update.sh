#!/usr/bin/env bash

# Builds one platform, preserves the existing multi-channel archive, and
# publishes the new descriptor and artifact to an S3-compatible object store.
set -euo pipefail

platform="${1:?Usage: publish_desktop_update.sh <windows|macos|linux> <stable|beta>}"
channel="${2:?Usage: publish_desktop_update.sh <windows|macos|linux> <stable|beta>}"

case "$platform" in
  windows) flutter config --enable-windows-desktop ;;
  macos) flutter config --enable-macos-desktop ;;
  linux) flutter config --enable-linux-desktop ;;
  *) echo "Unsupported platform: $platform" >&2; exit 64 ;;
esac

for required in HETZNER_S3_ACCESS_KEY HETZNER_S3_SECRET_KEY HETZNER_S3_BUCKET HETZNER_S3_PREFIX HETZNER_S3_REGION HETZNER_S3_ENDPOINT; do
  if [[ -z "${!required:-}" ]]; then
    echo "$required must be set." >&2
    exit 64
  fi
done

if [[ "$platform" == "macos" ]]; then
  for required in MACOS_DEVELOPER_ID_APPLICATION MACOS_NOTARY_PROFILE MACOS_KEYCHAIN; do
    if [[ -z "${!required:-}" ]]; then
      echo "$required must be set for macOS releases." >&2
      exit 64
    fi
  done
fi

# Hetzner's normal public URL is virtual-hosted:
# https://<bucket>.<region>.your-objectstorage.com/<prefix>. A custom public
# domain can override this derived URL through UPDATE_BASE_URL.
if [[ -z "${UPDATE_BASE_URL:-}" ]]; then
  endpoint_host="${HETZNER_S3_ENDPOINT%/}"
  endpoint_host="${endpoint_host#https://}"
  endpoint_host="${endpoint_host#http://}"
  UPDATE_BASE_URL="https://${HETZNER_S3_BUCKET}.${endpoint_host}/${HETZNER_S3_PREFIX%/}"
fi

python scripts/generate_git_info.py
flutter pub get

output_directory="dist/desktop_updater"
archive_file="$output_directory/app-archive.json"
archive_key="${HETZNER_S3_PREFIX%/}/app-archive.json"
config_file=".desktop_updater.ci.yaml"
archive_url="${UPDATE_BASE_URL%/}/app-archive.json"

mkdir -p "$output_directory"

# The first platform of the first release has no archive yet. Later platform
# jobs must seed it so every channel/platform entry remains available.
if ! aws s3 cp "s3://${HETZNER_S3_BUCKET}/${archive_key}" "$archive_file" \
  --endpoint-url "$HETZNER_S3_ENDPOINT" \
  --region "$HETZNER_S3_REGION"; then
  if [[ "${REQUIRE_EXISTING_ARCHIVE:-false}" == "true" ]]; then
    echo "Could not download the existing app-archive.json." >&2
    exit 1
  fi
  echo "No existing app-archive.json found; creating the first update index."
fi

trap 'rm -f "$config_file"' EXIT
cat > "$config_file" <<EOF
updates:
  baseUrl: "$UPDATE_BASE_URL"
  channel: "$channel"
s3:
  bucket: "$HETZNER_S3_BUCKET"
  prefix: "$HETZNER_S3_PREFIX"
  region: "$HETZNER_S3_REGION"
  endpoint: "$HETZNER_S3_ENDPOINT"
EOF

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
  --platform "$platform" \
  --channel "$channel" \
  --dart-define="UPDATE_ARCHIVE_URL=$archive_url" \
  --dart-define="UPDATE_CHANNEL=$channel"
