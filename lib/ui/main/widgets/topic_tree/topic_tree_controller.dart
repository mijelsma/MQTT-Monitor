import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../services/mqtt/models/mqtt_message.dart';
import '../../../../services/mqtt/mqtt_service.dart';
import '../../../../state/app_state.dart';
import '../../../../state/keys/app_keys.dart';
import '../../../../state/keys/settings_keys.dart';
import 'topic_tree_node.dart';

/// Manages the MQTT topic tree state, including message ingestion, tree structure, expand/collapse state, and filtering.
/// Structural changes (new nodes, expand/collapse, filter) cause [notifyListeners] so the parent widget rebuilds the flat row list.
/// Value changes for existing nodes are delivered exclusively through each node's [TopicTreeNode.valueNotifier] — the flat list
/// is NOT rebuilt on value updates, keeping row rebuilds more specific and efficient.
class TopicTreeController extends ChangeNotifier {
  // Subscribes to the MQTT message stream and updates the topic tree accordingly.
  TopicTreeController() {
    _subscription = MqttService.instance.messageStream.listen(_onMessage);
    _activeBrokerId = _state.read(AppKeys.activeBrokerId);
    _state.addListener(_onStateChanged);
  }

  // Access to global app state for reading settings and connection info.
  final AppStateManager _state = AppStateManager.instance;

  // Subscription to the MQTT message stream
  StreamSubscription<TopicMessage>? _subscription;

  // Cache of the currently active broker ID to detect changes.
  String? _activeBrokerId;

  // Root-level nodes keyed by their segment string.
  final Map<String, TopicTreeNode> _roots = {};

  // Deferred-pulse timers keyed by leaf fullPath. When a message is rate-limited, a timer is scheduled to fire one
  // coordinated pulse for the whole ancestor path after the rate window expires.
  final Map<String, Timer> _pendingTimers = {};

  /// Whether the tree is currently in the "all expanded" state.
  /// Switches when [expandAll] or [collapseAll] is called, and is also
  /// updated by individual [toggleExpand] calls.
  bool allExpanded = false;

  // Current filter string applied to the topic tree.
  String _filter = '';

  // Public getters for the current tree state.
  String get filter => _filter;

  /// Handles changes in the global app state, such as switching the active broker.
  void _onStateChanged() {
    // When the active broker changes, we need to clear the existing tree and start fresh.
    final newId = _state.read(AppKeys.activeBrokerId);

    // Only clear the tree if the broker ID actually changed. This avoids unnecessary rebuilds when unrelated state changes occur.
    if (newId != _activeBrokerId) {
      _activeBrokerId = newId;
      _clearTree();
    }
  }

  /// MQTT message handler: updates the topic tree structure and values based on incoming messages,
  /// then triggers pulses and notifies listeners as needed.
  void _onMessage(TopicMessage msg) {
    // Split and discard empty segments (handles leading/trailing slashes).
    final segments = msg.topic.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    bool structureChanged = false;
    Map<String, TopicTreeNode> currentLevel = _roots;
    String path = '';
    final visitedNodes = <TopicTreeNode>[];

    // Traverse or build the path down to the leaf node, creating new nodes as needed.
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      path = path.isEmpty ? seg : '$path/$seg';

      // Create a new node if this segment hasn't been seen before at the current level.
      if (!currentLevel.containsKey(seg)) {
        currentLevel[seg] = TopicTreeNode(segment: seg, fullPath: path);
        structureChanged = true;
      }

      // Move down into the child node for the next iteration.
      final node = currentLevel[seg]!;

      // Keep track of all visited nodes along the path for later pulsing.
      visitedNodes.add(node);

      // Only the last segment carries the payload value.
      if (i == segments.length - 1) {
        final prev = node.valueNotifier.value;
        // Update via ValueNotifier — does NOT trigger notifyListeners.
        node.valueNotifier.value = TopicNodeValue(payload: msg.payload, seq: (prev?.seq ?? 0) + 1);
      }

      // Continue down to the next level of the tree.
      currentLevel = node.children;
    }

    /// After processing the message and updating the tree, we need to trigger pulse animations on the affected nodes.
    /// Pulses are rate-limited per node based on the configured pulse rate, so we schedule them accordingly.
    _schedulePulse(visitedNodes);

    // Only rebuild the flat list when the tree structure actually changed.
    if (structureChanged) notifyListeners();
  }

  /// Schedules pulse animations for the given path of nodes, applying rate-limiting based on the configured pulse rate.
  void _schedulePulse(List<TopicTreeNode> path) {
    // If the path is empty, there's nothing to pulse.
    if (path.isEmpty) return;

    // The leaf node is the last one in the path, which is the one that received the new value and should be rate-limited.
    final leaf = path.last;
    final pps = _state.read(SettingsKeys.pulseRatePps);
    final minInterval = Duration(milliseconds: 1000 ~/ pps.clamp(1, 100));
    final now = DateTime.now();
    final elapsed = leaf.lastPulseAt == null ? minInterval : now.difference(leaf.lastPulseAt!);

    // Cancel any previously scheduled deferred pulse for this leaf.
    _pendingTimers.remove(leaf.fullPath)?.cancel();

    // If enough time has elapsed since the last pulse for this leaf, fire immediately. Otherwise, schedule a deferred pulse for when the rate window expires.
    if (elapsed >= minInterval) {
      _firePulse(path, minInterval);
    } else {
      final remaining = minInterval - elapsed;
      _pendingTimers[leaf.fullPath] = Timer(remaining, () {
        _pendingTimers.remove(leaf.fullPath);
        _firePulse(path, minInterval);
      });
    }
  }

  // Each node in the path is rate-limited independently using its own
  // [lastPulseAt]. This prevents a high-throughput parent (e.g. `my/topic` with
  // 100 active children) from pulsing faster than the configured rate even
  // though each individual leaf is already capped.
  void _firePulse(List<TopicTreeNode> path, Duration minInterval) {
    final now = DateTime.now();

    // Update the pulse timestamp and increment the pulse notifier for each node in the path, but only if its rate limit has expired.
    // This allows ancestor nodes to pulse when a descendant receives a message, while still respecting the configured pulse rate for each node.
    for (final node in path) {
      final nodeElapsed = node.lastPulseAt == null ? minInterval : now.difference(node.lastPulseAt!);
      if (nodeElapsed >= minInterval) {
        node.lastPulseAt = now;
        node.pulseNotifier.value++;
      }
    }
  }

  /// Update the filter text; triggers a flat-list rebuild if changed.
  void setFilter(String value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  /// Collapse or expand a branch node; triggers a flat-list rebuild.
  void toggleExpand(TopicTreeNode node) {
    node.isExpanded = !node.isExpanded;
    // Keep allExpanded in sync: true only if every branch is now expanded.
    allExpanded = _allNodes(_roots.values).every((n) => !n.isBranch || n.isExpanded);
    notifyListeners();
  }

  /// Collapse all branch nodes in the whole tree.
  void collapseAll() {
    for (final node in _allNodes(_roots.values)) {
      node.isExpanded = false;
    }
    allExpanded = false;
    notifyListeners();
  }

  /// Expand all branch nodes in the whole tree.
  void expandAll() {
    for (final node in _allNodes(_roots.values)) {
      node.isExpanded = true;
    }
    allExpanded = true;
    notifyListeners();
  }

  /// Remove all nodes and values from the tree.
  void clearAll() => _clearTree();

  void _clearTree() {
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
    _roots.clear();
    notifyListeners();
  }

  /// Build a flat, ordered list of [FlatTreeRow]s that should be rendered,
  /// respecting expand/collapse and the current [filter].
  List<FlatTreeRow> buildFlatList() {
    final filterLower = _filter.toLowerCase().trim();
    final rows = <FlatTreeRow>[];

    void visit(TopicTreeNode node, int depth) {
      // Skip node (and its subtree) if nothing inside matches the filter.
      if (filterLower.isNotEmpty && !_subtreeMatchesFilter(node, filterLower)) {
        return;
      }

      rows.add(FlatTreeRow(node: node, depth: depth));

      // Show children only when expanded (filter overrides collapse).
      if (node.children.isNotEmpty && (node.isExpanded || filterLower.isNotEmpty)) {
        final sorted = node.children.values.toList()..sort((a, b) => a.segment.toLowerCase().compareTo(b.segment.toLowerCase()));
        for (final child in sorted) {
          visit(child, depth + 1);
        }
      }
    }

    final sortedRoots = _roots.values.toList()..sort((a, b) => a.segment.toLowerCase().compareTo(b.segment.toLowerCase()));
    for (final root in sortedRoots) {
      visit(root, 0);
    }

    return rows;
  }

  /// Returns true when [node] or any of its descendants match [filterLower].
  bool _subtreeMatchesFilter(TopicTreeNode node, String filterLower) {
    if (node.fullPath.toLowerCase().contains(filterLower)) return true;
    final payload = node.valueNotifier.value?.payload;
    if (payload != null && payload.toLowerCase().contains(filterLower)) {
      return true;
    }
    for (final child in node.children.values) {
      if (_subtreeMatchesFilter(child, filterLower)) return true;
    }
    return false;
  }

  /// Recursively yields all nodes in the tree, starting from [nodes].
  Iterable<TopicTreeNode> _allNodes(Iterable<TopicTreeNode> nodes) sync* {
    for (final node in nodes) {
      yield node;
      yield* _allNodes(node.children.values);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _state.removeListener(_onStateChanged);
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
    _roots.clear();
    super.dispose();
  }
}
