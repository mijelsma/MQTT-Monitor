import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../topic_node_metrics.dart';
import 'topic_node_value_model.dart';

/// A node in the MQTT topic tree.
class TopicTreeNodeModel {
  TopicTreeNodeModel({required this.segment, required this.fullPath});

  final String segment;
  final String fullPath;
  final SplayTreeMap<String, TopicTreeNodeModel> children = SplayTreeMap(_compareSegments);

  DateTime? lastPulseAt;

  final ValueNotifier<TopicNodeValueModel?> valueNotifier = ValueNotifier(null);
  final ValueNotifier<int> pulseNotifier = ValueNotifier(0);
  final ValueNotifier<TopicNodeMetrics> metricsNotifier = ValueNotifier(const TopicNodeMetrics());

  bool isExpanded = false;

  bool get isBranch => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;
}

int _compareSegments(String left, String right) {
  final folded = left.toLowerCase().compareTo(right.toLowerCase());
  return folded == 0 ? left.compareTo(right) : folded;
}
