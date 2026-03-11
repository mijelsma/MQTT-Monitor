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
