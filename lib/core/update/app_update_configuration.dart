/// Build-time configuration for GitHub-backed desktop updates.
///
/// Release builds receive the public Releases API URL from GitHub Actions.
/// Local development builds remain unconfigured unless explicitly opted in.
abstract final class AppUpdateConfiguration {
  static const releasesUrl = String.fromEnvironment('GITHUB_RELEASES_URL');

  /// Only enable this for a local macOS smoke test of an unsigned app.
  ///
  /// Public macOS releases must remain signed and notarized.
  static const allowUnsignedMacOSUpdates = bool.fromEnvironment('ALLOW_UNSIGNED_MACOS_UPDATES');

  static Uri? get githubReleasesUrl {
    final url = releasesUrl.trim();
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }
}
