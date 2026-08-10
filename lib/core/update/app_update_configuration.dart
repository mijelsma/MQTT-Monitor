/// Build-time configuration for the desktop update feed.
///
/// Release builds receive the public feed URL and channel from GitHub Actions.
/// Local development builds can supply the same values with `--dart-define`.
abstract final class AppUpdateConfiguration {
  static const archiveUrl = String.fromEnvironment('UPDATE_ARCHIVE_URL');

  static const channel = String.fromEnvironment(
    'UPDATE_CHANNEL',
    defaultValue: 'stable',
  );

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
