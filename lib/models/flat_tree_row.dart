import 'topic_node.dart';

/// A flattened row entry produced by [MonitorViewModel.buildFlatList].
class FlatTreeRow {
  const FlatTreeRow({required this.node, required this.depth});

  final TopicTreeNode node;
  final int depth;
}
