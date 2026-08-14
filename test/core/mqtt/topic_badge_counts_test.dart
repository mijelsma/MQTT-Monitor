import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/topic_badge_counts.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_tree_node_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';

TopicTreeNodeModel addMessage(Map<String, TopicTreeNodeModel> roots, String topic, String payload) {
  final segments = topic.split('/');
  var level = roots;
  var fullPath = '';
  late TopicTreeNodeModel node;
  for (final segment in segments) {
    fullPath = fullPath.isEmpty ? segment : '$fullPath/$segment';
    node = level.putIfAbsent(segment, () => TopicTreeNodeModel(segment: segment, fullPath: fullPath));
    level = node.children;
  }
  final previous = node.valueNotifier.value;
  node.valueNotifier.value = TopicNodeValueModel(payload: payload, seq: (previous?.seq ?? 0) + 1, receivedAt: DateTime(2026));
  return node;
}

void main() {
  test('filtered parent counts are stable and do not double count', () {
    final roots = <String, TopicTreeNodeModel>{};
    addMessage(roots, 'ltt/airhub/0001/temperature', '21');
    addMessage(roots, 'ltt/airhub/0001/temperature', '22');
    addMessage(roots, 'ltt/airhub/0001/status', 'online');
    addMessage(roots, 'ltt/airhub/0002/temperature', '19');
    final parent = roots['ltt']!.children['airhub']!;

    TopicBadgeCounts calculate() => deriveTopicBadgeCounts(roots.values, includesTopic: (node) => node.fullPath.contains('/0001/'))[parent]!;

    final snapshots = List.generate(10, (_) => calculate());

    expect(snapshots.map((value) => value.topicCount), everyElement(2));
    expect(snapshots.map((value) => value.messageCount), everyElement(3));
  });

  test('rapid child arrivals update a filtered parent exactly once each', () {
    final roots = <String, TopicTreeNodeModel>{};
    final leaf = addMessage(roots, 'ltt/airhub/0001/events', 'target event');
    final parent = roots['ltt']!.children['airhub']!;
    final observed = <int>[];

    for (var expected = 1; expected <= 50; expected++) {
      if (expected > 1) {
        final previous = leaf.valueNotifier.value!;
        leaf.valueNotifier.value = TopicNodeValueModel(payload: 'target event $expected', seq: previous.seq + 1, receivedAt: DateTime(2026, 1, 1, 0, 0, expected));
      }
      final first = deriveTopicBadgeCounts(roots.values, includesTopic: (node) => node.valueNotifier.value?.payload.contains('target') ?? false)[parent]!;
      final repeated = deriveTopicBadgeCounts(roots.values, includesTopic: (node) => node.valueNotifier.value?.payload.contains('target') ?? false)[parent]!;

      expect(repeated.messageCount, first.messageCount);
      observed.add(first.messageCount);
    }

    expect(observed, List.generate(50, (index) => index + 1));
  });

  test('unfiltered branch counts include topics that are also branches', () {
    final roots = <String, TopicTreeNodeModel>{};
    addMessage(roots, 'devices/alpha', 'branch value');
    addMessage(roots, 'devices/alpha/status', 'online');
    final alpha = roots['devices']!.children['alpha']!;

    final counts = deriveTopicBadgeCounts(roots.values, includesTopic: (_) => true)[alpha]!;

    expect(counts.topicCount, 2);
    expect(counts.messageCount, 2);
  });
}
