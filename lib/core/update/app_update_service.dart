import 'dart:async';

import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/foundation.dart';

import '../state/app_state.dart';
import '../state/keys/settings_keys.dart';
import 'app_update_configuration.dart';

/// Owns the app's update channel and update lifecycle.
///
/// `desktop_updater` fixes a controller's channel at construction time. This
/// service recreates that controller when the user changes the beta preference,
/// so the preference takes effect immediately rather than on the next launch.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService({
    required AppStateManager state,
    Uri? appArchiveUrl,
    bool allowUnsignedMacOSUpdates =
        AppUpdateConfiguration.allowUnsignedMacOSUpdates,
  }) : _state = state,
       _appArchiveUrl = appArchiveUrl ?? AppUpdateConfiguration.appArchiveUrl,
       _allowUnsignedMacOSUpdates = allowUnsignedMacOSUpdates {
    _controller = _createController();
    _controller.addListener(_notifyListeners);
  }

  static const stableChannel = 'stable';
  static const betaChannel = 'beta';

  final AppStateManager _state;
  final Uri? _appArchiveUrl;
  final bool _allowUnsignedMacOSUpdates;
  late DesktopUpdaterController _controller;

  /// Whether this build has an update feed configured.
  bool get isConfigured => _appArchiveUrl != null;

  /// Whether beta releases are included in update checks.
  bool get tracksBetaReleases => _state.read(SettingsKeys.trackBetaReleases);

  /// The update feed channel currently being checked.
  String get channel => tracksBetaReleases ? betaChannel : stableChannel;

  /// Current update lifecycle state.
  UpdateState get state => _controller.state;

  /// Starts the quiet startup check after the widget tree has been created.
  void checkForUpdatesOnStartup() {
    if (!isConfigured) return;
    unawaited(_controller.checkForUpdates());
  }

  /// Selects the stable or beta feed, persists the choice, and checks it now.
  Future<void> setTracksBetaReleases(bool value) async {
    if (value == tracksBetaReleases) return;

    await _state.write(SettingsKeys.trackBetaReleases, value);
    _replaceController();
    checkForUpdatesOnStartup();
  }

  /// Checks the selected feed following an explicit user action.
  Future<ManualUpdateCheckResult?> checkForUpdates() {
    if (!isConfigured) return Future.value(null);
    return _controller.checkForUpdates();
  }

  Future<void> downloadUpdate() => _controller.downloadUpdate();

  Future<void> restartApp() => _controller.restartApp();

  DesktopUpdaterController _createController() {
    return DesktopUpdaterController(
      appArchiveUrl: _appArchiveUrl,
      channel: channel,
      allowUnsignedMacOSUpdates: _allowUnsignedMacOSUpdates,
      skipInitialVersionCheck: true,
    );
  }

  void _replaceController() {
    _controller
      ..removeListener(_notifyListeners)
      ..dispose();
    _controller = _createController()..addListener(_notifyListeners);
    notifyListeners();
  }

  void _notifyListeners() => notifyListeners();

  @override
  void dispose() {
    _controller
      ..removeListener(_notifyListeners)
      ..dispose();
    super.dispose();
  }
}
