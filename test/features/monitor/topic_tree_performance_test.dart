import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/monitor/topic_node_metrics.dart';
import 'package:mqtt_monitor/core/ui/repositories/ui_preferences_repository.dart';
import 'package:mqtt_monitor/features/monitor/topic_payload_preview.dart';
import 'package:mqtt_monitor/features/monitor/widgets/topic_tree_list.dart';
import 'package:mqtt_monitor/features/monitor/widgets/topic_tree_row.dart';
import 'package:mqtt_monitor/core/monitor/models/flat_tree_row_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_tree_node_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
  });

  testWidgets('rapid distant scrolling stays within topic-scaling budgets', (tester) async {
    const budgets = {10: Duration(milliseconds: 500), 100: Duration(milliseconds: 1200), 1000: Duration(milliseconds: 1200)};
    final results = <({int topics, Duration elapsed})>[];

    for (final entry in budgets.entries) {
      final fixture = _TopicTreeFixture.create(entry.key);
      await tester.pumpWidget(_treeApp(fixture.rows, dependencies.uiPreferences));
      await tester.pump();

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.itemExtent, topicTreeItemExtent);
      expect(find.byType(TopicTreeRow).evaluate().length, lessThan(25));

      final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
      await _jumpBetweenEnds(tester, position, repetitions: 2);

      var pulseControllersCreated = 0;
      void trackPulseControllers(ObjectEvent event) {
        final object = event.object;
        if (event is ObjectCreated && object is AnimationController && object.debugLabel?.startsWith('TopicTreeRow pulse:') == true) {
          pulseControllersCreated++;
        }
      }

      FlutterMemoryAllocations.instance.addListener(trackPulseControllers);
      final stopwatch = Stopwatch()..start();
      await _jumpBetweenEnds(tester, position, repetitions: 12);
      stopwatch.stop();
      FlutterMemoryAllocations.instance.removeListener(trackPulseControllers);

      results.add((topics: entry.key, elapsed: stopwatch.elapsed));
      expect(find.byType(TopicTreeRow).evaluate().length, lessThan(25), reason: 'Live row widgets must remain bounded by the viewport cache.');
      expect(pulseControllersCreated, 0, reason: 'Scrolling inactive rows must not allocate pulse controllers.');

      await tester.pumpWidget(const SizedBox.shrink());
      fixture.dispose();
    }

    debugPrint('Topic-tree rapid-scroll regression guard, 24 jumps per case:');
    debugPrint('topics | elapsed µs | budget µs');
    for (final result in results) {
      debugPrint(
        '${result.topics} | ${result.elapsed.inMicroseconds} | '
        '${budgets[result.topics]!.inMicroseconds}',
      );
      expect(result.elapsed, lessThan(budgets[result.topics]!), reason: '${result.topics}-topic rapid scrolling exceeded its regression budget.');
    }
  });

  testWidgets('pulse animation remains lazy and preserves its fade behavior', (tester) async {
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    final node = TopicTreeNodeModel(segment: 'temperature', fullPath: 'temperature')..valueNotifier.value = TopicNodeValueModel(payload: '21.5', seq: 1, receivedAt: DateTime(2026));
    await dependencies.uiPreferences.setPulseFadeMs(500);
    await dependencies.uiPreferences.setShowActivity(false);

    var pulseControllersCreated = 0;
    void trackPulseControllers(ObjectEvent event) {
      final object = event.object;
      if (event is ObjectCreated && object is AnimationController && object.debugLabel == 'TopicTreeRow pulse: temperature') {
        pulseControllersCreated++;
      }
    }

    FlutterMemoryAllocations.instance.addListener(trackPulseControllers);
    await tester.pumpWidget(_rowApp(node, dependencies.uiPreferences));
    expect(pulseControllersCreated, 0);
    expect(await _pulseAlpha(tester), 0);

    node.pulseNotifier.value++;
    await tester.pump();
    expect(pulseControllersCreated, 0);
    expect(await _pulseAlpha(tester), 0);

    await dependencies.uiPreferences.setShowActivity(true);
    var rowRebuilds = 0;
    var overlayRebuilds = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is TopicTreeRow) rowRebuilds++;
      if (element.widget.key == const ValueKey('topic-pulse-overlay')) {
        overlayRebuilds++;
      }
    };
    node.pulseNotifier.value++;
    await tester.pump();
    expect(pulseControllersCreated, 1);
    expect(rowRebuilds, 0);
    expect(overlayRebuilds, 1);
    expect(await _pulseAlpha(tester), closeTo(0.28, 0.01));

    await tester.pump(const Duration(milliseconds: 250));
    final halfwayAlpha = await _pulseAlpha(tester);
    expect(halfwayAlpha, greaterThan(0));
    expect(halfwayAlpha, lessThan(0.28));
    expect(rowRebuilds, 0);
    expect(overlayRebuilds, 1);

    node.pulseNotifier.value++;
    await tester.pump();
    expect(pulseControllersCreated, 1);
    expect(await _pulseAlpha(tester), closeTo(0.28, 0.01));
    expect(rowRebuilds, 0);
    expect(overlayRebuilds, 1);

    await tester.pump(const Duration(milliseconds: 501));
    expect(await _pulseAlpha(tester), 0);
    expect(rowRebuilds, 0);
    expect(overlayRebuilds, 1);

    await dependencies.uiPreferences.setPulseFadeMs(50);
    node.pulseNotifier.value++;
    await tester.pump();
    expect(await _pulseAlpha(tester), closeTo(0.28, 0.01));
    await tester.pump(const Duration(milliseconds: 51));
    expect(await _pulseAlpha(tester), 0);
    expect(rowRebuilds, 0);
    expect(overlayRebuilds, 1);

    await dependencies.uiPreferences.setPulseFadeMs(2000);
    node.pulseNotifier.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(await _pulseAlpha(tester), greaterThan(0));
    expect(await _pulseAlpha(tester), lessThan(0.28));
    await tester.pump(const Duration(milliseconds: 1001));
    expect(await _pulseAlpha(tester), 0);
    expect(rowRebuilds, 0);
    expect(overlayRebuilds, 1);

    node.valueNotifier.value = TopicNodeValueModel(payload: '22.0', seq: 2, receivedAt: DateTime(2026, 1, 1, 0, 0, 1));
    node.metricsNotifier.value = const TopicNodeMetrics(topicCount: 1, messageCount: 2);
    await tester.pump();
    expect(rowRebuilds, 1);
    expect(overlayRebuilds, 2);

    node.pulseNotifier.value++;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);

    debugOnRebuildDirtyWidget = null;
    FlutterMemoryAllocations.instance.removeListener(trackPulseControllers);
    node.valueNotifier.dispose();
    node.pulseNotifier.dispose();
    node.metricsNotifier.dispose();
  });

  testWidgets('frequent pulses remain repaint-only during distant scrolling', (tester) async {
    await dependencies.uiPreferences.setShowActivity(true);
    await dependencies.uiPreferences.setPulseFadeMs(500);
    final fixture = _TopicTreeFixture.create(1000);
    await tester.pumpWidget(_treeApp(fixture.rows, dependencies.uiPreferences));
    await tester.pump();
    final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    await _jumpBetweenEnds(tester, position, repetitions: 2);

    var dirtyRowRebuilds = 0;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce && element.widget is TopicTreeRow) dirtyRowRebuilds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < 24; iteration++) {
      for (final row in fixture.rows) {
        row.node.pulseNotifier.value++;
      }
      position.jumpTo(iteration.isEven ? position.maxScrollExtent : position.minScrollExtent);
      await tester.pump(const Duration(milliseconds: 16));
    }
    stopwatch.stop();

    expect(dirtyRowRebuilds, 0);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.dispose();
  });

  testWidgets('large and control-heavy payloads use bounded previews while scrolling', (tester) async {
    final controlPattern = String.fromCharCodes(List<int>.generate(32, (index) => index));
    final payloads = {'one-megabyte-ascii': List.filled(1024 * 1024, 'x').join(), 'one-megabyte-controls': List.filled(1024 * 1024 ~/ controlPattern.length, controlPattern).join()};
    const scales = [10, 100, 1000];
    const budget = Duration(seconds: 2);

    for (final payloadEntry in payloads.entries) {
      for (final topicTotal in scales) {
        final fixture = _TopicTreeFixture.create(topicTotal, payload: payloadEntry.value);
        await tester.pumpWidget(_treeApp(fixture.rows, dependencies.uiPreferences));
        await tester.pump();

        final raw = fixture.rows.first.node.valueNotifier.value!.payload;
        expect(identical(raw, payloadEntry.value), isTrue);
        final preview = _visiblePayloadPreview(tester);
        expect(preview.runes.length, lessThanOrEqualTo(topicPayloadPreviewMaxRunes));
        expect(preview.length, lessThan(raw.length));
        expect(preview.runes.any((rune) => rune <= 0x1F || (rune >= 0x7F && rune <= 0x9F) || rune == 0x2028 || rune == 0x2029), isFalse);

        final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
        await _jumpBetweenEnds(tester, position, repetitions: 2);
        final stopwatch = Stopwatch()..start();
        await _jumpBetweenEnds(tester, position, repetitions: 12);
        stopwatch.stop();
        debugPrint(
          'Topic-tree bounded-preview guard: ${payloadEntry.key}, '
          '$topicTotal topics, ${stopwatch.elapsedMicroseconds} µs',
        );
        expect(
          stopwatch.elapsed,
          lessThan(budget),
          reason:
              '${payloadEntry.key} at $topicTotal topics exceeded the '
              'bounded-preview scrolling budget.',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        fixture.dispose();
      }
    }
  });

  testWidgets('fixed row extent expands for accessibility text scaling', (tester) async {
    final fixture = _TopicTreeFixture.create(10);
    await tester.pumpWidget(_treeApp(fixture.rows, dependencies.uiPreferences, textScaler: const TextScaler.linear(2)));

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.itemExtent, greaterThan(topicTreeItemExtent));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    fixture.dispose();
  });
}

Future<void> _jumpBetweenEnds(WidgetTester tester, ScrollPosition position, {required int repetitions}) async {
  for (var i = 0; i < repetitions; i++) {
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    position.jumpTo(position.minScrollExtent);
    await tester.pump();
  }
}

Widget _rowApp(TopicTreeNodeModel node, UiPreferencesRepository preferences) => ChangeNotifierProvider.value(
  value: preferences,
  child: MaterialApp(
    theme: themeLight,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: TopicTreeRow(node: node, depth: 0, metrics: node.metricsNotifier, onToggle: () {}),
      ),
    ),
  ),
);

Widget _treeApp(List<FlatTreeRowModel> rows, UiPreferencesRepository preferences, {TextScaler textScaler = TextScaler.noScaling}) => ChangeNotifierProvider.value(
  value: preferences,
  child: MaterialApp(
    theme: themeLight,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Scaffold(
      body: SizedBox(
        width: 500,
        height: 120,
        child: TopicTreeList(rows: rows, selectedNode: null, onToggle: (_) {}, onSelect: (_) {}),
      ),
    ),
  ),
);

Future<double> _pulseAlpha(WidgetTester tester) async {
  final boundaries = find.descendant(of: find.byKey(const ValueKey('topic-pulse-overlay')), matching: find.byType(RepaintBoundary));
  if (boundaries.evaluate().isEmpty) return 0;
  final boundary = tester.renderObject<RenderRepaintBoundary>(boundaries);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    final alpha = bytes!.getUint8(3) / 255;
    image.dispose();
    return alpha;
  }))!;
}

String _visiblePayloadPreview(WidgetTester tester) {
  final richText = tester.widget<RichText>(find.descendant(of: find.byType(TopicTreeRow).first, matching: find.byType(RichText)).first);
  final root = richText.text as TextSpan;
  return (root.children!.last as TextSpan).text!;
}

class _TopicTreeFixture {
  _TopicTreeFixture(this.rows);

  final List<FlatTreeRowModel> rows;

  static _TopicTreeFixture create(int topicTotal, {String? payload}) {
    final rows = List<FlatTreeRowModel>.generate(topicTotal, (index) {
      final path = 'topic-${index.toString().padLeft(4, '0')}';
      final node = TopicTreeNodeModel(segment: path, fullPath: path)..valueNotifier.value = TopicNodeValueModel(payload: payload ?? '$index', seq: 1, receivedAt: DateTime(2026));
      return FlatTreeRowModel(node: node, depth: 0, metrics: node.metricsNotifier);
    });
    return _TopicTreeFixture(rows);
  }

  void dispose() {
    for (final row in rows) {
      row.node.valueNotifier.dispose();
      row.node.pulseNotifier.dispose();
      row.node.metricsNotifier.dispose();
    }
  }
}
