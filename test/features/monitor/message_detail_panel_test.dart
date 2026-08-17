import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/services/message_history_service.dart';
import 'package:mqtt_monitor/core/dashboard/repositories/dashboard_repository.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/history/repositories/history_preferences_repository.dart';
import 'package:mqtt_monitor/features/monitor/widgets/message_detail_panel.dart';
import 'package:mqtt_monitor/shared/widgets/copy_button.dart';
import 'package:mqtt_monitor/features/monitor/view_models/monitor_view_model.dart';
import 'package:mqtt_monitor/core/publishing/services/publish_command_service.dart';
import 'package:mqtt_monitor/core/ui/repositories/ui_preferences_repository.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_tree_node_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
  });

  test('recognizes a standalone JSON numeric string as a pinnable payload', () {
    expect(parseNumericPayload('"23.5"'), (23.5, null));
  });

  test('formats copied bytes as one unadorned hex line', () {
    expect(formatPayloadBytesForClipboard([0x41, 0x42, 0x00, 0xFF, 0x20, 0x5A]), '41 42 00 FF 20 5A');
  });

  Widget buildHarness(String payload, {List<int>? payloadBytes, double? width}) {
    final mqtt = dependencies.mqttSession;
    addTearDown(mqtt.dispose);
    final ingestion = MessageIngestionCoordinator(mqtt, dependencies.brokers);
    final history = MessageHistoryService(ingestion, dependencies.historyPreferences, dependencies.brokers);
    final node = TopicTreeNodeModel(segment: 'temperature', fullPath: 'home/temperature');
    node.valueNotifier.value = TopicNodeValueModel(payload: payload, payloadBytes: payloadBytes, seq: 1, receivedAt: DateTime(2026));
    final dashboard = DashboardRepository(dependencies.preferences, dependencies.brokers);
    final monitor = MonitorViewModel(mqttSession: mqtt, uiPreferences: dependencies.uiPreferences, brokerRepository: dependencies.brokers, shortcutRepository: dependencies.shortcuts, variableRepository: dependencies.variables, publisher: PublishCommandService(mqtt, dependencies.templateResolver), templateResolver: dependencies.templateResolver);
    addTearDown(dashboard.dispose);
    addTearDown(monitor.dispose);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UiPreferencesRepository>.value(value: dependencies.uiPreferences),
        ChangeNotifierProvider<DashboardRepository>.value(value: dashboard),
        ChangeNotifierProvider<MonitorViewModel>.value(value: monitor),
        ChangeNotifierProvider<HistoryPreferencesRepository>.value(value: dependencies.historyPreferences),
        Provider<MessageHistoryService>.value(value: history),
      ],
      child: MaterialApp(
        theme: themeLight,
        localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: width == null
              ? MessageDetailPanel(node: node)
              : Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: MessageDetailPanel(node: node),
                  ),
                ),
        ),
      ),
    );
  }

  testWidgets('payload display uses a SelectionArea', (tester) async {
    await tester.pumpWidget(buildHarness('{"temperature": 21.5}'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payload-selection-area')), findsOneWidget);
    expect(tester.widget(find.byKey(const Key('payload-selection-area'))), isA<SelectionArea>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection display handles an empty payload', (tester) async {
    await tester.pumpWidget(buildHarness(''));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payload-selection-area')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a selectable, aligned raw byte table for a short message', (tester) async {
    await tester.pumpWidget(buildHarness('AB', payloadBytes: [0x41, 0x42, 0x00, 0xFF, 0x20, 0x5A], width: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BYTES'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payload-byte-view')), findsOneWidget);
    expect(find.text('OFFSET'), findsOneWidget);
    expect(find.text('00000000'), findsOneWidget);
    expect(find.text('AB.. Z'), findsOneWidget);
    expect(find.text('6 B'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('payload-byte-header-0'))).dx, tester.getTopLeft(find.byKey(const Key('payload-byte-0-0'))).dx);
    expect(tester.getTopLeft(find.byKey(const Key('payload-byte-ascii-header'))).dx, tester.getTopLeft(find.byKey(const Key('payload-byte-ascii-0'))).dx);
    expect(tester.widgetList<CopyButton>(find.byType(CopyButton)).last.text, '41 42 00 FF 20 5A');
    final byteScroll = tester.widget<SingleChildScrollView>(find.byKey(const Key('payload-byte-scroll')));
    expect(byteScroll.scrollDirection, Axis.horizontal);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection display handles a very large payload', (tester) async {
    final payload = List.filled(20000, 'payload').join('-');

    await tester.pumpWidget(buildHarness(payload));
    await tester.pump();

    expect(find.byKey(const Key('payload-selection-area')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final payload in ['42', '"23.5"', '32.69 °C']) {
    testWidgets('selection display lays out pinnable payload $payload', (tester) async {
      await tester.pumpWidget(buildHarness(payload));
      await tester.pump();

      expect(find.byKey(const Key('payload-selection-area')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
