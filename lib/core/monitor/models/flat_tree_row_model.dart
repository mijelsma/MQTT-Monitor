import 'package:flutter/foundation.dart';

import '../topic_node_metrics.dart';
import 'topic_tree_node_model.dart';

/// A cached flattened topic-tree row with a granular count signal.
class FlatTreeRowModel {
  const FlatTreeRowModel({required this.node, required this.depth, required this.metrics});

  final TopicTreeNodeModel node;
  final int depth;
  final ValueListenable<TopicNodeMetrics> metrics;
}
