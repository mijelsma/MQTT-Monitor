import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_connection_intent_store.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_session_controller.dart';
import 'package:mqtt_monitor/core/publishing/publish_command_service.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/layout_keys.dart';
import 'package:mqtt_monitor/features/monitor/detail_sidebar_controller.dart';
import 'package:mqtt_monitor/features/monitor/monitor_viewmodel.dart';
import 'package:mqtt_monitor/features/monitor/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/features/monitor/publish_draft_controller.dart';
import 'package:mqtt_monitor/features/monitor/widgets/detail_sidebar.dart';
import 'package:mqtt_monitor/features/monitor/widgets/history_panel.dart';
import 'package:mqtt_monitor/features/monitor/widgets/message_detail_panel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/models/sidebar_panel_default.dart';
import 'package:mqtt_monitor/models/topic_node.dart';
import 'package:mqtt_monitor/models/topic_node_value.dart';
import 'package:mqtt_monitor/shared/widgets/payload_editor.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_layout.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  final state = AppStateManager.instance;
  late BrokerRepository brokers;
  late MqttConnectionIntentStore connectionIntent;
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
    connectionIntent = MqttConnectionIntentStore(dependencies.preferences);
  });

  Future<({PublishDraftController draft, MonitorWorkspaceController workspace})> pumpSidebar(WidgetTester tester, {required Key expandedSibling}) async {
    // Use "last status" for every panel so the LayoutKeys written below
    // are honored (otherwise the per-panel default setting would win).
    await dependencies.uiPreferences.setDefaultSidebarDetail(SidebarPanelDefault.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarHistory(SidebarPanelDefault.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarPublish(SidebarPanelDefault.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarShortcuts(SidebarPanelDefault.lastStatus);

    await state.write(LayoutKeys.sidebarDetailCollapsed, expandedSibling != const Key('detail-section-toggle'));
    await state.write(LayoutKeys.sidebarHistoryCollapsed, expandedSibling != const Key('history-section-toggle'));
    await state.write(LayoutKeys.sidebarPublishCollapsed, false);
    await state.write(LayoutKeys.sidebarShortcutsCollapsed, expandedSibling != const Key('shortcuts-section-toggle'));

    final mqtt = MqttSessionController(state, brokers, connectionIntent);
    final ingestion = MessageIngestionCoordinator(mqtt, brokers);
    final projection = TopicProjection(ingestion, brokers);
    final history = MessageHistoryService(ingestion, state, brokers);
    final vm = MonitorViewModel(mqttSession: mqtt, uiPreferences: dependencies.uiPreferences, brokerRepository: brokers, shortcutRepository: dependencies.shortcuts, variableRepository: dependencies.variables, publisher: PublishCommandService(mqtt, dependencies.templateResolver), templateResolver: dependencies.templateResolver);
    final workspace = MonitorWorkspaceController(projection: projection, history: history, uiPreferences: dependencies.uiPreferences);
    final sidebar = DetailSidebarController(state, dependencies.uiPreferences);
    final draft = PublishDraftController();
    addTearDown(vm.dispose);
    addTearDown(workspace.dispose);
    addTearDown(sidebar.dispose);
    addTearDown(projection.dispose);
    addTearDown(mqtt.dispose);
    addTearDown(draft.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateManager>.value(value: state),
          ChangeNotifierProvider.value(value: dependencies.uiPreferences),
          ChangeNotifierProvider<BrokerRepository>.value(value: brokers),
          ChangeNotifierProvider<MonitorViewModel>.value(value: vm),
          ChangeNotifierProvider<MonitorWorkspaceController>.value(value: workspace),
          ChangeNotifierProvider<DetailSidebarController>.value(value: sidebar),
          ChangeNotifierProvider<PublishDraftController>.value(value: draft),
          Provider<MessageHistoryService>.value(value: history),
        ],
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: const Scaffold(body: SizedBox(width: 900, height: 700, child: DetailSidebar())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (draft: draft, workspace: workspace);
  }

  Future<void> enterDraft(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('publish-topic-field')), 'devices/alpha/set');
    final payloadField = find.descendant(of: find.byType(PayloadEditor), matching: find.byType(TextField));
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
    expect(workspacePanelAnimationDurationForSpeed(0), const Duration(milliseconds: 500));
    expect(workspacePanelAnimationDurationForSpeed(60), const Duration(milliseconds: 160));
    expect(workspacePanelAnimationDurationForSpeed(100), const Duration(milliseconds: 40));
    expect(workspacePanelAnimationDurationForSpeed(200), const Duration(milliseconds: 40));
  });

  testWidgets('sidebar panels animate at the configured speed', (tester) async {
    await dependencies.uiPreferences.setSidebarAnimationsEnabled(true);
    // A slow speed gives a long enough window to sample mid-animation.
    await dependencies.uiPreferences.setSidebarAnimationSpeed(30);
    await pumpSidebar(tester, expandedSibling: const Key('history-section-toggle'));

    final expectedDuration = workspacePanelAnimationDurationForSpeed(30);

    // Chevron rotation duration follows the configured speed.
    expect(find.byType(AnimatedRotation), findsNWidgets(4));
    expect(tester.widgetList<AnimatedRotation>(find.byType(AnimatedRotation)).every((rotation) => rotation.duration == expectedDuration), isTrue);

    final initialHeight = tester.getSize(find.byKey(const Key('history-content-clip'))).height;
    expect(initialHeight, greaterThan(0));

    // Tap to collapse history; mid-animation the panel height is partway
    // between its expanded height and zero (i.e. a real collapse animation).
    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pump(); // process the tap and start the animation ticker
    await tester.pump(expectedDuration ~/ 2);
    final midHeight = tester.getSize(find.byKey(const Key('history-content-clip'))).height;
    expect(midHeight, greaterThan(0));
    expect(midHeight, lessThan(initialHeight));

    // After settling, the collapsed panel has no visible content clip.
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('history-content-clip'))).height, 0);
  });

  testWidgets('sidebar panel animation can be disabled', (tester) async {
    await dependencies.uiPreferences.setSidebarAnimationsEnabled(false);
    await pumpSidebar(tester, expandedSibling: const Key('history-section-toggle'));

    expect(find.byType(AnimatedRotation), findsNWidgets(4));
    expect(tester.widgetList<AnimatedRotation>(find.byType(AnimatedRotation)).every((rotation) => rotation.duration == Duration.zero), isTrue);

    // Disabled: collapsing snaps instantly with no intermediate height.
    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pump();
    expect(tester.getSize(find.byKey(const Key('history-content-clip'))).height, 0);
  });

  testWidgets('detail and publish resize across collapsed history', (tester) async {
    await dependencies.uiPreferences.setSidebarAnimationsEnabled(false);
    await pumpSidebar(tester, expandedSibling: const Key('detail-section-toggle'));

    final divider = find.byKey(const Key('workspace-panel-divider-0-2'));
    expect(divider, findsOneWidget);
    final detailBefore = tester.getSize(find.byKey(const Key('detail-content-clip'))).height;
    final publishBefore = tester.getSize(find.byKey(const Key('publish-content-clip'))).height;

    await tester.drag(divider, const Offset(0, 50));
    await tester.pump();

    expect(tester.getSize(find.byKey(const Key('detail-content-clip'))).height, greaterThan(detailBefore));
    expect(tester.getSize(find.byKey(const Key('publish-content-clip'))).height, lessThan(publishBefore));
    expect(tester.getSize(find.byKey(const Key('history-content-clip'))).height, 0);
  });

  for (final sibling in <({Key key, String name})>[(key: const Key('detail-section-toggle'), name: 'message detail'), (key: const Key('history-section-toggle'), name: 'history'), (key: const Key('shortcuts-section-toggle'), name: 'shortcuts')]) {
    testWidgets('collapsing ${sibling.name} preserves the Send Message draft', (tester) async {
      final draft = (await pumpSidebar(tester, expandedSibling: sibling.key)).draft;
      await enterDraft(tester);

      await tester.tap(find.byKey(sibling.key));
      await tester.pumpAndSettle();

      expectDraftPreserved(draft);
      expect(find.byKey(const Key('publish-topic-field')), findsOneWidget);
      final topicField = tester.widget<TextField>(find.byKey(const Key('publish-topic-field')));
      expect(topicField.controller?.text, 'devices/alpha/set');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('history selection survives collapse and expansion', (tester) async {
    final fixture = await pumpSidebar(tester, expandedSibling: const Key('history-section-toggle'));
    final node = TopicTreeNode(segment: 'value', fullPath: 'sensor/value')..valueNotifier.value = TopicNodeValue(payload: 'latest', seq: 2, receivedAt: DateTime(2026, 1, 1, 12, 1));
    addTearDown(node.valueNotifier.dispose);
    addTearDown(node.pulseNotifier.dispose);
    addTearDown(node.metricsNotifier.dispose);
    fixture.workspace.selectNode(node);
    await tester.pump();

    final historical = TopicNodeValue(payload: 'historical', seq: 1, receivedAt: DateTime(2026, 1, 1, 12));
    tester.widget<HistoryPanel>(find.byType(HistoryPanel)).onSelect!(historical);
    await tester.pump();
    expect(tester.widget<MessageDetailPanel>(find.byType(MessageDetailPanel)).selectedHistory, same(historical));

    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pumpAndSettle();
    expect(tester.widget<MessageDetailPanel>(find.byType(MessageDetailPanel)).selectedHistory, same(historical));

    await tester.tap(find.byKey(const Key('history-section-toggle')));
    await tester.pumpAndSettle();
    expect(tester.widget<HistoryPanel>(find.byType(HistoryPanel)).selectedValue, same(historical));
  });

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
