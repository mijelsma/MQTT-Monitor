import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/ingestion/ingested_message.dart';
import 'package:mqtt_monitor/core/monitor/topic_tree_index.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';

void main() {
  test('cached projection stays within its topic-scaling budgets', () {
    const messageTotal = 10000;
    const budgets = {10: Duration(milliseconds: 100), 100: Duration(milliseconds: 100), 250: Duration(milliseconds: 100), 1000: Duration(milliseconds: 100)};
    _profile(topicTotal: 3, messageTotal: messageTotal);

    final results = [for (final entry in budgets.entries) (topicTotal: entry.key, elapsed: _profile(topicTotal: entry.key, messageTotal: messageTotal), budget: entry.value)];

    debugPrint('Monitor cached-path regression guard, $messageTotal existing-topic messages per case:');
    debugPrint('topics | cached projection µs | budget µs');
    for (final result in results) {
      debugPrint('${result.topicTotal} | ${result.elapsed.inMicroseconds} | ${result.budget.inMicroseconds}');
      expect(result.elapsed, lessThan(result.budget), reason: '${result.topicTotal}-topic cached projection exceeded its regression budget.');
    }
  });
}

Duration _profile({required int topicTotal, required int messageTotal}) {
  final startedAt = DateTime(2026);
  final index = TopicTreeIndex();

  for (var topic = 0; topic < topicTotal; topic++) {
    final path = 'devices/device-$topic/value';
    index.insert(_message(path, 1, startedAt));
  }

  var structuralChanges = 0;
  final stopwatch = Stopwatch()..start();
  for (var sequence = 2; sequence < messageTotal + 2; sequence++) {
    final path = 'devices/device-${sequence % topicTotal}/value';
    final result = index.insert(_message(path, sequence, startedAt));
    if (result.structureChanged) structuralChanges++;
  }
  stopwatch.stop();

  expect(structuralChanges, 0);
  expect(index.pathFor('devices/device-0/value').last.metricsNotifier.value.messageCount, 1 + (messageTotal + 1) ~/ topicTotal);
  return stopwatch.elapsed;
}

IngestedMessage _message(String topic, int sequence, DateTime receivedAt) => IngestedMessage(
  brokerId: 'broker',
  topic: topic,
  value: TopicNodeValueModel(payload: '$sequence', seq: sequence, receivedAt: receivedAt),
);
