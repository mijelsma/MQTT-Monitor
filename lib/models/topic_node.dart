import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/monitor/topic_node_metrics.dart';
import 'topic_node_value.dart';

/// A node in the MQTT topic tree.
class TopicTreeNode {
  TopicTreeNode({required this.segment, required this.fullPath});

  final String segment;
  final String fullPath;
  final SplayTreeMap<String, TopicTreeNode> children = SplayTreeMap(
    _compareSegments,
  );

  DateTime? lastPulseAt;

  final ValueNotifier<TopicNodeValue?> valueNotifier = ValueNotifier(null);
  final ValueNotifier<int> pulseNotifier = ValueNotifier(0);
  final ValueNotifier<TopicNodeMetrics> metricsNotifier = ValueNotifier(
    const TopicNodeMetrics(),
  );

  bool isExpanded = false;

  bool get isBranch => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;
}

int _compareSegments(String left, String right) {
  final folded = left.toLowerCase().compareTo(right.toLowerCase());
  return folded == 0 ? left.compareTo(right) : folded;
}
