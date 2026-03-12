import 'package:flutter/foundation.dart';

import 'topic_node_value.dart';

export 'flat_tree_row.dart';
export 'topic_node_value.dart';

/// A node in the MQTT topic tree.
///
/// Branch nodes (nodes with children) represent path segments that have never
/// directly received a payload.  Leaf nodes (no children, or nodes that have
/// received a payload) hold their last value via [valueNotifier].
class TopicTreeNode {
  TopicTreeNode({required this.segment, required this.fullPath});

  /// The single path segment this node represents (e.g. `"sensors"`).
  final String segment;

  /// The full slash-joined topic path up to this node (e.g. `"home/sensors"`).
  final String fullPath;

  /// Ordered map of child segment → child node.
  final Map<String, TopicTreeNode> children = {};

  /// Timestamp of the last pulse emitted for this node (leaf rate-limit gate).
  DateTime? lastPulseAt;

  /// Notifier for the last received value at this node.
  /// `null` = no payload has ever arrived at exactly this path.
  final ValueNotifier<TopicNodeValue?> valueNotifier = ValueNotifier(null);

  /// Incremented whenever any message arrives at this node OR any descendant.
  /// Used by [TopicTreeRow] to trigger the pulse animation on ancestor rows.
  final ValueNotifier<int> pulseNotifier = ValueNotifier(0);

  /// Incremented on every message, un-rate-limited, so row badges can update
  /// immediately without waiting for a [TopicTreeController.notifyListeners] cycle.
  final ValueNotifier<int> countNotifier = ValueNotifier(0);

  /// Total number of messages received at this node and all descendants.
  int subtreeMsgCount = 0;

  /// Number of leaf endpoint topics in this subtree (nodes with no children).
  /// `my/new/sensor/one` + `my/new/sensor/two` → 2, not 4.
  int get subtreeTopicCount {
    if (children.isEmpty) return 1; // this node IS the endpoint
    int count = 0;
    for (final child in children.values) {
      count += child.subtreeTopicCount;
    }
    return count;
  }

  /// Display counts used by row badges — set by the controller in
  /// [TopicTreeController.buildFlatList] on every rebuild.
  /// When no filter is active these equal [subtreeTopicCount]/[subtreeMsgCount];
  /// when a filter is active they reflect only the matching sub-tree.
  int displayTopicCount = 0;
  int displayMsgCount = 0;

  /// Whether the subtree below this node is currently expanded in the UI.
  bool isExpanded = false;

  /// Whether this node is a branch (has children) or a leaf (no children).
  /// Note that a node can be both a branch and a leaf if it has received
  /// messages directly at its path as well as at descendant paths.
  bool get isBranch => children.isNotEmpty;

  /// Whether this node is a leaf (no children).
  /// Note that a node can be both a branch and a leaf if it has received
  /// messages directly at its path as well as at descendant paths.
  bool get isLeaf => children.isEmpty;
}
