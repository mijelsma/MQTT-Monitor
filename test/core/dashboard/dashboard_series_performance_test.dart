import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/dashboard/repositories/dashboard_repository.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_series_store.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_value_extractor.dart';
import 'package:mqtt_monitor/core/ingestion/ingested_message.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/dashboard/models/graph_card_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';

import '../../support/test_dependencies.dart';

void main() {
  test('parse-once routing stays within card-scaling budgets without traffic writes', () async {
    const messageCount = 1000;
    const cases = <({int cards, Duration budget})>[(cards: 10, budget: Duration(seconds: 1)), (cards: 100, budget: Duration(seconds: 3)), (cards: 1000, budget: Duration(seconds: 12))];
    final results = <({int cards, int microseconds})>[];

    for (final testCase in cases) {
      final dependencies = await TestDependencies.create();
      await dependencies.brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'broker.invalid'));
      final repository = DashboardRepository(dependencies.preferences, dependencies.brokers);
      await repository.initialize();
      await repository.setCards('broker', [for (var index = 0; index < testCase.cards; index++) GraphCardModel(id: 'card-$index', topic: 'sensor', jsonKeyPath: 'value', displayName: 'Card $index', colorValue: 0xFF000000, maxDataPoints: 1)]);
      final persistedBefore = dependencies.preferences.get('${DashboardRepository.cardsKeyPrefix}broker');
      final messages = StreamController<IngestedMessage>.broadcast(sync: true);
      var decodes = 0;
      final series = DashboardSeriesStore(
        messages: messages.stream,
        repository: repository,
        variables: dependencies.variables,
        templateResolver: dependencies.templateResolver,
        extractor: DashboardValueExtractor(
          decoder: (source) {
            decodes++;
            return jsonDecode(source);
          },
        ),
      )..initialize();

      for (var sequence = 1; sequence <= 100; sequence++) {
        messages.add(
          IngestedMessage(
            brokerId: 'broker',
            topic: 'sensor',
            value: TopicNodeValueModel(
              payload: '{"value":$sequence}',
              seq: sequence,
              receivedAt: DateTime(2026, 1, 1).add(Duration(milliseconds: sequence)),
            ),
          ),
        );
      }
      decodes = 0;

      final stopwatch = Stopwatch()..start();
      for (var sequence = 1; sequence <= messageCount; sequence++) {
        messages.add(
          IngestedMessage(
            brokerId: 'broker',
            topic: 'sensor',
            value: TopicNodeValueModel(
              payload: '{"value":$sequence}',
              seq: sequence,
              receivedAt: DateTime(2026, 1, 1).add(Duration(milliseconds: sequence)),
            ),
          ),
        );
      }
      stopwatch.stop();

      expect(decodes, messageCount, reason: 'A payload must be decoded once, not once per matching card.');
      expect(series.currentSeries('broker', 'card-${testCase.cards - 1}').single.value, messageCount);
      expect(dependencies.preferences.get('${DashboardRepository.cardsKeyPrefix}broker'), persistedBefore, reason: 'Live traffic must not write dashboard configuration.');
      expect(stopwatch.elapsed, lessThan(testCase.budget));
      results.add((cards: testCase.cards, microseconds: stopwatch.elapsedMicroseconds));

      await series.dispose();
      await messages.close();
      repository.dispose();
    }

    // ignore: avoid_print
    print('Dashboard parse-once routing guard, $messageCount messages per case:');
    // ignore: avoid_print
    print('cards | elapsed us');
    for (final result in results) {
      // ignore: avoid_print
      print('${result.cards} | ${result.microseconds}');
    }
  });
}
