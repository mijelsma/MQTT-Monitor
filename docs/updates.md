# Desktop updates and releases

MQTT Monitor discovers GitHub Releases and delegates verified download,
staging, installation, and relaunch mechanics to `desktop_updater`.

## Channels and versions

- Stable releases use an exact `vX.Y.Z` tag.
- Beta releases use `vX.Y.Z-prerelease`, such as `v1.0.0-beta.2`.
- Stable is the default channel. Enabling beta tracking includes stable and
  prerelease candidates.
- The app selects the greatest eligible semantic version and never offers an
  in-app downgrade.

Release scripts reject malformed tags, tag/channel disagreement, platform
identity drift, wrong versions, malformed digests, unexpected artifact kinds,
and download URLs outside the tagged GitHub Release.

## Platform artifacts

- macOS publishes a signed, notarized, and stapled DMG.
- Windows publishes a per-user Inno Setup installer. Portable zip publication
  is rejected by the release contract.
- Linux publishes a relocatable zip that preserves executable permissions.

Windows first installation uses the interactive modern installer. Automatic
updates use the same verified installer with silent arguments, retain the
current install directory, and relaunch MQTT Monitor after success.

The Windows installer is currently unsigned. Authenticode signing and trusted
timestamping must be added before 1.0. At that point the release descriptor
must also require and pin the signing certificate thumbprint so the updater
fails closed for an unexpected publisher.

## Publication order

1. Analyze and test the exact tagged commit.
2. Build Windows, macOS, and Linux independently.
3. Validate every descriptor, artifact length, SHA-256, version, channel,
   application name, and platform identity.
4. Assemble `app-archive.json` after all platform builds succeed.
5. Create one complete draft GitHub Release and publish it.
6. Download the public assets and validate them again.

Published tags and assets are immutable project records. Do not move a
published tag, overwrite an asset, or delete an older release. Corrections use
a new patch or prerelease tag. Repository release immutability should be
enabled in GitHub settings before 1.0.

## Retention and downgrades

Older GitHub releases remain available for reproducibility, but installing an
older application over a newer one is unsupported. Repositories reject unknown
future schema versions instead of guessing or rewriting them. Starting with
the public 1.0 schema, later releases must provide forward migrations whenever
a persisted schema changes.
