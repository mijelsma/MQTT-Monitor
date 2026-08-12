import 'dart:async';

import '../../models/topic_node.dart';

/// Rate-limits topic activity pulses and owns every delayed pulse timer.
class TopicPulseController {
  TopicPulseController({DateTime Function()? clock, Timer Function(Duration duration, void Function() callback)? timerFactory}) : _clock = clock ?? DateTime.now, _timerFactory = timerFactory ?? Timer.new;

  final DateTime Function() _clock;
  final Timer Function(Duration duration, void Function() callback) _timerFactory;
  final Map<String, Timer> _pending = {};

  /// Schedules a pulse for [path] at no more than [pulsesPerSecond].
  void schedule(List<TopicTreeNode> path, int pulsesPerSecond) {
    if (path.isEmpty) return;
    final leaf = path.last;
    final interval = Duration(milliseconds: 1000 ~/ pulsesPerSecond.clamp(1, 100));
    final now = _clock();
    final elapsed = leaf.lastPulseAt == null ? interval : now.difference(leaf.lastPulseAt!);

    _pending.remove(leaf.fullPath)?.cancel();
    if (elapsed >= interval) {
      _fire(path, interval);
      return;
    }
    _pending[leaf.fullPath] = _timerFactory(interval - elapsed, () {
      _pending.remove(leaf.fullPath);
      _fire(path, interval);
    });
  }

  /// Cancels delayed pulses for a topic and its descendants.
  void cancelSubtree(String topic) {
    final prefix = '$topic/';
    final keys = _pending.keys.where((key) => key == topic || key.startsWith(prefix)).toList();
    for (final key in keys) {
      _pending.remove(key)?.cancel();
    }
  }

  /// Cancels all delayed pulses.
  void clear() {
    for (final timer in _pending.values) {
      timer.cancel();
    }
    _pending.clear();
  }

  void _fire(List<TopicTreeNode> path, Duration interval) {
    final now = _clock();
    for (final node in path) {
      final elapsed = node.lastPulseAt == null ? interval : now.difference(node.lastPulseAt!);
      if (elapsed < interval) continue;
      node.lastPulseAt = now;
      node.pulseNotifier.value++;
    }
  }
}
