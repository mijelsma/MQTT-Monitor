# Desktop updates and releases

MQTT Monitor uses `desktop_updater` for in-app desktop updates. The app reads
one public `app-archive.json`, selects a matching platform and channel, then
downloads an artifact only after its length and SHA-256 digest have been read
from a release descriptor.

The production feed is hosted in a Hetzner Object Storage bucket and published
by GitHub Actions. The workflow is [release.yml](../.github/workflows/release.yml).

## One shared Hetzner bucket is safe

Yes, this app can share a bucket with private apps. Keep every MQTT Monitor
object below one unique prefix, for example:

```text
mqtt-monitor/
  app-archive.json
  releases/<version>/<platform>/release.json
  releases/<version>/<platform>/<artifact>
```

Do **not** make the whole bucket public. Create a bucket policy that grants
anonymous `s3:GetObject` access only to:

```text
arn:aws:s3:::<bucket-name>/mqtt-monitor/*
```

Hetzner supports policies limited to an object prefix, including a private
bucket with public objects under only that prefix. [Hetzner bucket policy
documentation](https://docs.hetzner.com/storage/object-storage/faq/buckets-objects/)

Create a second, dedicated S3 credential for GitHub Actions. Restrict it to
`s3:GetObject` and `s3:PutObject` for the same prefix; it must not have delete
access or access to the private-app prefixes.

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

The application gets the archive URL from this base URL during the release
build; it is not needed in local development builds.

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

## Release workflow

For every tag, GitHub Actions does the following in order:

1. Builds and uploads the Windows update.
2. Reads the existing archive and adds the macOS update.
3. Reads the archive again and adds the Linux update.
4. Creates or updates the matching GitHub Release, attaching the generated
   platform archives.

The sequential order preserves all platforms and both channels in the shared
`app-archive.json`. The workflow also prevents two releases from modifying the
archive at the same time.

At this stage, the GitHub Release attachments are the updater ZIP archives.
Keep publishing your conventional DMG/EXE installer assets separately until
macOS signing/notarization and a Windows installer pipeline are configured.

## Normal release procedure

1. Change `version:` in `pubspec.yaml`. Increase both version and build
   number, for example from `0.1.0+2` to `0.2.0+3`.
2. Commit and push the release commit.
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
   archive; later runs preserve and extend it.
5. Open the created GitHub Release and download the platform artifact to test
   it. A prior build of the same channel should discover the update from
   **Settings → About**.

## macOS production requirement

The workflow builds a macOS update archive, but production macOS in-app
updates must be Developer ID signed, notarized, and stapled. The app correctly
rejects unsigned macOS updates by default. Add signing/notarization secrets and
the matching macOS release configuration before publicly relying on macOS
auto-update; use `ALLOW_UNSIGNED_MACOS_UPDATES` only for a local smoke test.

## Local smoke test

The local macOS test remains useful before your first hosted release. Build an
older app with `UPDATE_ARCHIVE_URL=http://127.0.0.1:8080/app-archive.json` and
`ALLOW_UNSIGNED_MACOS_UPDATES=true`, then create a higher-version package with
the same values and serve `dist/desktop_updater` over a local HTTP server.
