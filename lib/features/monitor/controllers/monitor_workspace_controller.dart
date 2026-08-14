import 'package:flutter/foundation.dart';

import '../../../core/history/services/message_history_service.dart';
import '../../../core/monitor/topic_node_metrics.dart';
import '../../../core/monitor/topic_projection.dart';
import '../../../core/monitor/controllers/topic_pulse_controller.dart';
import '../../../core/mqtt/topic_badge_counts.dart';
import '../../../core/ui/repositories/ui_preferences_repository.dart';
import '../../../core/monitor/models/flat_tree_row_model.dart';
import '../../../core/monitor/models/topic_tree_node_model.dart';
import '../search_scope.dart';

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
  final Map<TopicTreeNodeModel, ValueNotifier<TopicNodeMetrics>> _filteredMetrics = {};
  final Map<TopicTreeNodeModel, TopicNodeMetrics> _filteredContributions = {};

  TopicTreeNodeModel? _selectedNode;
  String _filter = '';
  String _normalizedFilter = '';
  SearchScope _scope = SearchScope.all;
  List<FlatTreeRowModel> _visibleRows = const [];
  int _visibleRowDerivationCount = 0;
  String? _brokerId;

  TopicTreeNodeModel? get selectedNode => _selectedNode;
  String get filter => _filter;
  SearchScope get scope => _scope;
  List<FlatTreeRowModel> get visibleRows => _visibleRows;
  int get visibleRowDerivationCount => _visibleRowDerivationCount;

  bool get anyExpanded => _allNodes(_projection.roots).any((node) => node.isBranch && node.isExpanded);

  /// Selects a node for the detail and history panels.
  void selectNode(TopicTreeNodeModel? node) {
    if (identical(_selectedNode, node)) return;
    _selectedNode = node;
    notifyListeners();
  }

  /// Applies a filter and expands branches containing matches on first entry.
  void setFilter(String value) {
    if (_filter == value) return;
    final wasEmpty = _normalizedFilter.isEmpty;
    _filter = value;
    _normalizedFilter = value.toLowerCase().trim();
    _refreshFilteredIndex();
    if (_normalizedFilter.isNotEmpty && wasEmpty) {
      _expandFilteredBranches();
    }
    _deriveVisibleRows();
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
  void toggleExpand(TopicTreeNodeModel node) {
    node.isExpanded = !node.isExpanded;
    _deriveVisibleRows();
    notifyListeners();
  }

  /// Collapses every branch.
  void collapseAll() {
    for (final node in _allNodes(_projection.roots)) {
      node.isExpanded = false;
    }
    _deriveVisibleRows();
    notifyListeners();
  }

  /// Expands every branch.
  void expandAll() {
    for (final node in _allNodes(_projection.roots)) {
      node.isExpanded = true;
    }
    _deriveVisibleRows();
    notifyListeners();
  }

  /// Deletes a subtree and its corresponding in-memory history.
  void deleteTopic(TopicTreeNodeModel node) {
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
    if (_normalizedFilter.isEmpty) {
      _pulses.schedule(update.path, _uiPreferences.pulseRatePps);
      return;
    }

    if (update.structureChanged) {
      if (_isVisibleInFilter(update.path.last)) {
        _pulses.schedule(update.path, _uiPreferences.pulseRatePps);
      }
      return;
    }

    final updatedNode = update.path.last;
    final previous = _filteredContributions[updatedNode] ?? const TopicNodeMetrics();
    final next = _filteredContributionFor(updatedNode);
    _filteredContributions[updatedNode] = next;

    final delta = next.subtract(previous);
    if (delta != const TopicNodeMetrics()) {
      for (final node in update.path) {
        final metrics = _filteredMetrics.putIfAbsent(node, () => ValueNotifier(const TopicNodeMetrics()));
        metrics.value = metrics.value.add(topics: delta.topicCount, messages: delta.messageCount);
      }
    }

    if (_isVisibleInFilter(updatedNode)) {
      _pulses.schedule(update.path, _uiPreferences.pulseRatePps);
    }
    if (previous.topicCount != next.topicCount) {
      _deriveVisibleRows();
      notifyListeners();
    }
  }

  void _rebuildRows() {
    _refreshFilteredIndex();
    _deriveVisibleRows();
  }

  void _refreshFilteredIndex() {
    _filteredContributions.clear();
    if (_normalizedFilter.isEmpty) return;

    final filteredCounts = deriveTopicBadgeCounts(
      _projection.roots,
      includesTopic: (node) {
        final value = node.valueNotifier.value;
        if (value != null) {
          final contribution = _filteredContributionFor(node);
          _filteredContributions[node] = contribution;
          return contribution.topicCount == 1;
        }
        return false;
      },
    );
    for (final entry in filteredCounts.entries) {
      final notifier = _filteredMetrics.putIfAbsent(entry.key, () => ValueNotifier(const TopicNodeMetrics()));
      notifier.value = TopicNodeMetrics(topicCount: entry.value.topicCount, messageCount: entry.value.messageCount);
    }
  }

  void _deriveVisibleRows() {
    _visibleRowDerivationCount++;
    final rows = <FlatTreeRowModel>[];
    final filterActive = _normalizedFilter.isNotEmpty;

    void visit(TopicTreeNodeModel node, int depth) {
      if (filterActive && !_isVisibleInFilter(node)) {
        return;
      }
      rows.add(FlatTreeRowModel(node: node, depth: depth, metrics: filterActive ? _filteredMetrics.putIfAbsent(node, () => ValueNotifier(const TopicNodeMetrics())) : node.metricsNotifier));
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

  void _expandFilteredBranches() {
    void visit(TopicTreeNodeModel node) {
      if (node.isBranch && _isVisibleInFilter(node)) {
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

  bool _isVisibleInFilter(TopicTreeNodeModel node) => (_filteredMetrics[node]?.value.topicCount ?? 0) > 0;

  TopicNodeMetrics _filteredContributionFor(TopicTreeNodeModel node) {
    final value = node.valueNotifier.value;
    if (value == null || !_nodeMatchesFilter(node, _normalizedFilter)) {
      return const TopicNodeMetrics();
    }
    return TopicNodeMetrics(topicCount: 1, messageCount: value.seq);
  }

  bool _nodeMatchesFilter(TopicTreeNodeModel node, String filter) {
    if (_scope != SearchScope.value && node.fullPath.toLowerCase().contains(filter)) {
      return true;
    }
    final payload = node.valueNotifier.value?.payload;
    return _scope != SearchScope.topic && payload != null && payload.toLowerCase().contains(filter);
  }

  bool _isWithin(String? candidate, String root) => candidate != null && (candidate == root || candidate.startsWith('$root/'));

  Iterable<TopicTreeNodeModel> _allNodes(Iterable<TopicTreeNodeModel> nodes) sync* {
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
