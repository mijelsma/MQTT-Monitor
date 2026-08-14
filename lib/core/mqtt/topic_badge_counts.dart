import '../../core/monitor/models/topic_tree_node_model.dart';

class TopicBadgeCounts {
  const TopicBadgeCounts({required this.topicCount, required this.messageCount});

  final int topicCount;
  final int messageCount;
}

/// Derives badge counts bottom-up from topic values. The returned map is a
/// single immutable snapshot for one rebuild, so filtered and unfiltered
/// counters can never race or overwrite each other.
Map<TopicTreeNodeModel, TopicBadgeCounts> deriveTopicBadgeCounts(Iterable<TopicTreeNodeModel> roots, {required bool Function(TopicTreeNodeModel node) includesTopic}) {
  final result = <TopicTreeNodeModel, TopicBadgeCounts>{};

  TopicBadgeCounts visit(TopicTreeNodeModel node) {
    var topics = 0;
    var messages = 0;

    final value = node.valueNotifier.value;
    if (value != null && includesTopic(node)) {
      topics = 1;
      messages = value.seq;
    }

    for (final child in node.children.values) {
      final childCounts = visit(child);
      topics += childCounts.topicCount;
      messages += childCounts.messageCount;
    }

    final counts = TopicBadgeCounts(topicCount: topics, messageCount: messages);
    result[node] = counts;
    return counts;
  }

  for (final root in roots) {
    visit(root);
  }
  return Map.unmodifiable(result);
}
