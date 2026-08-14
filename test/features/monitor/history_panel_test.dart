import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/repositories/broker_repository.dart';
import 'package:mqtt_monitor/core/history/services/message_history_service.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/features/monitor/widgets/history_panel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_history_policy_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_tree_node_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late BrokerRepository brokers;
  late StreamController<MQTTMessage> messages;
  late MessageHistoryService history;
  late TopicTreeNodeModel node;

  setUp(() async {
    final dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
    messages = StreamController<MQTTMessage>.broadcast();
    history = MessageHistoryService.fromStream(messages.stream, dependencies.historyPreferences, brokers)..initialize();
    node = TopicTreeNodeModel(segment: 'value', fullPath: 'sensor/value')..valueNotifier.value = TopicNodeValueModel(payload: 'live', seq: 1, receivedAt: DateTime(2026));
  });

  tearDown(() async {
    await history.dispose();
    node.valueNotifier.dispose();
    node.pulseNotifier.dispose();
    await messages.close();
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BrokerRepository>.value(value: brokers),
          Provider<MessageHistoryService>.value(value: history),
        ],
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 500, height: 400, child: HistoryPanel(node: node)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addPolicy({required bool enabled, int retention = 10}) async {
    await brokers.add(
      BrokerEntryModel(
        id: 'broker',
        name: 'Broker',
        host: 'broker.invalid',
        subscriptions: [
          SubscriptionEntryModel(
            id: 'subscription',
            topic: 'sensor/#',
            history: SubscriptionHistoryPolicyModel(enabled: enabled, retention: retention),
          ),
        ],
      ),
    );
  }

  testWidgets('shows unmatched and disabled policy states', (tester) async {
    await pumpPanel(tester);
    expect(find.text('No matching subscription'), findsWidgets);

    await addPolicy(enabled: false);
    await tester.pumpAndSettle();

    expect(find.text('History disabled'), findsWidgets);
    expect(find.text('Live values continue, but new history is not stored'), findsOneWidget);
  });

  testWidgets('shows effective retention, history, and clear state', (tester) async {
    await addPolicy(enabled: true, retention: 25);
    messages.add(MQTTMessage(topic: 'sensor/value', payload: 'stored-value', receivedAt: DateTime(2026, 1, 1, 12)));
    await tester.pump();
    await pumpPanel(tester);

    expect(find.text('Retaining up to 25'), findsOneWidget);
    expect(find.text('stored-value'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('No history yet'), findsOneWidget);
  });
}
