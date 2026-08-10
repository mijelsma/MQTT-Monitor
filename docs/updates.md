# Auto-update release README

This is the complete release path for MQTT Monitor desktop updates:

```text
release tag
  → GitHub Actions builds Windows / macOS / Linux
  → GitHub Actions publishes release files to Hetzner S3
  → app-archive.json points to the current release for each channel/platform

installed app → public app-archive.json → release.json → verified artifact
              → download → install/restart
```

The application never receives S3 credentials. It only downloads the public
update files, selects its own platform and channel, and verifies the artifact's
length and SHA-256 before installing it.

The production feed is hosted in a Hetzner Object Storage bucket and published
by GitHub Actions. The workflow is [release.yml](../.github/workflows/release.yml).

## Current setup and permissions

The shared Hetzner bucket is `ota`. MQTT Monitor owns only this prefix:

```text
mqtt-monitor/
  app-archive.json
  releases/<version>/<platform>/release.json
  releases/<version>/<platform>/<artifact>
```

The public update feed is:

```text
https://ota.fsn1.your-objectstorage.com/mqtt-monitor/app-archive.json
```

This is how we keep one shared bucket safe:

| Who | Allowed access |
| --- | --- |
| App users | Anonymous `s3:GetObject` for `ota/mqtt-monitor/*` only |
| GitHub Actions (`mqtt-monitor-github`) | `s3:GetObject` and `s3:PutObject` for that same prefix only |
| Admin key | Bucket management; kept local, never put in GitHub |

Everything outside `ota/mqtt-monitor/*` remains private. Neither the app nor
GitHub has access to the other app folders. Do not restore a bucket-wide public
rule such as `arn:aws:s3:::ota/*`.

Hetzner supports policies limited to an object prefix, including a private
bucket with public objects under only that prefix. [Hetzner bucket policy
documentation](https://docs.hetzner.com/storage/object-storage/faq/buckets-objects/)

## GitHub secrets

In GitHub, open **Settings → Secrets and variables → Actions → New repository
secret** and add the six required values below. `UPDATE_BASE_URL` is optional
and is only needed for a custom public download domain.

| Secret | Example value |
| --- | --- |
| `HETZNER_S3_ACCESS_KEY` | Dedicated MQTT Monitor release access key |
| `HETZNER_S3_SECRET_KEY` | Matching secret key |
| `HETZNER_S3_BUCKET` | `shared-app-artifacts` |
| `HETZNER_S3_PREFIX` | `mqtt-monitor` |
| `HETZNER_S3_REGION` | `fsn1` |
| `HETZNER_S3_ENDPOINT` | `https://fsn1.your-objectstorage.com` |
| `UPDATE_BASE_URL` *(optional)* | `https://shared-app-artifacts.fsn1.your-objectstorage.com/mqtt-monitor` |

With the normal Hetzner endpoint, the workflow derives the public URL from the
bucket, region, and prefix, so `UPDATE_BASE_URL` is not required. Set it only
when using a custom public domain or proxy; it must point to the same prefix
and should not end with `/`. Hetzner public object URLs use the form
`https://<bucket>.<location>.your-objectstorage.com/<object>`. [Hetzner Object
Storage overview](https://docs.hetzner.com/storage/object-storage/overview/)

The workflow derives the public URL from the bucket, endpoint, and prefix. The
application receives it as a build-time value; a normal local `flutter run`
does not have this value unless you pass the Dart defines below.

## Stable and beta channels

Both channels use the same bucket and archive, but are selected separately by
the app. The release workflow chooses the channel from the Git tag:

| Tag | Channel | GitHub release |
| --- | --- | --- |
| `v1.4.0` | stable | Normal release |
| `v1.5.0-beta.1` | beta | Prerelease |

A beta build only receives beta updates; a stable build only receives stable
updates. Installing a beta build from the GitHub prerelease is therefore the
opt-in path to the beta channel.

## What one release does

For every tag, GitHub Actions does the following in order:

1. Builds and uploads the Windows update.
2. Reads the existing archive and adds the macOS update.
3. Reads the archive again and adds the Linux update.
4. Creates or updates the matching GitHub Release, attaching the generated
   platform archives.

The sequential order preserves all platforms and both channels in the shared
`app-archive.json`. The workflow also prevents two releases from modifying the
archive at the same time.

The macOS release attachment and in-app update artifact are a signed,
notarized, stapled DMG. Windows and Linux continue to use updater ZIP archives.
Users need a normal installer/DMG for their first installation; in-app updates
only work after the app is already installed.

## Future release procedure

1. Change `version:` in `pubspec.yaml`. Increase both version and build
   number, for example from `0.1.0+2` to `0.2.0+3`.
2. Commit and push the release commit to the branch you are releasing from.
3. Create and push one tag:

   ```bash
   # Stable
   git tag v0.2.0
   git push origin v0.2.0

   # Or beta
   git tag v0.3.0-beta.1
   git push origin v0.3.0-beta.1
   ```

4. Watch **Actions → Release desktop apps**. Its first run creates the update
   archive; later runs preserve and extend it. A beta tag creates a GitHub
   prerelease; a stable tag creates a normal release.
5. Open the created GitHub Release and download the platform artifact to test
   it. A prior build of the same channel should discover the update from
   **Settings → About**.

## macOS signing and notarization

The workflow imports a `Developer ID Application` certificate into a temporary
GitHub Actions keychain, signs the app with hardened runtime, sends it to
Apple's notary service, staples the accepted ticket, and creates/signs/staples
the DMG. The exact signed DMG is both uploaded to Hetzner and attached to the
GitHub Release.

These GitHub repository secrets are required:

| Secret | Value |
| --- | --- |
| `MACOS_DEVELOPER_ID_P12_BASE64` | Base64-encoded Developer ID `.p12` export |
| `MACOS_DEVELOPER_ID_P12_PASSWORD` | Password chosen when exporting the `.p12` |
| `MACOS_NOTARY_API_KEY_P8_BASE64` | Base64-encoded App Store Connect team API `.p8` key |
| `MACOS_NOTARY_KEY_ID` | App Store Connect API key ID |
| `MACOS_NOTARY_ISSUER_ID` | App Store Connect issuer ID |

Keep those values only in GitHub Secrets. The runner removes its temporary
keychain and decoded key files after every macOS job.

## Local check of the hosted feed

To remove “Updates are not configured” from a local macOS build and point it at
the beta feed:

```bash
flutter build macos --debug \
  --dart-define=UPDATE_ARCHIVE_URL=https://ota.fsn1.your-objectstorage.com/mqtt-monitor/app-archive.json \
  --dart-define=UPDATE_CHANNEL=beta
```

To test an actual in-app update, install an **older** build on the same channel,
then publish a higher version. A build with the same version correctly reports
that it is up to date.
