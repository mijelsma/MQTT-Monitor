import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Updates the native window chrome (title bar) to match the app theme.
abstract final class WindowChrome {
  static const _channel = MethodChannel('mqtt_monitor/window_chrome');

  /// Switches the native title bar between light and dark appearance.
  ///
  /// Wired up on macOS (window appearance) and Windows (DWM immersive dark
  /// mode). Other platforms have no native runner handler and are skipped.
  static Future<void> setAppearance(Brightness brightness) async {
    if (defaultTargetPlatform != TargetPlatform.macOS && defaultTargetPlatform != TargetPlatform.windows) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setAppearance', brightness.name);
    } on PlatformException {
      // Native chrome is unavailable on this platform.
    } on MissingPluginException {
      // No native runner registers the channel.
    }
  }
}
