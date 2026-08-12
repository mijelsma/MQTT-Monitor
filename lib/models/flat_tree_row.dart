import 'package:flutter/foundation.dart';

import '../core/monitor/topic_node_metrics.dart';
import 'topic_node.dart';

/// A cached flattened topic-tree row with a granular count signal.
class FlatTreeRow {
  const FlatTreeRow({
    required this.node,
    required this.depth,
    required this.metrics,
  });

  final TopicTreeNode node;
  final int depth;
  final ValueListenable<TopicNodeMetrics> metrics;
}
