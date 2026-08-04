import 'package:flutter/foundation.dart';

import 'topic_node_value.dart';

/// A node in the MQTT topic tree.
class TopicTreeNode {
  TopicTreeNode({required this.segment, required this.fullPath});

  final String segment;
  final String fullPath;
  final Map<String, TopicTreeNode> children = {};

  DateTime? lastPulseAt;

  final ValueNotifier<TopicNodeValue?> valueNotifier = ValueNotifier(null);
  final ValueNotifier<int> pulseNotifier = ValueNotifier(0);

  bool isExpanded = false;

  bool get isBranch => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;
}
