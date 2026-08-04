import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/history/message_history_service.dart';
import '../../core/mqtt/connection_status.dart';
import '../../core/mqtt/mqtt_message.dart';
import '../../core/mqtt/mqtt_service.dart';
import '../../core/mqtt/topic_badge_counts.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/environment_variable.dart';
import '../../models/flat_tree_row.dart';
import '../../models/publish_shortcut.dart';
import '../../models/topic_node.dart';
import '../../models/topic_node_value.dart';

/// Regex that matches `${VAR_NAME}` placeholders in topic templates.
final _variablePlaceholderPattern = RegExp(r'\$\{([^}]+)\}');

/// Which part of a topic row is matched when filtering.
enum SearchScope { all, topic, value }

/// ViewModel for the monitor screen.
///
/// Manages the topic tree, connection state, and user interactions.
/// Widgets read state from this ViewModel and call its methods for actions.
class MonitorViewModel extends ChangeNotifier {
  // Constructor takes the MQTT service and app state manager, starts listening for messages.
  MonitorViewModel({
    required MqttService mqttService,
    required AppStateManager state,
    required MessageHistoryService historyService,
  }) : _mqtt = mqttService,
       _state = state,
       _history = historyService {
    _state.load(SettingsKeys.environmentVariables);
    _state.load(SettingsKeys.environmentVariableValues);
    _subscription = _mqtt.messageStream.listen(_onMessage);
    _activeBrokerId = activeBroker?.id;
    _state.addListener(_onStateChanged);
  }

  // Internal state
  final MqttService _mqtt;
  final AppStateManager _state;
  final MessageHistoryService _history;
  StreamSubscription<MQTTMessage>? _subscription;
  String? _activeBrokerId;

  // The topic tree is represented as a map of root nodes. Each node has a map of children, allowing for a dynamic tree structure.
  final Map<String, TopicTreeNode> _roots = {};

  // Currently selected node (for the detail panel).
  TopicTreeNode? _selectedNode;
  TopicTreeNode? get selectedNode => _selectedNode;

  /// Selects a node to display in the detail panel.
  void selectNode(TopicTreeNode? node) {
    if (_selectedNode == node) return;
    _selectedNode = node;
    notifyListeners();
  }

  // pendingTimers is used to track scheduled pulse animations for nodes, ensuring we respect the configured pulse
  // rate even under high message throughput.
  final Map<String, Timer> _pendingTimers = {};

  // Filter and search scope state
  String _filter = '';
  SearchScope _scope = SearchScope.all;

  // Whether any node is currently expanded (used to toggle between collapse/expand all).
  bool anyExpanded = false;

  // ── Filter & scope ────────────────────────────────────────────────────
  String get filter => _filter;
  SearchScope get scope => _scope;

  // Connection status and settings
  ConnectionStatus get connectionStatus =>
      _state.read(AppKeys.connectionStatus);
  String? get connectionError => _state.read(AppKeys.connectionError);
  int get messageCount => _state.read(AppKeys.messageCount);
  int get messageRate => _state.read(AppKeys.messageRate);
  bool get showStatusBar => _state.read(SettingsKeys.showStatusBar);
  // Brokers
  List<BrokerEntry> get brokers => _state.read(SettingsKeys.brokers);

  // The currently active broker, or null if no brokers are configured.
  BrokerEntry? get activeBroker {
    final list = brokers;
    if (list.isEmpty) return null;
    final id = _state.read(AppKeys.activeBrokerId);
    if (id != null && list.any((b) => b.id == id))
      return list.firstWhere((b) => b.id == id);
    return list.first;
  }

  /// Selects a broker by its ID.
  void selectBroker(String id) => _state.write(AppKeys.activeBrokerId, id);

  /// Disconnects from the current broker.
  void disconnect() => _mqtt.disconnect();

  /// Reconnects to the active broker.
  void reconnect() => _mqtt.reconnect();

  /// Publishes a message to the given topic.
  /// Returns `true` if the message was sent.
  bool publish(
    String topic,
    String payload, {
    int qos = 0,
    bool retain = false,
  }) {
    return _mqtt.publish(topic, payload, qos: qos, retain: retain);
  }

  /// Whether the client is currently connected.
  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  /// Shortcuts available for the currently active broker.
  ///
  /// Returns global shortcuts plus any scoped to the active broker.
  List<PublishShortcut> get availableShortcuts {
    final all = _state.read(SettingsKeys.shortcuts);
    final brokerId = activeBroker?.id;
    return all
        .where(
          (s) =>
              s.isGlobal ||
              (brokerId != null && s.brokerIds.contains(brokerId)),
        )
        .toList();
  }

  /// Environment variables visible to the currently active broker.
  List<EnvironmentVariable> get environmentVariables {
    final all = _state.read(SettingsKeys.environmentVariables);
    final brokerId = activeBroker?.id;
    return all
        .where(
          (v) =>
              v.isGlobal ||
              (brokerId != null && v.brokerIds.contains(brokerId)),
        )
        .toList();
  }

  /// Current values for each environment variable.
  Map<String, String> get variableValues =>
      _state.read(SettingsKeys.environmentVariableValues);

  /// Sets the value for a single environment variable.
  void setVariableValue(String name, String value) {
    final updated = Map<String, String>.from(variableValues)..[name] = value;
    _state.write(SettingsKeys.environmentVariableValues, updated);
  }

  /// Resolves `\${VAR_NAME}` placeholders in a shortcut topic using current variable values.
  String resolveShortcutTopic(String topic) {
    final values = variableValues;
    return topic.replaceAllMapped(
      _variablePlaceholderPattern,
      (m) => values[m.group(1)!] ?? m.group(0)!,
    );
  }

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
    _state.write(
      SettingsKeys.brokers,
      brokers.where((b) => b.id != id).toList(),
    );
  }

  /// Reacts to app state changes and clears the tree when the broker switches.
  void _onStateChanged() {
    final newId = activeBroker?.id;
    if (newId != _activeBrokerId) {
      _activeBrokerId = newId;
      _clearTree();
      _history.clear();
    }
    notifyListeners();
  }

  /// Handles an incoming MQTT message and inserts it into the topic tree.
  void _onMessage(MQTTMessage msg) {
    final segments = msg.topic.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    Map<String, TopicTreeNode> currentLevel = _roots;
    String path = '';
    final visitedNodes = <TopicTreeNode>[];

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      path = path.isEmpty ? seg : '$path/$seg';

      if (!currentLevel.containsKey(seg)) {
        currentLevel[seg] = TopicTreeNode(segment: seg, fullPath: path);
      }

      final node = currentLevel[seg]!;
      visitedNodes.add(node);

      if (i == segments.length - 1) {
        final prev = node.valueNotifier.value;
        node.valueNotifier.value = TopicNodeValue(
          payload: msg.payload,
          seq: (prev?.seq ?? 0) + 1,
          receivedAt: msg.receivedAt,
          retain: msg.retain,
          qos: msg.qos,
        );
      }

      currentLevel = node.children;
    }

    _schedulePulse(visitedNodes);
    notifyListeners();
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
    final elapsed = leaf.lastPulseAt == null
        ? minInterval
        : now.difference(leaf.lastPulseAt!);

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
      final nodeElapsed = node.lastPulseAt == null
          ? minInterval
          : now.difference(node.lastPulseAt!);
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
    anyExpanded = _allNodes(
      _roots.values,
    ).any((n) => n.isBranch && n.isExpanded);
    notifyListeners();
  }

  /// Collapses all nodes in the topic tree.
  void collapseAll() {
    for (final node in _allNodes(_roots.values)) {
      node.isExpanded = false;
    }
    anyExpanded = false;
    notifyListeners();
  }

  /// Expands all nodes in the topic tree.
  void expandAll() {
    for (final node in _allNodes(_roots.values)) {
      node.isExpanded = true;
    }
    anyExpanded = true;
    notifyListeners();
  }

  /// Removes a single topic from the tree (and its children).
  ///
  /// Also clears history for any topics in the removed subtree.
  void deleteTopic(TopicTreeNode node) {
    final segments = node.fullPath
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) return;

    // Collect all topic paths in the subtree so we can clear history.
    final removedTopics = <String>[];
    void collectPaths(TopicTreeNode n) {
      if (n.valueNotifier.value != null) removedTopics.add(n.fullPath);
      for (final child in n.children.values) {
        collectPaths(child);
      }
    }

    collectPaths(node);

    // Navigate to the parent level and remove the node.
    Map<String, TopicTreeNode> level = _roots;
    for (int i = 0; i < segments.length - 1; i++) {
      final parent = level[segments[i]];
      if (parent == null) return;
      level = parent.children;
    }
    level.remove(segments.last);

    // Prune empty ancestors.
    _pruneEmptyAncestors(segments);

    // Clear history for removed topics.
    _history.clearTopics(removedTopics);

    // Deselect if the deleted node was selected.
    if (_selectedNode != null &&
        _selectedNode!.fullPath.startsWith(node.fullPath)) {
      _selectedNode = null;
    }

    _pendingTimers.remove(node.fullPath)?.cancel();
    notifyListeners();
  }

  /// Removes empty ancestor nodes after a topic deletion.
  void _pruneEmptyAncestors(List<String> segments) {
    for (int depth = segments.length - 2; depth >= 0; depth--) {
      Map<String, TopicTreeNode> level = _roots;
      for (int i = 0; i < depth; i++) {
        final n = level[segments[i]];
        if (n == null) return;
        level = n.children;
      }
      final node = level[segments[depth]];
      if (node != null &&
          node.children.isEmpty &&
          node.valueNotifier.value == null) {
        level.remove(segments[depth]);
      } else {
        break;
      }
    }
  }

  /// Publishes an empty retained message to clear the retained value on the broker.
  bool clearRetainedMessage(String topic) {
    return _mqtt.publish(topic, '', qos: 0, retain: true);
  }

  /// Clears all topics from the tree and history.
  void clearAllTopics() {
    _clearTree();
    _history.clear();
  }

  /// Cancels pending timers and clears all topic tree data.
  void _clearTree() {
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
    _roots.clear();
    _selectedNode = null;
    notifyListeners();
  }

  /// Builds a flat list of rows from the topic tree for display.
  List<FlatTreeRow> buildFlatList() {
    final filterLower = _filter.toLowerCase().trim();
    final rows = <FlatTreeRow>[];
    final counts = deriveTopicBadgeCounts(
      _roots.values,
      includesTopic: (node) =>
          filterLower.isEmpty || _nodeMatchesFilter(node, filterLower),
    );

    void visit(TopicTreeNode node, int depth) {
      final nodeCounts = counts[node]!;
      if (filterLower.isNotEmpty && nodeCounts.topicCount == 0) return;

      rows.add(
        FlatTreeRow(
          node: node,
          depth: depth,
          topicCount: nodeCounts.topicCount,
          messageCount: nodeCounts.messageCount,
        ),
      );

      if (node.children.isNotEmpty && node.isExpanded) {
        final sorted = node.children.values.toList()
          ..sort(
            (a, b) =>
                a.segment.toLowerCase().compareTo(b.segment.toLowerCase()),
          );
        for (final child in sorted) {
          visit(child, depth + 1);
        }
      }
    }

    final sortedRoots = _roots.values.toList()
      ..sort(
        (a, b) => a.segment.toLowerCase().compareTo(b.segment.toLowerCase()),
      );
    for (final root in sortedRoots) {
      visit(root, 0);
    }

    return rows;
  }

  /// Returns true if the node or any of its children match the filter.
  bool _subtreeMatchesFilter(TopicTreeNode node, String filterLower) {
    if (_nodeMatchesFilter(node, filterLower)) return true;
    for (final child in node.children.values) {
      if (_subtreeMatchesFilter(child, filterLower)) return true;
    }
    return false;
  }

  bool _nodeMatchesFilter(TopicTreeNode node, String filterLower) {
    final matchTopic =
        _scope != SearchScope.value &&
        node.fullPath.toLowerCase().contains(filterLower);
    if (matchTopic) return true;
    final payload = node.valueNotifier.value?.payload;
    final matchValue =
        _scope != SearchScope.topic &&
        payload != null &&
        payload.toLowerCase().contains(filterLower);
    return matchValue;
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
