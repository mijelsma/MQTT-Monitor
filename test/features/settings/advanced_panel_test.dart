import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/features/settings/panels/advanced_panel.dart';
import 'package:mqtt_monitor/features/settings/settings_viewmodel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final state = AppStateManager.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await state.initialize();
    await state.resetAll();
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    final vm = SettingsViewModel(state: state);
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: const Scaffold(body: SizedBox(width: 700, height: 900, child: AdvancedPanel())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('advanced panel shows messages-per-topic slider defaulting to 10', (tester) async {
    await pumpPanel(tester);

    expect(state.read(SettingsKeys.defaultHistorySize), 10, reason: 'the default history per topic is 10 messages');
    expect(find.text('Messages stored per topic'), findsOneWidget);
    expect(find.text('10'), findsWidgets, reason: 'the current value is shown');
  });

  testWidgets('history sliders cover the configured ranges', (tester) async {
    await pumpPanel(tester);

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders, hasLength(2), reason: 'per-topic and increased monitoring buffers');

    final perTopic = sliders.first;
    expect(perTopic.min, 1);
    expect(perTopic.max, 500);
    expect(perTopic.value, 10);

    final increased = sliders.last;
    expect(increased.min, 50);
    expect(increased.max, 5000);
    expect(increased.divisions, 99, reason: 'increased buffer steps by exactly 50');
  });

  testWidgets('advanced panel warns in the themed error color', (tester) async {
    await pumpPanel(tester);

    final warning = tester.widget<Text>(find.textContaining('affect performance'));
    expect(warning.style?.fontWeight, FontWeight.w600, reason: 'the warning is emphasised in bold');
    expect(warning.style?.color, isNotNull);
  });

  group('snapPerTopicHistory', () {
    test('returns 1 for any position below 5', () {
      expect(snapPerTopicHistory(0), 1);
      expect(snapPerTopicHistory(1), 1);
      expect(snapPerTopicHistory(3), 1);
    });

    test('snaps to multiples of 5 from 5 upward', () {
      expect(snapPerTopicHistory(4), 5);
      expect(snapPerTopicHistory(5), 5);
      expect(snapPerTopicHistory(6), 5);
      expect(snapPerTopicHistory(8), 10);
      expect(snapPerTopicHistory(10), 10);
      expect(snapPerTopicHistory(12), 10);
      expect(snapPerTopicHistory(497), 495);
      expect(snapPerTopicHistory(498), 500);
      expect(snapPerTopicHistory(500), 500);
    });
  });
}
