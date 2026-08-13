import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/models/graph_card_model.dart';

import 'pipeline_acceptance_fixture.dart';
import 'traffic_generator.dart';

void main() {
  group('production pipeline performance acceptance', () {
    test('10,000-message bursts remain lossless across topic scales', () async {
      const messageCount = 10000;
      const budgets = {10: Duration(seconds: 5), 100: Duration(seconds: 5), 1000: Duration(seconds: 8)};
      final results = <({int topics, TrafficRun run})>[];

      for (final entry in budgets.entries) {
        final fixture = await PipelineAcceptanceFixture.create(historyEnabled: false);
        final generator = TrafficGenerator(topicCount: entry.key);
        final run = await fixture.replay(generator.messages(messageCount));

        expect(fixture.processed, messageCount);
        expect(run.peakBacklog, greaterThan(0), reason: 'The asynchronous burst must exercise queued work.');
        expect(run.totalElapsed, lessThan(entry.value));
        expect(fixture.history.bufferCount, 0, reason: 'Disabled history must not allocate buffers.');
        expect(fixture.projection.pathFor('devices/device-0/value'), isNotEmpty);
        results.add((topics: entry.key, run: run));
        await fixture.dispose();
      }

      _printRuns('10,000-message asynchronous burst', results);
    });

    test('payload shapes remain lossless and bounded', () async {
      const cases = <({TrafficPayload payload, int messages, int topics, Duration budget})>[
        (payload: TrafficPayload.smallText, messages: 10000, topics: 100, budget: Duration(seconds: 5)),
        (payload: TrafficPayload.malformedUtf8, messages: 10000, topics: 100, budget: Duration(seconds: 5)),
        (payload: TrafficPayload.json10Kb, messages: 2000, topics: 100, budget: Duration(seconds: 8)),
        (payload: TrafficPayload.json1Mb, messages: 40, topics: 10, budget: Duration(seconds: 8)),
      ];

      for (final testCase in cases) {
        final fixture = await PipelineAcceptanceFixture.create(historyEnabled: false);
        final generator = TrafficGenerator(topicCount: testCase.topics);
        final run = await fixture.replay(generator.messages(testCase.messages, payload: testCase.payload));

        expect(run.messages, testCase.messages);
        expect(fixture.processed, testCase.messages);
        expect(run.totalElapsed, lessThan(testCase.budget));
        expect(fixture.history.bufferCount, 0);
        final latest = fixture.projection.pathFor('devices/device-0/value').last.valueNotifier.value;
        expect(latest, isNotNull);
        if (testCase.payload == TrafficPayload.malformedUtf8) {
          expect(latest!.payload, contains('\uFFFD'));
        }
        debugPrint('${testCase.payload.name}: ${testCase.messages} messages, ${run.totalElapsed.inMicroseconds} us, ${run.messagesPerSecond.toStringAsFixed(0)} msg/s');
        await fixture.dispose();
      }
    });

    test('minimum typical maximum and disabled history policies stay bounded', () async {
      for (final retention in [1, 10, 1000]) {
        final fixture = await PipelineAcceptanceFixture.create(historyRetention: retention);
        final generator = TrafficGenerator(topicCount: 2);
        await fixture.replay(generator.messages(retention * 2 + 20));

        expect(fixture.history.bufferCount, 2);
        expect(fixture.history.getHistory('devices/device-0/value'), hasLength(retention));
        expect(fixture.history.getHistory('devices/device-1/value'), hasLength(retention));
        await fixture.dispose();
      }

      final disabled = await PipelineAcceptanceFixture.create(historyEnabled: false);
      await disabled.replay(TrafficGenerator(topicCount: 1000).messages(10000));
      expect(disabled.history.bufferCount, 0);
      await disabled.dispose();
    });

    test('dashboard routing scales across 1 20 and 100 bounded cards', () async {
      const messageCount = 1000;
      const budgets = {1: Duration(seconds: 2), 20: Duration(seconds: 4), 100: Duration(seconds: 8)};

      for (final entry in budgets.entries) {
        final cards = _cards(entry.key, maximumSamples: 5);
        final fixture = await PipelineAcceptanceFixture.create(historyEnabled: false, cards: cards);
        final signal = fixture.dashboard.seriesFor(PipelineAcceptanceFixture.brokerId, cards.first.id);
        void listener() {}

        for (var cycle = 0; cycle < 20; cycle++) {
          signal.addListener(listener);
          signal.removeListener(listener);
        }
        final run = await fixture.replay(TrafficGenerator(topicCount: 1).messages(messageCount, payload: TrafficPayload.smallJson));

        expect(run.totalElapsed, lessThan(entry.value));
        for (final card in cards) {
          final values = fixture.dashboard.currentSeries(PipelineAcceptanceFixture.brokerId, card.id);
          expect(values, hasLength(5));
          expect(values.last.value, card.jsonKeyPath == 'metrics.secondary' ? messageCount : messageCount - 1);
        }
        debugPrint('${entry.key} dashboard cards: ${run.totalElapsed.inMicroseconds} us');
        await fixture.dispose();
      }
    });

    test('long replay has bounded logical ownership and no gross RSS growth', () async {
      const messageCount = 100000;
      const topicCount = 1000;
      const historyRetention = 5;
      final fixture = await PipelineAcceptanceFixture.create(historyRetention: historyRetention, cards: _cards(20, maximumSamples: 50));
      final generator = TrafficGenerator(topicCount: topicCount);
      final rssBefore = ProcessInfo.currentRss;
      final run = await fixture.replay(generator.messages(messageCount, payload: TrafficPayload.smallJson));
      final rssAfter = ProcessInfo.currentRss;
      final rssGrowth = rssAfter - rssBefore;

      expect(run.messages, messageCount);
      expect(fixture.history.bufferCount, topicCount);
      for (var topic = 0; topic < topicCount; topic++) {
        expect(fixture.history.getHistory('devices/device-$topic/value').length, lessThanOrEqualTo(historyRetention));
      }
      for (final card in _cards(20, maximumSamples: 50)) {
        expect(fixture.dashboard.currentSeries(PipelineAcceptanceFixture.brokerId, card.id).length, lessThanOrEqualTo(50));
      }
      expect(rssGrowth, lessThan(384 * 1024 * 1024), reason: 'A bounded 100,000-message replay must not retain hundreds of MiB. RSS is intentionally a generous gross guard because VM allocation and GC timing vary.');
      debugPrint('Long replay: ${run.totalElapsed.inMicroseconds} us, ${run.messagesPerSecond.toStringAsFixed(0)} msg/s, RSS before $rssBefore, after $rssAfter, growth $rssGrowth bytes');
      await fixture.dispose();
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

List<GraphCardModel> _cards(int count, {required int maximumSamples}) => [for (var index = 0; index < count; index++) GraphCardModel(id: 'card-$index', topic: 'devices/device-0/value', jsonKeyPath: index.isEven ? 'metrics.value' : 'metrics.secondary', displayName: 'Card $index', colorValue: 0xff000000 + index, maxDataPoints: maximumSamples)];

void _printRuns(String name, List<({int topics, TrafficRun run})> results) {
  debugPrint(name);
  debugPrint('topics | total us | peak backlog | msg/s');
  for (final result in results) {
    debugPrint('${result.topics} | ${result.run.totalElapsed.inMicroseconds} | ${result.run.peakBacklog} | ${result.run.messagesPerSecond.toStringAsFixed(0)}');
  }
}
