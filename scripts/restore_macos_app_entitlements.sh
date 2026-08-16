#!/usr/bin/env bash

# desktop_updater re-signs the app before notarization. Re-sign the completed
# app with Runner's entitlements again, then notarize that final signature.
set -euo pipefail

: "${DESKTOP_UPDATER_APP_PATH:?Missing macOS app path from desktop_updater.}"
: "${DESKTOP_UPDATER_PROJECT_ROOT:?Missing project root from desktop_updater.}"
: "${MACOS_DEVELOPER_ID_APPLICATION:?Missing Developer ID signing identity.}"
: "${MACOS_NOTARY_PROFILE:?Missing notary profile.}"
: "${MACOS_KEYCHAIN:?Missing signing keychain.}"

app_path="$DESKTOP_UPDATER_APP_PATH"
entitlements_path="$DESKTOP_UPDATER_PROJECT_ROOT/macos/Runner/Release.entitlements"

if [[ ! -d "$app_path" || ! -f "$entitlements_path" ]]; then
  echo 'Could not locate the macOS app or release entitlements.' >&2
  exit 1
fi

# Sign nested code first, then the app bundle. Public Developer ID builds stay
# outside App Sandbox so desktop_updater can mount, stage, replace, and relaunch
# the signed app bundle. Debug builds remain sandboxed separately.
while IFS= read -r -d '' nested_code; do
  codesign --force --options runtime --timestamp \
    --sign "$MACOS_DEVELOPER_ID_APPLICATION" "$nested_code"
done < <(find "$app_path/Contents/Frameworks" -depth \( -name '*.app' -o -name '*.appex' -o -name '*.framework' -o -name '*.xpc' -o -name '*.dylib' -o -name '*.so' \) -print0)

codesign --force --options runtime --timestamp \
  --generate-entitlement-der \
  --entitlements "$entitlements_path" \
  --sign "$MACOS_DEVELOPER_ID_APPLICATION" "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"
if codesign -d --entitlements :- "$app_path" 2>&1 | grep -q 'com.apple.security.app-sandbox'; then
  echo 'Release app must not carry App Sandbox; automatic updates cannot stage inside it.' >&2
  exit 1
fi

notary_archive="$(mktemp -d)/MQTT-Monitor-notary.zip"
trap 'rm -rf "${notary_archive%/*}"' EXIT
ditto -c -k --keepParent "$app_path" "$notary_archive"
xcrun notarytool submit "$notary_archive" \
  --keychain-profile "$MACOS_NOTARY_PROFILE" \
  --keychain "$MACOS_KEYCHAIN" \
  --wait
xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"
