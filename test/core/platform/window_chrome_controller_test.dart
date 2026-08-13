import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/logging/app_logger.dart';
import 'package:mqtt_monitor/core/platform/window_chrome.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PlatformWindowChromeController.channelName);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('sends the shared appearance contract on macOS and Windows', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final controller = PlatformWindowChromeController(LocalAppLogger());

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await controller.setAppearance(Brightness.dark);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await controller.setAppearance(Brightness.light);

    expect(calls.map((call) => (call.method, call.arguments)), const [(PlatformWindowChromeController.setAppearanceMethod, 'dark'), (PlatformWindowChromeController.setAppearanceMethod, 'light')]);
  });

  test('does not send the native contract on Linux', () async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls += 1;
      return null;
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await PlatformWindowChromeController(LocalAppLogger()).setAppearance(Brightness.dark);

    expect(calls, 0);
  });

  test('records a missing native handler as a recoverable diagnostic', () async {
    final logger = LocalAppLogger();
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await PlatformWindowChromeController(logger).setAppearance(Brightness.dark);

    expect(logger.events.single.level, AppLogLevel.debug);
    expect(logger.events.single.area, 'window.chrome');
  });
}
