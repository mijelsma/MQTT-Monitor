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
import 'package:mqtt_monitor/models/sidebar_panel_default.dart';
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
    // Use "last status" for every panel so the LayoutKeys written below
    // are honored (otherwise the per-panel default setting would win).
    await state.write(SettingsKeys.defaultSidebarDetail, SidebarPanelDefault.lastStatus);
    await state.write(SettingsKeys.defaultSidebarHistory, SidebarPanelDefault.lastStatus);
    await state.write(SettingsKeys.defaultSidebarPublish, SidebarPanelDefault.lastStatus);
    await state.write(SettingsKeys.defaultSidebarShortcuts, SidebarPanelDefault.lastStatus);

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
      const Duration(milliseconds: 500),
    );
    expect(
      sidebarAnimationDurationForSpeed(60),
      const Duration(milliseconds: 160),
    );
    expect(
      sidebarAnimationDurationForSpeed(100),
      const Duration(milliseconds: 40),
    );
    expect(
      sidebarAnimationDurationForSpeed(200),
      const Duration(milliseconds: 40),
    );
  });

  testWidgets('sidebar panels animate at the configured speed', (tester) async {
    await state.write(SettingsKeys.sidebarAnimationsEnabled, true);
    // A slow speed gives a long enough window to sample mid-animation.
    await state.write(SettingsKeys.sidebarAnimationSpeed, 30);
    await pumpSidebar(
      tester,
      expandedSibling: const Key('history-section-toggle'),
    );

    final expectedDuration = sidebarAnimationDurationForSpeed(30);

    // Chevron rotation duration follows the configured speed.
    expect(find.byType(AnimatedRotation), findsNWidgets(4));
    expect(
      tester
          .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
          .every((rotation) => rotation.duration == expectedDuration),
      isTrue,
    );

    final initialHeight = tester
        .getSize(find.byKey(const Key('history-content-clip')))
        .height;
    expect(initialHeight, greaterThan(0));

    // Tap to collapse history; mid-animation the panel height is partway
    // between its expanded height and zero (i.e. a real collapse animation).
    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pump(); // process the tap and start the animation ticker
    await tester.pump(expectedDuration ~/ 2);
    final midHeight = tester
        .getSize(find.byKey(const Key('history-content-clip')))
        .height;
    expect(midHeight, greaterThan(0));
    expect(midHeight, lessThan(initialHeight));

    // After settling, the collapsed panel's content is unmounted.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-content-clip')), findsNothing);
  });

  testWidgets('sidebar panel animation can be disabled', (tester) async {
    await state.write(SettingsKeys.sidebarAnimationsEnabled, false);
    await pumpSidebar(
      tester,
      expandedSibling: const Key('history-section-toggle'),
    );

    expect(find.byType(AnimatedRotation), findsNWidgets(4));
    expect(
      tester
          .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
          .every((rotation) => rotation.duration == Duration.zero),
      isTrue,
    );

    // Disabled: collapsing snaps instantly with no intermediate height.
    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('history-content-clip')), findsNothing);
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

  group('PublishDraftController', () {
    test('setQos clamps out-of-range values to a valid MQTT QoS', () {
      final draft = PublishDraftController();
      addTearDown(draft.dispose);

      draft.setQos(-1);
      expect(draft.qos, 0);
      draft.setQos(99);
      expect(draft.qos, 2);
    });

    test('setQos fires onQosChanged exactly when the QoS actually changes', () {
      final picks = <int>[];
      final draft = PublishDraftController(onQosChanged: picks.add);
      addTearDown(draft.dispose);

      draft.setQos(2);
      draft.setQos(2);
      draft.setQos(0);
      expect(picks, [2, 0], reason: 'Identical picks should not re-fire the callback.');
    });

    test('initial QoS is honored, and onQosChanged is not fired during construction', () {
      final picks = <int>[];
      final draft = PublishDraftController(initialQos: 2, onQosChanged: picks.add);
      addTearDown(draft.dispose);

      expect(draft.qos, 2);
      expect(picks, isEmpty);
    });
  });
}
