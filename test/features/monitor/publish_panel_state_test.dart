import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_service.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/layout_keys.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/features/monitor/monitor_viewmodel.dart';
import 'package:mqtt_monitor/features/monitor/publish_draft_controller.dart';
import 'package:mqtt_monitor/features/monitor/widgets/detail_sidebar.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/shared/widgets/payload_editor.dart';
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

  Future<PublishDraftController> pumpSidebar(
    WidgetTester tester, {
    required Key expandedSibling,
  }) async {
    await state.write(
      LayoutKeys.sidebarDetailCollapsed,
      expandedSibling != const Key('detail-section-toggle'),
    );
    await state.write(
      LayoutKeys.sidebarHistoryCollapsed,
      expandedSibling != const Key('history-section-toggle'),
    );
    await state.write(LayoutKeys.sidebarPublishCollapsed, false);
    await state.write(
      LayoutKeys.sidebarShortcutsCollapsed,
      expandedSibling != const Key('shortcuts-section-toggle'),
    );

    final mqtt = MqttService(state);
    final history = MessageHistoryService(mqtt, state);
    final vm = MonitorViewModel(
      mqttService: mqtt,
      state: state,
      historyService: history,
    );
    final draft = PublishDraftController();
    addTearDown(vm.dispose);
    addTearDown(draft.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateManager>.value(value: state),
          ChangeNotifierProvider<MonitorViewModel>.value(value: vm),
          ChangeNotifierProvider<PublishDraftController>.value(value: draft),
          Provider<MessageHistoryService>.value(value: history),
        ],
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const Scaffold(
            body: SizedBox(width: 900, height: 700, child: DetailSidebar()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return draft;
  }

  Future<void> enterDraft(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('publish-topic-field')),
      'devices/alpha/set',
    );
    final payloadField = find.descendant(
      of: find.byType(PayloadEditor),
      matching: find.byType(TextField),
    );
    await tester.enterText(payloadField, '{"enabled":true}');
    await tester.tap(find.byKey(const Key('publish-qos-2')));
    await tester.tap(find.byKey(const Key('publish-retain-toggle')));
    await tester.pump();
  }

  void expectDraftPreserved(PublishDraftController draft) {
    expect(draft.topicController.text, 'devices/alpha/set');
    expect(draft.payloadController.text, '{"enabled":true}');
    expect(draft.qos, 2);
    expect(draft.retain, isTrue);
  }

  test('sidebar speed maps to a short, bounded animation duration', () {
    expect(
      sidebarAnimationDurationForSpeed(0),
      const Duration(milliseconds: 250),
    );
    expect(
      sidebarAnimationDurationForSpeed(60),
      const Duration(milliseconds: 160),
    );
    expect(
      sidebarAnimationDurationForSpeed(100),
      const Duration(milliseconds: 100),
    );
    expect(
      sidebarAnimationDurationForSpeed(200),
      const Duration(milliseconds: 100),
    );
  });

  testWidgets('sidebar panels animate at the configured speed', (tester) async {
    await state.write(SettingsKeys.sidebarAnimationsEnabled, true);
    await state.write(SettingsKeys.sidebarAnimationSpeed, 100);
    await pumpSidebar(
      tester,
      expandedSibling: const Key('history-section-toggle'),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const Key('detail-sidebar-animation')),
    );
    expect(switcher.duration, const Duration(milliseconds: 100));
    expect(find.byType(AnimatedRotation), findsNWidgets(4));
    expect(
      tester
          .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
          .every(
            (rotation) =>
                rotation.duration == const Duration(milliseconds: 100),
          ),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('detail-sidebar-layout')), findsNWidgets(2));

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail-sidebar-layout')), findsOneWidget);
  });

  testWidgets('sidebar panel animation can be disabled', (tester) async {
    await state.write(SettingsKeys.sidebarAnimationsEnabled, false);
    await pumpSidebar(
      tester,
      expandedSibling: const Key('history-section-toggle'),
    );

    expect(find.byKey(const Key('detail-sidebar-animation')), findsNothing);
    expect(find.byType(AnimatedRotation), findsNWidgets(4));
    expect(
      tester
          .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
          .every((rotation) => rotation.duration == Duration.zero),
      isTrue,
    );
    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('detail-sidebar-layout')), findsOneWidget);
  });

  for (final sibling in <({Key key, String name})>[
    (key: const Key('detail-section-toggle'), name: 'message detail'),
    (key: const Key('history-section-toggle'), name: 'history'),
    (key: const Key('shortcuts-section-toggle'), name: 'shortcuts'),
  ]) {
    testWidgets('collapsing ${sibling.name} preserves the Send Message draft', (
      tester,
    ) async {
      final draft = await pumpSidebar(tester, expandedSibling: sibling.key);
      await enterDraft(tester);

      await tester.tap(find.byKey(sibling.key));
      await tester.pumpAndSettle();

      expectDraftPreserved(draft);
      expect(find.byKey(const Key('publish-topic-field')), findsOneWidget);
      final topicField = tester.widget<TextField>(
        find.byKey(const Key('publish-topic-field')),
      );
      expect(topicField.controller?.text, 'devices/alpha/set');
      expect(tester.takeException(), isNull);
    });
  }
}
