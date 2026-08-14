import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/foundation.dart';

/// Minimal controller contract owned by the application update service.
abstract interface class AppUpdateController {
  UpdateState get state;

  void addListener(VoidCallback listener);

  void removeListener(VoidCallback listener);

  Future<ManualUpdateCheckResult> checkForUpdates();

  Future<void> downloadUpdate();

  Future<void> restartApp();

  void dispose();
}

/// Creates channel-specific updater controllers.
abstract interface class AppUpdateControllerFactory {
  AppUpdateController create({required Uri? appArchiveUrl, required String channel, required bool allowUnsignedMacOSUpdates});
}

/// Production factory backed by the desktop updater plugin.
class DesktopAppUpdateControllerFactory implements AppUpdateControllerFactory {
  const DesktopAppUpdateControllerFactory();

  @override
  AppUpdateController create({required Uri? appArchiveUrl, required String channel, required bool allowUnsignedMacOSUpdates}) {
    return DesktopAppUpdateController(appArchiveUrl: appArchiveUrl, channel: channel, allowUnsignedMacOSUpdates: allowUnsignedMacOSUpdates);
  }
}

/// Keeps the plugin type outside the application update lifecycle.
class DesktopAppUpdateController implements AppUpdateController {
  DesktopAppUpdateController({required Uri? appArchiveUrl, required String channel, required bool allowUnsignedMacOSUpdates}) : _controller = DesktopUpdaterController(appArchiveUrl: appArchiveUrl, channel: channel, allowUnsignedMacOSUpdates: allowUnsignedMacOSUpdates, skipInitialVersionCheck: true);

  final DesktopUpdaterController _controller;

  @override
  UpdateState get state => _controller.state;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _controller.removeListener(listener);

  @override
  Future<ManualUpdateCheckResult> checkForUpdates() => _controller.checkForUpdates();

  @override
  Future<void> downloadUpdate() => _controller.downloadUpdate();

  @override
  Future<void> restartApp() => _controller.restartApp();

  @override
  void dispose() => _controller.dispose();
}
