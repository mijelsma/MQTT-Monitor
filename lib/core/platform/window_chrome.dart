import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

abstract interface class WindowChromeController {
  Future<void> setAppearance(Brightness brightness);
}

/// Updates supported native title bars and records recoverable channel misses.
class PlatformWindowChromeController implements WindowChromeController {
  PlatformWindowChromeController(this._logger, {MethodChannel channel = const MethodChannel('mqtt_monitor/window_chrome')}) : _channel = channel;

  final AppLogger _logger;
  final MethodChannel _channel;

  @override
  Future<void> setAppearance(Brightness brightness) async {
    if (defaultTargetPlatform != TargetPlatform.macOS && defaultTargetPlatform != TargetPlatform.windows) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setAppearance', brightness.name);
    } on PlatformException catch (error) {
      _logger.log(AppLogLevel.warning, 'window.chrome', 'Native window appearance could not be updated.', error: error);
    } on MissingPluginException catch (error) {
      _logger.log(AppLogLevel.debug, 'window.chrome', 'No native window appearance handler is registered.', error: error);
    }
  }
}
