import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/platform/controllers/window_chrome_controller.dart';
import 'package:mqtt_monitor/core/platform/window_chrome_lifecycle.dart';

import '../../support/test_dependencies.dart';

void main() {
  testWidgets('syncs preference changes and clears the brightness callback', (tester) async {
    final dependencies = await TestDependencies.create();
    final controller = _RecordingWindowChromeController();

    await tester.pumpWidget(WindowChromeLifecycle(preferences: dependencies.uiPreferences, controller: controller, child: const SizedBox()));

    expect(tester.binding.platformDispatcher.onPlatformBrightnessChanged, isNotNull);
    final initialCalls = controller.appearances.length;

    await dependencies.uiPreferences.setThemeMode(ThemeMode.dark);
    await tester.pump();
    expect(controller.appearances.last, Brightness.dark);

    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.platformDispatcher.onPlatformBrightnessChanged, isNull);

    await dependencies.uiPreferences.setThemeMode(ThemeMode.light);
    await tester.pump();
    expect(controller.appearances.length, initialCalls + 1);
  });
}

class _RecordingWindowChromeController implements WindowChromeController {
  final List<Brightness> appearances = [];

  @override
  Future<void> setAppearance(Brightness brightness) async {
    appearances.add(brightness);
  }
}
