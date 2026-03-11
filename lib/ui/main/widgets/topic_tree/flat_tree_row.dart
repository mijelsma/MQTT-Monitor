import 'topic_tree_node.dart';

/// A flattened row entry produced by [TopicTreeController.buildFlatList].
class FlatTreeRow {
  const FlatTreeRow({required this.node, required this.depth});

  final TopicTreeNode node;

  /// Visual indent depth (0 = root level).
  final int depth;
}
