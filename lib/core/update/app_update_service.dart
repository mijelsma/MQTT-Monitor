import 'dart:async';

import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/foundation.dart';

import 'app_update_configuration.dart';
import 'app_update_controller.dart';
import 'github_release_source.dart';
import 'update_preferences_repository.dart';

/// Owns the app's update channel and update lifecycle.
///
/// `desktop_updater` fixes a controller's channel at construction time. This
/// service recreates that controller when the user changes the beta preference,
/// so the preference takes effect immediately rather than on the next launch.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService({
    required UpdatePreferencesRepository preferences,
    Uri? githubReleasesUrl,
    AppUpdateReleaseSource? releaseSource,
    AppUpdateControllerFactory controllerFactory =
        const DesktopAppUpdateControllerFactory(),
    bool allowUnsignedMacOSUpdates =
        AppUpdateConfiguration.allowUnsignedMacOSUpdates,
  }) : _preferences = preferences,
       _releaseSource =
           releaseSource ??
           _createReleaseSource(
             githubReleasesUrl ?? AppUpdateConfiguration.githubReleasesUrl,
           ),
       _controllerFactory = controllerFactory,
       _allowUnsignedMacOSUpdates = allowUnsignedMacOSUpdates {
    _lastTracksBetaReleases = preferences.tracksBetaReleases;
    _controller = _createController(appArchiveUrl: null, channel: channel);
    _controller.addListener(_notifyListeners);
    _preferences.addListener(_onPreferencesChanged);
  }

  static const stableChannel = 'stable';
  static const betaChannel = 'beta';

  final UpdatePreferencesRepository _preferences;
  final AppUpdateReleaseSource? _releaseSource;
  final AppUpdateControllerFactory _controllerFactory;
  final bool _allowUnsignedMacOSUpdates;
  late AppUpdateController _controller;
  UpdateState? _discoveryState;
  GitHubRelease? _selectedRelease;
  int _selectionEpoch = 0;
  late bool _lastTracksBetaReleases;

  /// Whether this build has GitHub release discovery configured.
  bool get isConfigured => _releaseSource != null;

  /// Whether beta releases are included in update checks.
  bool get tracksBetaReleases => _preferences.tracksBetaReleases;

  /// The update feed channel currently being checked.
  String get channel => tracksBetaReleases ? betaChannel : stableChannel;

  /// Current update lifecycle state.
  UpdateState get state => _discoveryState ?? _controller.state;

  /// GitHub Release selected by the most recent successful check.
  GitHubRelease? get selectedRelease => _selectedRelease;

  Uri get releasePageUrl =>
      _selectedRelease?.htmlUrl ??
      Uri.parse('https://github.com/mijelsma/mqtt-monitor/releases');

  /// Starts the quiet startup check after the widget tree has been created.
  void checkForUpdatesOnStartup() {
    if (!isConfigured) return;
    unawaited(_discoverAndCheck());
  }

  /// Selects the stable or beta feed, persists the choice, and checks it now.
  Future<void> setTracksBetaReleases(bool value) async {
    if (value == tracksBetaReleases) return;
    await _preferences.setTracksBetaReleases(value);
  }

  void _onPreferencesChanged() {
    final tracksBetaReleases = _preferences.tracksBetaReleases;
    if (tracksBetaReleases == _lastTracksBetaReleases) return;
    _lastTracksBetaReleases = tracksBetaReleases;
    _selectionEpoch += 1;
    _selectedRelease = null;
    _discoveryState = null;
    _replaceController(appArchiveUrl: null, channel: channel);
    checkForUpdatesOnStartup();
  }

  /// Checks the selected feed following an explicit user action.
  Future<ManualUpdateCheckResult?> checkForUpdates() {
    if (!isConfigured) return Future.value(null);
    return _discoverAndCheck();
  }

  Future<void> downloadUpdate() => _controller.downloadUpdate();

  Future<void> restartApp() => _controller.restartApp();

  Future<ManualUpdateCheckResult?> _discoverAndCheck() async {
    final releaseSource = _releaseSource;
    if (releaseSource == null) return null;

    final epoch = ++_selectionEpoch;
    _discoveryState = const UpdateChecking();
    notifyListeners();

    try {
      final selection = await releaseSource.findLatest(
        includePrereleases: tracksBetaReleases,
      );
      if (epoch != _selectionEpoch) return null;

      _selectedRelease = selection?.release;
      if (selection == null) {
        _replaceController(appArchiveUrl: null, channel: channel);
        _discoveryState = null;
        notifyListeners();
        return const ManualUpdateCheckUpToDate();
      }

      _replaceController(
        appArchiveUrl: selection.archiveUrl,
        channel: selection.channel,
      );
      _discoveryState = null;
      return await _controller.checkForUpdates();
    } on Object catch (error, stackTrace) {
      if (epoch != _selectionEpoch) return null;
      _discoveryState = UpdateFailed(error);
      notifyListeners();
      return ManualUpdateCheckFailed(error, stackTrace);
    }
  }

  AppUpdateController _createController({
    required Uri? appArchiveUrl,
    required String channel,
  }) {
    return _controllerFactory.create(
      appArchiveUrl: appArchiveUrl,
      channel: channel,
      allowUnsignedMacOSUpdates: _allowUnsignedMacOSUpdates,
    );
  }

  void _replaceController({
    required Uri? appArchiveUrl,
    required String channel,
  }) {
    _controller
      ..removeListener(_notifyListeners)
      ..dispose();
    _controller = _createController(
      appArchiveUrl: appArchiveUrl,
      channel: channel,
    )..addListener(_notifyListeners);
    notifyListeners();
  }

  void _notifyListeners() => notifyListeners();

  @override
  void dispose() {
    _selectionEpoch += 1;
    _preferences.removeListener(_onPreferencesChanged);
    _releaseSource?.close();
    _controller
      ..removeListener(_notifyListeners)
      ..dispose();
    super.dispose();
  }
}

AppUpdateReleaseSource? _createReleaseSource(Uri? url) {
  if (url == null) return null;
  return GitHubReleaseSource(releasesUrl: url);
}
