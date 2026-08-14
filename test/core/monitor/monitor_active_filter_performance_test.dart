import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/services/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/core/monitor/controllers/topic_pulse_controller.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/features/monitor/controllers/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/features/monitor/search_scope.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_tree_node_model.dart';

import '../../support/test_dependencies.dart';

void main() {
  test('active value filtering stays incremental as topic count grows', () async {
    const messageTotal = 1000;
    const budgets = {10: Duration(milliseconds: 300), 100: Duration(milliseconds: 300), 1000: Duration(milliseconds: 300)};
    await _profile(topicTotal: 10, messageTotal: messageTotal);

    final results = <({int topicTotal, Duration elapsed, Duration budget})>[];
    for (final entry in budgets.entries) {
      results.add((topicTotal: entry.key, elapsed: await _profile(topicTotal: entry.key, messageTotal: messageTotal), budget: entry.value));
    }

    debugPrint('Active value-filter regression guard, $messageTotal existing-topic messages per case:');
    debugPrint('topics | incremental update us | budget us');
    for (final result in results) {
      debugPrint('${result.topicTotal} | ${result.elapsed.inMicroseconds} | ${result.budget.inMicroseconds}');
      expect(result.elapsed, lessThan(result.budget), reason: '${result.topicTotal}-topic active filtering exceeded its regression budget.');
    }
  });
}

Future<Duration> _profile({required int topicTotal, required int messageTotal}) async {
  final dependencies = await TestDependencies.create();
  await dependencies.brokers.add(
    const BrokerEntryModel(
      id: 'filter-performance',
      name: 'Filter performance',
      host: 'performance.invalid',
      subscriptions: [SubscriptionEntryModel(id: 'all', topic: '#')],
    ),
  );
  final source = StreamController<MQTTMessage>.broadcast(sync: true);
  final ingestion = MessageIngestionCoordinator.fromStream(source.stream, dependencies.brokers)..initialize();
  final projection = TopicProjection(ingestion, dependencies.brokers)..initialize();
  final history = MessageHistoryService(ingestion, dependencies.historyPreferences, dependencies.brokers);
  final padding = List.filled(4096, 'x').join();

  for (var topic = 0; topic < topicTotal; topic++) {
    source.add(_message('devices/device-$topic/value', topic == 0 ? 'needle-$padding' : 'ordinary-$topic-$padding', topic));
  }

  final workspace = MonitorWorkspaceController(projection: projection, history: history, uiPreferences: dependencies.uiPreferences, pulses: _NoopTopicPulseController());
  workspace.expandAll();
  workspace.setScope(SearchScope.value);
  workspace.setFilter('needle');
  final initialDerivations = workspace.visibleRowDerivationCount;

  final stopwatch = Stopwatch()..start();
  for (var sequence = 2; sequence < messageTotal + 2; sequence++) {
    final topic = sequence % topicTotal;
    source.add(_message('devices/device-$topic/value', topic == 0 ? 'needle-$sequence-$padding' : 'ordinary-$topic-$sequence-$padding', sequence));
  }
  stopwatch.stop();

  expect(workspace.visibleRowDerivationCount, initialDerivations);
  expect(workspace.visibleRows.map((row) => row.node.fullPath), ['devices', 'devices/device-0', 'devices/device-0/value']);
  expect(workspace.visibleRows.first.metrics.value.messageCount, 1 + (messageTotal + 1) ~/ topicTotal);

  workspace.dispose();
  projection.dispose();
  await history.dispose();
  await ingestion.dispose();
  await source.close();
  return stopwatch.elapsed;
}

MQTTMessage _message(String topic, String payload, int millisecond) => MQTTMessage(topic: topic, payload: payload, receivedAt: DateTime(2026, 1, 1, 0, 0, 0, millisecond));

class _NoopTopicPulseController extends TopicPulseController {
  @override
  void schedule(List<TopicTreeNodeModel> path, int pulsesPerSecond) {}
}
