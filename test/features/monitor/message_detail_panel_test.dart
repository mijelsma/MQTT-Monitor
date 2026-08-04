import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_service.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/features/monitor/widgets/message_detail_panel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/models/topic_node.dart';
import 'package:mqtt_monitor/models/topic_node_value.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildHarness(String payload) {
    final state = AppStateManager.instance;
    final mqtt = MqttService(state);
    final history = MessageHistoryService(mqtt, state);
    final node = TopicTreeNode(
      segment: 'temperature',
      fullPath: 'home/temperature',
    );
    node.valueNotifier.value = TopicNodeValue(
      payload: payload,
      seq: 1,
      receivedAt: DateTime(2026),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateManager>.value(value: state),
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
        home: Scaffold(body: MessageDetailPanel(node: node)),
      ),
    );
  }

  testWidgets('payload display uses a SelectionArea', (tester) async {
    await tester.pumpWidget(buildHarness('{"temperature": 21.5}'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payload-selection-area')), findsOneWidget);
    expect(
      tester.widget(find.byKey(const Key('payload-selection-area'))),
      isA<SelectionArea>(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection display handles an empty payload', (tester) async {
    await tester.pumpWidget(buildHarness(''));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payload-selection-area')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection display handles a very large payload', (tester) async {
    final payload = List.filled(20000, 'payload').join('-');

    await tester.pumpWidget(buildHarness(payload));
    await tester.pump();

    expect(find.byKey(const Key('payload-selection-area')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
