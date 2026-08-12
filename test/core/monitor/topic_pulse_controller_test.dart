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

  test('one pulse per second does not suppress slower messages', () {
    var now = DateTime(2026);
    final controller = TopicPulseController(clock: () => now);
    final leaf = TopicTreeNode(segment: 'leaf', fullPath: 'leaf');

    for (var message = 0; message < 5; message++) {
      controller.schedule([leaf], 1);
      now = now.add(const Duration(seconds: 2));
    }

    expect(leaf.pulseNotifier.value, 5);
    controller.clear();
  });

  test('shared ancestors are throttled across independently firing leaves', () {
    var now = DateTime(2026);
    final controller = TopicPulseController(clock: () => now);
    final root = TopicTreeNode(segment: 'root', fullPath: 'root');
    final first = TopicTreeNode(segment: 'first', fullPath: 'root/first');
    final second = TopicTreeNode(segment: 'second', fullPath: 'root/second');

    controller.schedule([root, first], 1);
    now = now.add(const Duration(milliseconds: 100));
    controller.schedule([root, second], 1);

    expect(root.pulseNotifier.value, 1);
    expect(first.pulseNotifier.value, 1);
    expect(second.pulseNotifier.value, 1);
    controller.clear();
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
