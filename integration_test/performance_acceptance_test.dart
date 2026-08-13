import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mqtt_monitor/core/monitor/topic_node_metrics.dart';
import 'package:mqtt_monitor/features/monitor/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/features/monitor/widgets/topic_tree.dart';
import 'package:mqtt_monitor/features/monitor/widgets/topic_tree_list.dart';
import 'package:mqtt_monitor/models/flat_tree_row.dart';
import 'package:mqtt_monitor/models/topic_node.dart';
import 'package:mqtt_monitor/models/topic_node_value.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../test/performance/pipeline_acceptance_fixture.dart';
import '../test/performance/traffic_generator.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile-mode pipeline and topic-tree acceptance', (tester) async {
    const idleSeconds = int.fromEnvironment('PERFORMANCE_IDLE_SECONDS', defaultValue: 1);
    final rssStart = ProcessInfo.currentRss;
    final report = <String, Object?>{'mode': 'profile', 'device': Platform.operatingSystem, 'idleSeconds': idleSeconds, 'rssStartBytes': rssStart};
    final startup = Stopwatch()..start();
    final fixture = await PipelineAcceptanceFixture.create(historyRetention: 5);
    startup.stop();
    report['fixtureStartupUs'] = startup.elapsedMicroseconds;
    debugPrint('Profile fixture ready in ${startup.elapsedMicroseconds} us, RSS $rssStart bytes');

    final idleRssBefore = ProcessInfo.currentRss;
    await Future<void>.delayed(Duration(seconds: idleSeconds));
    final idleRssAfter = ProcessInfo.currentRss;
    report['idle'] = {'durationSeconds': idleSeconds, 'rssBeforeBytes': idleRssBefore, 'rssAfterBytes': idleRssAfter, 'rssGrowthBytes': idleRssAfter - idleRssBefore};
    debugPrint('Profile idle: $idleSeconds s, RSS growth ${idleRssAfter - idleRssBefore} bytes');

    report['lowTraffic10PerSecond'] = await _pacedTraffic(fixture, messagesPerSecond: 10, seconds: 2);
    report['sustainedTraffic1000PerSecond'] = await _pacedTraffic(fixture, messagesPerSecond: 1000, seconds: 3);

    for (final topics in [10, 100, 1000]) {
      final run = await fixture.replay(TrafficGenerator(topicCount: topics).messages(10000, startSequence: fixture.processed));
      report['burst${topics}Topics'] = _runData(run);
      debugPrint('Profile burst, $topics topics: ${run.totalElapsed.inMicroseconds} us');
    }

    final longRun = await fixture.replay(TrafficGenerator(topicCount: 1000).messages(100000, payload: TrafficPayload.smallJson, startSequence: fixture.processed));
    report['longReplay'] = _runData(longRun);
    final rssAfterTraffic = ProcessInfo.currentRss;
    report['rssAfterTrafficBytes'] = rssAfterTraffic;
    debugPrint('Profile long replay: ${longRun.totalElapsed.inMicroseconds} us, RSS $rssAfterTraffic bytes');

    final rows = _ProfileTreeFixture.create(1000, TrafficGenerator(topicCount: 1).payloadFor(TrafficPayload.json1Mb, 0));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: fixture.dependencies.uiPreferences,
        child: MaterialApp(
          theme: themeLight,
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 300,
              child: TopicTreeList(rows: rows.rows, selectedNode: null, onToggle: (_) {}, onSelect: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> values) => timings.addAll(values);
    SchedulerBinding.instance.addTimingsCallback(collect);
    for (var pass = 0; pass < 12; pass++) {
      await tester.fling(find.byType(ListView), Offset(0, pass.isEven ? -2500 : 2500), 12000);
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await tester.pump(const Duration(milliseconds: 100));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    report['topicTreeFrames'] = _frameData(timings);
    debugPrint('Profile topic tree: ${report['topicTreeFrames']}');

    final uniqueFixture = await PipelineAcceptanceFixture.create(historyEnabled: false);
    final uniqueWorkspace = MonitorWorkspaceController(projection: uniqueFixture.projection, history: uniqueFixture.history, uiPreferences: uniqueFixture.dependencies.uiPreferences);
    final uniqueFilter = TextEditingController();
    await uniqueFixture.replay([MQTTMessage(topic: 'iot/device-warmup/value', payload: '0', receivedAt: DateTime.utc(2026))]);
    uniqueWorkspace.expandAll();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: uniqueFixture.dependencies.uiPreferences),
          ChangeNotifierProvider.value(value: uniqueWorkspace),
        ],
        child: MaterialApp(
          theme: themeLight,
          home: Scaffold(
            body: SizedBox(width: 800, height: 600, child: TopicTree(filterController: uniqueFilter)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final uniqueTimings = <FrameTiming>[];
    void collectUnique(List<FrameTiming> values) => uniqueTimings.addAll(values);
    SchedulerBinding.instance.addTimingsCallback(collectUnique);
    final uniqueHeartbeat = Stopwatch()..start();
    var uniqueHeartbeatCount = 0;
    var uniqueMaximumGapUs = 0;
    var previousHeartbeatUs = 0;
    final heartbeat = Timer.periodic(Duration.zero, (_) {
      final nowUs = uniqueHeartbeat.elapsedMicroseconds;
      final gapUs = nowUs - previousHeartbeatUs;
      if (gapUs > uniqueMaximumGapUs) uniqueMaximumGapUs = gapUs;
      previousHeartbeatUs = nowUs;
      uniqueHeartbeatCount++;
    });
    final uniqueRun = await uniqueFixture.replay(TrafficGenerator(topicCount: 1).uniqueTopicMessages(20000));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    heartbeat.cancel();
    SchedulerBinding.instance.removeTimingsCallback(collectUnique);
    report['uniqueTopicBurst'] = {..._runData(uniqueRun), 'heartbeats': uniqueHeartbeatCount, 'maximumHeartbeatGapUs': uniqueMaximumGapUs, 'frames': _frameData(uniqueTimings)};
    debugPrint('Profile unique-topic burst: ${report['uniqueTopicBurst']}');
    await tester.pumpWidget(const SizedBox.shrink());
    uniqueFilter.dispose();
    uniqueWorkspace.dispose();
    await uniqueFixture.dispose();

    final shutdown = Stopwatch()..start();
    await tester.pumpWidget(const SizedBox.shrink());
    rows.dispose();
    await fixture.dispose();
    shutdown.stop();
    report['fixtureShutdownUs'] = shutdown.elapsedMicroseconds;
    final rssEnd = ProcessInfo.currentRss;
    report['rssEndBytes'] = rssEnd;
    debugPrint('Profile shutdown: ${shutdown.elapsedMicroseconds} us, final RSS $rssEnd bytes');
    binding.reportData = report;
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Map<String, Object> _runData(TrafficRun run) => {'messages': run.messages, 'peakBacklog': run.peakBacklog, 'enqueueUs': run.enqueueElapsed.inMicroseconds, 'totalUs': run.totalElapsed.inMicroseconds, 'messagesPerSecond': run.messagesPerSecond};

Future<Map<String, Object>> _pacedTraffic(PipelineAcceptanceFixture fixture, {required int messagesPerSecond, required int seconds}) async {
  final generator = TrafficGenerator(topicCount: 1000);
  var peakBacklog = 0;
  var processingMicroseconds = 0;
  final wallClock = Stopwatch()..start();
  for (var second = 0; second < seconds; second++) {
    final interval = Stopwatch()..start();
    final run = await fixture.replay(generator.messages(messagesPerSecond, messagesPerSecond: messagesPerSecond, startSequence: fixture.processed));
    interval.stop();
    processingMicroseconds += run.totalElapsed.inMicroseconds;
    if (run.peakBacklog > peakBacklog) peakBacklog = run.peakBacklog;
    final remaining = const Duration(seconds: 1) - interval.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  }
  wallClock.stop();
  final result = <String, Object>{'messages': messagesPerSecond * seconds, 'targetMessagesPerSecond': messagesPerSecond, 'wallClockUs': wallClock.elapsedMicroseconds, 'processingUs': processingMicroseconds, 'peakBacklog': peakBacklog};
  debugPrint('Profile paced traffic, $messagesPerSecond msg/s for $seconds s: $result');
  return result;
}

Map<String, Object> _frameData(List<FrameTiming> timings) {
  if (timings.isEmpty) return {'frames': 0, 'missed16ms': 0, 'buildP90Us': 0, 'rasterP90Us': 0};
  final builds = timings.map((timing) => timing.buildDuration.inMicroseconds).toList()..sort();
  final rasters = timings.map((timing) => timing.rasterDuration.inMicroseconds).toList()..sort();
  final totals = timings.map((timing) => timing.totalSpan.inMicroseconds).toList();
  int percentile(List<int> values) => values[((values.length - 1) * 0.9).round()];
  return {'frames': timings.length, 'missed16ms': totals.where((value) => value > 16667).length, 'buildP90Us': percentile(builds), 'rasterP90Us': percentile(rasters), 'worstTotalUs': totals.reduce((left, right) => left > right ? left : right)};
}

class _ProfileTreeFixture {
  _ProfileTreeFixture(this.rows);

  final List<FlatTreeRow> rows;

  static _ProfileTreeFixture create(int topicCount, String payload) {
    final rows = List<FlatTreeRow>.generate(topicCount, (index) {
      final path = 'topic-${index.toString().padLeft(4, '0')}';
      final node = TopicTreeNode(segment: path, fullPath: path)
        ..valueNotifier.value = TopicNodeValue(payload: payload, seq: 1, receivedAt: DateTime.utc(2026))
        ..metricsNotifier.value = const TopicNodeMetrics(topicCount: 1, messageCount: 1);
      return FlatTreeRow(node: node, depth: 0, metrics: node.metricsNotifier);
    });
    return _ProfileTreeFixture(rows);
  }

  void dispose() {
    for (final row in rows) {
      row.node.valueNotifier.dispose();
      row.node.pulseNotifier.dispose();
      row.node.metricsNotifier.dispose();
    }
  }
}
