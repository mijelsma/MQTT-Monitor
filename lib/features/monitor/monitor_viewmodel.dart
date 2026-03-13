import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/mqtt/connection_status.dart';
import '../../core/mqtt/mqtt_message.dart';
import '../../core/mqtt/mqtt_service.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/flat_tree_row.dart';
import '../../models/topic_node.dart';
import '../../models/topic_node_value.dart';

/// Which part of a topic row is matched when filtering.
enum SearchScope { all, topic, value }

/// ViewModel for the monitor screen.
///
/// Manages the topic tree, connection state, and user interactions.
/// Widgets read state from this ViewModel and call its methods for actions.
class MonitorViewModel extends ChangeNotifier {
  // Constructor takes the MQTT service and app state manager, starts listening for messages.
  MonitorViewModel({required MqttService mqttService, required AppStateManager state}) : _mqtt = mqttService, _state = state {
    _subscription = _mqtt.messageStream.listen(_onMessage);
    _activeBrokerId = activeBroker?.id;
    _state.addListener(_onStateChanged);
  }

  // Internal state
  final MqttService _mqtt;
  final AppStateManager _state;
  StreamSubscription<MQTTMessage>? _subscription;
  String? _activeBrokerId;

  // The topic tree is represented as a map of root nodes. Each node has a map of children, allowing for a dynamic tree structure.
  final Map<String, TopicTreeNode> _roots = {};

  // pendingTimers is used to track scheduled pulse animations for nodes, ensuring we respect the configured pulse
  // rate even under high message throughput.
  final Map<String, Timer> _pendingTimers = {};

  // Filter and search scope state
  String _filter = '';
  SearchScope _scope = SearchScope.all;

  // Whether all nodes are currently expanded (used to toggle between expand/collapse all).
  bool allExpanded = false;

  // ── Filter & scope ────────────────────────────────────────────────────
  String get filter => _filter;
  SearchScope get scope => _scope;

  // Counts of topics and messages currently displayed (after filtering)
  int filteredTopicCount = 0;
  int filteredMsgCount = 0;

  // Connection status and settings
  ConnectionStatus get connectionStatus => _state.read(AppKeys.connectionStatus);
  String? get connectionError => _state.read(AppKeys.connectionError);
  int get messageCount => _state.read(AppKeys.messageCount);
  int get messageRate => _state.read(AppKeys.messageRate);
  bool get showStatusBar => _state.read(SettingsKeys.showStatusBar);
  bool get showActivity => _state.read(SettingsKeys.showActivity);
  int get pulseFadeMs => _state.read(SettingsKeys.pulseFadeMs);

  // Brokers
  List<BrokerEntry> get brokers => _state.read(SettingsKeys.brokers);

  // The currently active broker, or null if no brokers are configured.
  BrokerEntry? get activeBroker {
    final list = brokers;
    if (list.isEmpty) return null;
    final id = _state.read(AppKeys.activeBrokerId);
    if (id != null && list.any((b) => b.id == id)) return list.firstWhere((b) => b.id == id);
    return list.first;
  }

  /// Selects a broker by its ID.
  void selectBroker(String id) => _state.write(AppKeys.activeBrokerId, id);

  /// Disconnects from the current broker.
  void disconnect() => _mqtt.disconnect();

  /// Reconnects to the active broker.
  void reconnect() => _mqtt.reconnect();

  /// Adds a new broker and makes it the active one.
  void addBroker(BrokerEntry entry) {
    _state.write(SettingsKeys.brokers, [...brokers, entry]);
    _state.write(AppKeys.activeBrokerId, entry.id);
  }

  /// Updates an existing broker entry in the list.
  void updateBroker(BrokerEntry updated) {
    final list = [...brokers];
    final i = list.indexWhere((b) => b.id == updated.id);
    if (i != -1) list[i] = updated;
    _state.write(SettingsKeys.brokers, list);
  }

  /// Deletes a broker by its ID.
  void deleteBroker(String id) {
    _state.write(SettingsKeys.brokers, brokers.where((b) => b.id != id).toList());
  }

  /// Reacts to app state changes and clears the tree when the broker switches.
  void _onStateChanged() {
    final newId = activeBroker?.id;
    if (newId != _activeBrokerId) {
      _activeBrokerId = newId;
      _clearTree();
    }
    notifyListeners();
  }

  /// Handles an incoming MQTT message and inserts it into the topic tree.
  void _onMessage(MQTTMessage msg) {
    final segments = msg.topic.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    bool structureChanged = false;
    Map<String, TopicTreeNode> currentLevel = _roots;
    String path = '';
    final visitedNodes = <TopicTreeNode>[];

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      path = path.isEmpty ? seg : '$path/$seg';

      if (!currentLevel.containsKey(seg)) {
        currentLevel[seg] = TopicTreeNode(segment: seg, fullPath: path);
        structureChanged = true;
      }

      final node = currentLevel[seg]!;
      visitedNodes.add(node);

      if (i == segments.length - 1) {
        final prev = node.valueNotifier.value;
        node.valueNotifier.value = TopicNodeValue(payload: msg.payload, seq: (prev?.seq ?? 0) + 1);
      }

      currentLevel = node.children;
    }

    for (final node in visitedNodes) {
      node.subtreeMsgCount++;
      node.displayMsgCount++;
      node.countNotifier.value++;
    }

    _schedulePulse(visitedNodes);

    final leafMatchesFilter = _filter.isNotEmpty && _subtreeMatchesFilter(visitedNodes.last, _filter.toLowerCase().trim());

    if (structureChanged || leafMatchesFilter) notifyListeners();
  }

  /// Schedules a pulse animation for the given node path, respecting rate limits.
  void _schedulePulse(List<TopicTreeNode> path) {
    if (path.isEmpty) return;

    if (_filter.isNotEmpty) {
      final filterLower = _filter.toLowerCase().trim();
      if (!_subtreeMatchesFilter(path.last, filterLower)) return;
    }

    final leaf = path.last;
    final pps = _state.read(SettingsKeys.pulseRatePps);
    final minInterval = Duration(milliseconds: 1000 ~/ pps.clamp(1, 100));
    final now = DateTime.now();
    final elapsed = leaf.lastPulseAt == null ? minInterval : now.difference(leaf.lastPulseAt!);

    _pendingTimers.remove(leaf.fullPath)?.cancel();

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

  /// Fires pulse notifications for each node in the path.
  void _firePulse(List<TopicTreeNode> path, Duration minInterval) {
    final now = DateTime.now();
    for (final node in path) {
      final nodeElapsed = node.lastPulseAt == null ? minInterval : now.difference(node.lastPulseAt!);
      if (nodeElapsed >= minInterval) {
        node.lastPulseAt = now;
        node.pulseNotifier.value++;
      }
    }
  }

  /// Sets the topic filter string and expands matching branches.
  void setFilter(String value) {
    if (_filter == value) return;
    final wasEmpty = _filter.isEmpty;
    _filter = value;
    if (value.isNotEmpty && wasEmpty) {
      _expandMatchingBranches(value.toLowerCase().trim());
    }
    notifyListeners();
  }

  /// Sets the search scope (topic, value, or all).
  void setScope(SearchScope value) {
    if (_scope == value) return;
    _scope = value;
    notifyListeners();
  }

  /// Expands all branches that contain nodes matching the filter.
  void _expandMatchingBranches(String filterLower) {
    void visit(TopicTreeNode node) {
      if (!node.isBranch) return;
      if (_subtreeMatchesFilter(node, filterLower)) node.isExpanded = true;
      for (final child in node.children.values) {
        visit(child);
      }
    }

    for (final root in _roots.values) {
      visit(root);
    }
  }

  /// Toggles the expanded state of a single node.
  void toggleExpand(TopicTreeNode node) {
    node.isExpanded = !node.isExpanded;
    allExpanded = _allNodes(_roots.values).every((n) => !n.isBranch || n.isExpanded);
    notifyListeners();
  }

  /// Collapses all nodes in the topic tree.
  void collapseAll() {
    for (final node in _allNodes(_roots.values)) {
      node.isExpanded = false;
    }
    allExpanded = false;
    notifyListeners();
  }

  /// Expands all nodes in the topic tree.
  void expandAll() {
    for (final node in _allNodes(_roots.values)) {
      node.isExpanded = true;
    }
    allExpanded = true;
    notifyListeners();
  }

  /// Clears the entire topic tree (public API).
  void clearAll() => _clearTree();

  /// Cancels pending timers and clears all topic tree data.
  void _clearTree() {
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
    _roots.clear();
    notifyListeners();
  }

  /// Builds a flat list of rows from the topic tree for display.
  List<FlatTreeRow> buildFlatList() {
    final filterLower = _filter.toLowerCase().trim();
    final rows = <FlatTreeRow>[];

    void visit(TopicTreeNode node, int depth) {
      if (filterLower.isNotEmpty && !_subtreeMatchesFilter(node, filterLower)) return;

      rows.add(FlatTreeRow(node: node, depth: depth));

      if (node.children.isNotEmpty && node.isExpanded) {
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

    for (final row in rows) {
      final (t, m) = _computeDisplayCounts(row.node, filterLower);
      row.node.displayTopicCount = t;
      row.node.displayMsgCount = m;
    }

    if (filterLower.isNotEmpty) {
      int tCount = 0;
      int mCount = 0;
      for (final row in rows) {
        if (row.node.children.isEmpty) {
          tCount++;
          mCount += row.node.subtreeMsgCount;
        }
      }
      filteredTopicCount = tCount;
      filteredMsgCount = mCount;
    } else {
      filteredTopicCount = 0;
      filteredMsgCount = 0;
    }

    return rows;
  }

  /// Computes the topic and message counts for a node, respecting the active filter.
  (int, int) _computeDisplayCounts(TopicTreeNode node, String filterLower) {
    if (node.children.isEmpty) {
      return (1, node.valueNotifier.value?.seq ?? 0);
    }
    int t = 0, m = 0;
    for (final child in node.children.values) {
      if (filterLower.isEmpty || _subtreeMatchesFilter(child, filterLower)) {
        final (ct, cm) = _computeDisplayCounts(child, filterLower);
        t += ct;
        m += cm;
      }
    }
    m += node.valueNotifier.value?.seq ?? 0;
    return (t, m);
  }

  /// Returns true if the node or any of its children match the filter.
  bool _subtreeMatchesFilter(TopicTreeNode node, String filterLower) {
    final matchTopic = _scope != SearchScope.value && node.fullPath.toLowerCase().contains(filterLower);
    if (matchTopic) return true;
    final payload = node.valueNotifier.value?.payload;
    final matchValue = _scope != SearchScope.topic && payload != null && payload.toLowerCase().contains(filterLower);
    if (matchValue) return true;
    for (final child in node.children.values) {
      if (_subtreeMatchesFilter(child, filterLower)) return true;
    }
    return false;
  }

  /// Yields all nodes in the tree recursively.
  Iterable<TopicTreeNode> _allNodes(Iterable<TopicTreeNode> nodes) sync* {
    for (final node in nodes) {
      yield node;
      yield* _allNodes(node.children.values);
    }
  }

  /// Cleans up subscriptions, timers, and tree data.
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
