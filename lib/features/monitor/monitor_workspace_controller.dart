import 'package:flutter/foundation.dart';

import '../../core/history/message_history_service.dart';
import '../../core/monitor/topic_node_metrics.dart';
import '../../core/monitor/topic_projection.dart';
import '../../core/monitor/topic_pulse_controller.dart';
import '../../core/mqtt/topic_badge_counts.dart';
import '../../core/ui/ui_preferences_repository.dart';
import '../../models/flat_tree_row.dart';
import '../../models/topic_node.dart';
import 'search_scope.dart';

/// Owns monitor selection, filtering, expansion, pulses, and cached rows.
class MonitorWorkspaceController extends ChangeNotifier {
  MonitorWorkspaceController({required TopicProjection projection, required MessageHistoryService history, required UiPreferencesRepository uiPreferences, TopicPulseController? pulses}) : _projection = projection, _history = history, _uiPreferences = uiPreferences, _pulses = pulses ?? TopicPulseController() {
    _projection.addListener(_onStructureChanged);
    _projection.updates.addListener(_onProjectionUpdate);
    _rebuildRows();
  }

  final TopicProjection _projection;
  final MessageHistoryService _history;
  final UiPreferencesRepository _uiPreferences;
  final TopicPulseController _pulses;
  final Map<TopicTreeNode, ValueNotifier<TopicNodeMetrics>> _filteredMetrics = {};

  TopicTreeNode? _selectedNode;
  String _filter = '';
  SearchScope _scope = SearchScope.all;
  List<FlatTreeRow> _visibleRows = const [];
  int _visibleRowDerivationCount = 0;
  String? _brokerId;

  TopicTreeNode? get selectedNode => _selectedNode;
  String get filter => _filter;
  SearchScope get scope => _scope;
  List<FlatTreeRow> get visibleRows => _visibleRows;
  int get visibleRowDerivationCount => _visibleRowDerivationCount;

  bool get anyExpanded => _allNodes(_projection.roots).any((node) => node.isBranch && node.isExpanded);

  /// Selects a node for the detail and history panels.
  void selectNode(TopicTreeNode? node) {
    if (identical(_selectedNode, node)) return;
    _selectedNode = node;
    notifyListeners();
  }

  /// Applies a filter and expands branches containing matches on first entry.
  void setFilter(String value) {
    if (_filter == value) return;
    final wasEmpty = _normalizedFilter.isEmpty;
    _filter = value;
    if (_normalizedFilter.isNotEmpty && wasEmpty) {
      _expandMatchingBranches(_normalizedFilter);
    }
    _rebuildRows();
    notifyListeners();
  }

  /// Changes which fields participate in monitor filtering.
  void setScope(SearchScope value) {
    if (_scope == value) return;
    _scope = value;
    _rebuildRows();
    notifyListeners();
  }

  /// Toggles one branch and refreshes the cached visible row list.
  void toggleExpand(TopicTreeNode node) {
    node.isExpanded = !node.isExpanded;
    _rebuildRows();
    notifyListeners();
  }

  /// Collapses every branch.
  void collapseAll() {
    for (final node in _allNodes(_projection.roots)) {
      node.isExpanded = false;
    }
    _rebuildRows();
    notifyListeners();
  }

  /// Expands every branch.
  void expandAll() {
    for (final node in _allNodes(_projection.roots)) {
      node.isExpanded = true;
    }
    _rebuildRows();
    notifyListeners();
  }

  /// Deletes a subtree and its corresponding in-memory history.
  void deleteTopic(TopicTreeNode node) {
    if (_isWithin(_selectedNode?.fullPath, node.fullPath)) {
      _selectedNode = null;
    }
    _pulses.cancelSubtree(node.fullPath);
    final topics = _projection.delete(node);
    _history.clearTopics(topics);
  }

  /// Clears the current broker's topic projection and history.
  void clearAllTopics() {
    _selectedNode = null;
    _pulses.clear();
    _projection.clear();
    _history.clear();
  }

  void _onStructureChanged() {
    if (_brokerId != _projection.brokerId) {
      _brokerId = _projection.brokerId;
      _pulses.clear();
    }
    final selected = _selectedNode;
    if (selected != null) {
      final path = _projection.pathFor(selected.fullPath);
      if (path.isEmpty || !identical(path.last, selected)) _selectedNode = null;
    }
    _rebuildRows();
    notifyListeners();
  }

  void _onProjectionUpdate() {
    final update = _projection.updates.value;
    if (update == null) return;
    final filter = _normalizedFilter;
    if (filter.isEmpty || _subtreeMatchesFilter(update.path.last, filter)) {
      _pulses.schedule(update.path, _uiPreferences.pulseRatePps);
    }
    if (filter.isEmpty || update.structureChanged) return;

    final topicMatches = update.path.last.fullPath.toLowerCase().contains(filter);
    if (_scope == SearchScope.topic || (_scope == SearchScope.all && topicMatches)) {
      if (!topicMatches) return;
      for (final node in update.path) {
        final metrics = _filteredMetrics[node];
        if (metrics != null) {
          metrics.value = metrics.value.add(topics: update.topicCreated ? 1 : 0, messages: 1);
        }
      }
      return;
    }

    _rebuildRows();
    notifyListeners();
  }

  void _rebuildRows() {
    _visibleRowDerivationCount++;
    final filter = _normalizedFilter;
    final rows = <FlatTreeRow>[];
    Map<TopicTreeNode, TopicBadgeCounts>? filteredCounts;
    if (filter.isNotEmpty) {
      filteredCounts = deriveTopicBadgeCounts(_projection.roots, includesTopic: (node) => _nodeMatchesFilter(node, filter));
      for (final entry in filteredCounts.entries) {
        final notifier = _filteredMetrics.putIfAbsent(entry.key, () => ValueNotifier(const TopicNodeMetrics()));
        notifier.value = TopicNodeMetrics(topicCount: entry.value.topicCount, messageCount: entry.value.messageCount);
      }
    }

    void visit(TopicTreeNode node, int depth) {
      if (filteredCounts != null && filteredCounts[node]!.topicCount == 0) {
        return;
      }
      rows.add(FlatTreeRow(node: node, depth: depth, metrics: filteredCounts == null ? node.metricsNotifier : _filteredMetrics[node]!));
      if (!node.isExpanded) return;
      for (final child in node.children.values) {
        visit(child, depth + 1);
      }
    }

    for (final root in _projection.roots) {
      visit(root, 0);
    }
    _visibleRows = List.unmodifiable(rows);
  }

  void _expandMatchingBranches(String filter) {
    void visit(TopicTreeNode node) {
      if (node.isBranch && _subtreeMatchesFilter(node, filter)) {
        node.isExpanded = true;
      }
      for (final child in node.children.values) {
        visit(child);
      }
    }

    for (final root in _projection.roots) {
      visit(root);
    }
  }

  String get _normalizedFilter => _filter.toLowerCase().trim();

  bool _subtreeMatchesFilter(TopicTreeNode node, String filter) {
    if (_nodeMatchesFilter(node, filter)) return true;
    return node.children.values.any((child) => _subtreeMatchesFilter(child, filter));
  }

  bool _nodeMatchesFilter(TopicTreeNode node, String filter) {
    if (_scope != SearchScope.value && node.fullPath.toLowerCase().contains(filter)) {
      return true;
    }
    final payload = node.valueNotifier.value?.payload;
    return _scope != SearchScope.topic && payload != null && payload.toLowerCase().contains(filter);
  }

  bool _isWithin(String? candidate, String root) => candidate != null && (candidate == root || candidate.startsWith('$root/'));

  Iterable<TopicTreeNode> _allNodes(Iterable<TopicTreeNode> nodes) sync* {
    for (final node in nodes) {
      yield node;
      yield* _allNodes(node.children.values);
    }
  }

  /// Releases projection signals, filtered count notifiers, and pulse timers.
  @override
  void dispose() {
    _projection.removeListener(_onStructureChanged);
    _projection.updates.removeListener(_onProjectionUpdate);
    _pulses.clear();
    for (final notifier in _filteredMetrics.values) {
      notifier.dispose();
    }
    super.dispose();
  }
}
