/// Build-time configuration for the desktop update feed.
///
/// Release builds receive the public feed URL from GitHub Actions. Local
/// development builds can supply the same value with `--dart-define`.
abstract final class AppUpdateConfiguration {
  static const archiveUrl = String.fromEnvironment('UPDATE_ARCHIVE_URL');

  /// Only enable this for a local macOS smoke test of an unsigned app.
  ///
  /// Public macOS releases must remain signed and notarized.
  static const allowUnsignedMacOSUpdates = bool.fromEnvironment(
    'ALLOW_UNSIGNED_MACOS_UPDATES',
  );

  static Uri? get appArchiveUrl {
    final url = archiveUrl.trim();
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }
}
