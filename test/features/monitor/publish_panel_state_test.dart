import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/repositories/broker_repository.dart';
import 'package:mqtt_monitor/core/history/services/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/core/publishing/services/publish_command_service.dart';
import 'package:mqtt_monitor/features/monitor/controllers/detail_sidebar_controller.dart';
import 'package:mqtt_monitor/features/monitor/view_models/monitor_view_model.dart';
import 'package:mqtt_monitor/features/monitor/controllers/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/features/monitor/controllers/publish_draft_controller.dart';
import 'package:mqtt_monitor/features/monitor/widgets/detail_sidebar.dart';
import 'package:mqtt_monitor/features/monitor/widgets/history_panel.dart';
import 'package:mqtt_monitor/features/monitor/widgets/message_detail_panel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/core/ui/models/sidebar_panel_default_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_tree_node_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';
import 'package:mqtt_monitor/shared/widgets/payload_editor.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_layout.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late BrokerRepository brokers;
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
  });

  Future<({PublishDraftController draft, MonitorWorkspaceController workspace})> pumpSidebar(WidgetTester tester, {required Key expandedSibling}) async {
    // Use "last status" for every panel so the LayoutKeys written below
    // are honored (otherwise the per-panel default setting would win).
    await dependencies.uiPreferences.setDefaultSidebarDetail(SidebarPanelDefaultModel.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarHistory(SidebarPanelDefaultModel.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarPublish(SidebarPanelDefaultModel.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarShortcuts(SidebarPanelDefaultModel.lastStatus);

    await dependencies.workspaceLayout.setCollapsed(0, expandedSibling != const Key('detail-section-toggle'));
    await dependencies.workspaceLayout.setCollapsed(1, expandedSibling != const Key('history-section-toggle'));
    await dependencies.workspaceLayout.setCollapsed(2, false);
    await dependencies.workspaceLayout.setCollapsed(3, expandedSibling != const Key('shortcuts-section-toggle'));

    final mqtt = dependencies.mqttSession;
    final ingestion = MessageIngestionCoordinator(mqtt, brokers);
    final projection = TopicProjection(ingestion, brokers);
    final history = MessageHistoryService(ingestion, dependencies.historyPreferences, brokers);
    final vm = MonitorViewModel(mqttSession: mqtt, uiPreferences: dependencies.uiPreferences, brokerRepository: brokers, shortcutRepository: dependencies.shortcuts, variableRepository: dependencies.variables, publisher: PublishCommandService(mqtt, dependencies.templateResolver), templateResolver: dependencies.templateResolver);
    final workspace = MonitorWorkspaceController(projection: projection, history: history, uiPreferences: dependencies.uiPreferences);
    final sidebar = DetailSidebarController(dependencies.workspaceLayout, dependencies.uiPreferences);
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
    final node = TopicTreeNodeModel(segment: 'value', fullPath: 'sensor/value')..valueNotifier.value = TopicNodeValueModel(payload: 'latest', seq: 2, receivedAt: DateTime(2026, 1, 1, 12, 1));
    addTearDown(node.valueNotifier.dispose);
    addTearDown(node.pulseNotifier.dispose);
    addTearDown(node.metricsNotifier.dispose);
    fixture.workspace.selectNode(node);
    await tester.pump();

    final historical = TopicNodeValueModel(payload: 'historical', seq: 1, receivedAt: DateTime(2026, 1, 1, 12));
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
