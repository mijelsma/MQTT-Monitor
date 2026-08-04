import 'topic_node.dart';

/// A flattened row entry produced by [MonitorViewModel.buildFlatList].
class FlatTreeRow {
  const FlatTreeRow({required this.node, required this.depth, required this.topicCount, required this.messageCount});

  final TopicTreeNode node;
  final int depth;
  final int topicCount;
  final int messageCount;
}
