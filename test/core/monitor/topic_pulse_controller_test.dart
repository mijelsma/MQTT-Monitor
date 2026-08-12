import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/monitor/topic_pulse_controller.dart';
import 'package:mqtt_monitor/models/topic_node.dart';

void main() {
  test(
    'throttles repeated leaf pulses and propagates them through the path',
    () {
      var now = DateTime(2026);
      final timers = <_ManualTimer>[];
      final controller = TopicPulseController(
        clock: () => now,
        timerFactory: (_, callback) {
          final timer = _ManualTimer(callback);
          timers.add(timer);
          return timer;
        },
      );
      final root = TopicTreeNode(segment: 'root', fullPath: 'root');
      final leaf = TopicTreeNode(segment: 'leaf', fullPath: 'root/leaf');

      controller.schedule([root, leaf], 2);
      controller.schedule([root, leaf], 2);
      expect(root.pulseNotifier.value, 1);
      expect(leaf.pulseNotifier.value, 1);

      now = now.add(const Duration(milliseconds: 500));
      timers.single.fire();
      expect(root.pulseNotifier.value, 2);
      expect(leaf.pulseNotifier.value, 2);
      controller.clear();
    },
  );

  test('cancels delayed pulses for an entire deleted subtree', () {
    var now = DateTime(2026);
    final timers = <_ManualTimer>[];
    final controller = TopicPulseController(
      clock: () => now,
      timerFactory: (_, callback) {
        final timer = _ManualTimer(callback);
        timers.add(timer);
        return timer;
      },
    );
    final root = TopicTreeNode(segment: 'root', fullPath: 'root');
    final leaf = TopicTreeNode(segment: 'leaf', fullPath: 'root/leaf');

    controller.schedule([root, leaf], 1);
    controller.schedule([root, leaf], 1);
    controller.cancelSubtree('root');
    now = now.add(const Duration(seconds: 1));
    timers.single.fire();

    expect(root.pulseNotifier.value, 1);
    expect(leaf.pulseNotifier.value, 1);
  });
}

class _ManualTimer implements Timer {
  _ManualTimer(this._callback);

  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;
}
