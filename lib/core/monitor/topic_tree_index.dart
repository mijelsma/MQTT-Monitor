import 'dart:collection';

import '../../core/monitor/models/topic_tree_node_model.dart';
import '../ingestion/ingested_message.dart';

/// Owns the sorted topic tree and updates subtree totals incrementally.
class TopicTreeIndex {
  final SplayTreeMap<String, TopicTreeNodeModel> _roots = SplayTreeMap(_compareSegments);

  /// Returns roots in stable case-insensitive display order.
  Iterable<TopicTreeNodeModel> get roots => _roots.values;

  /// Returns whether no topic nodes are indexed.
  bool get isEmpty => _roots.isEmpty;

  /// Inserts [message] and returns its node path plus structural-change state.
  ({List<TopicTreeNodeModel> path, bool structureChanged, bool topicCreated}) insert(IngestedMessage message) {
    final segments = message.topic.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) {
      return (path: const [], structureChanged: false, topicCreated: false);
    }

    Map<String, TopicTreeNodeModel> level = _roots;
    final path = <TopicTreeNodeModel>[];
    var fullPath = '';
    var structureChanged = false;
    for (final segment in segments) {
      fullPath = fullPath.isEmpty ? segment : '$fullPath/$segment';
      var node = level[segment];
      if (node == null) {
        node = TopicTreeNodeModel(segment: segment, fullPath: fullPath);
        level[segment] = node;
        structureChanged = true;
      }
      path.add(node);
      level = node.children;
    }

    final leaf = path.last;
    final isFirstValue = leaf.valueNotifier.value == null;
    leaf.valueNotifier.value = message.value;
    for (final node in path) {
      node.metricsNotifier.value = node.metricsNotifier.value.add(topics: isFirstValue ? 1 : 0, messages: 1);
    }
    return (path: List.unmodifiable(path), structureChanged: structureChanged, topicCreated: isFirstValue);
  }

  /// Returns the existing node path for a concrete topic.
  List<TopicTreeNodeModel> pathFor(String topic) {
    final segments = topic.split('/').where((segment) => segment.isNotEmpty);
    Map<String, TopicTreeNodeModel> level = _roots;
    final path = <TopicTreeNodeModel>[];
    for (final segment in segments) {
      final node = level[segment];
      if (node == null) return const [];
      path.add(node);
      level = node.children;
    }
    return List.unmodifiable(path);
  }

  /// Removes [node], prunes empty ancestors, and returns concrete topic paths.
  List<String> delete(TopicTreeNodeModel node) {
    final segments = node.fullPath.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return const [];

    final ancestorPath = pathFor(node.fullPath);
    if (ancestorPath.isEmpty || !identical(ancestorPath.last, node)) {
      return const [];
    }
    final removedMetrics = node.metricsNotifier.value;
    final removedTopics = <String>[];
    _collectConcreteTopics(node, removedTopics);

    Map<String, TopicTreeNodeModel> level = _roots;
    for (var index = 0; index < segments.length - 1; index++) {
      level = level[segments[index]]!.children;
    }
    level.remove(segments.last);

    for (final ancestor in ancestorPath.take(ancestorPath.length - 1)) {
      ancestor.metricsNotifier.value = ancestor.metricsNotifier.value.subtract(removedMetrics);
    }
    _pruneEmptyAncestors(segments);
    return List.unmodifiable(removedTopics);
  }

  /// Clears all indexed topics.
  void clear() => _roots.clear();

  void _collectConcreteTopics(TopicTreeNodeModel node, List<String> target) {
    if (node.valueNotifier.value != null) target.add(node.fullPath);
    for (final child in node.children.values) {
      _collectConcreteTopics(child, target);
    }
  }

  void _pruneEmptyAncestors(List<String> segments) {
    for (var depth = segments.length - 2; depth >= 0; depth--) {
      Map<String, TopicTreeNodeModel> level = _roots;
      for (var index = 0; index < depth; index++) {
        final parent = level[segments[index]];
        if (parent == null) return;
        level = parent.children;
      }
      final candidate = level[segments[depth]];
      if (candidate == null || candidate.children.isNotEmpty || candidate.valueNotifier.value != null) {
        return;
      }
      level.remove(segments[depth]);
    }
  }
}

int _compareSegments(String left, String right) {
  final folded = left.toLowerCase().compareTo(right.toLowerCase());
  return folded == 0 ? left.compareTo(right) : folded;
}
