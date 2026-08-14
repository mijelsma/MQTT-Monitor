import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/dashboard/repositories/dashboard_repository.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_series_store.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_value_extractor.dart';
import 'package:mqtt_monitor/core/ingestion/ingested_message.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/publishing/models/environment_variable_model.dart';
import 'package:mqtt_monitor/core/dashboard/models/graph_card_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_node_value_model.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;
  late DashboardRepository repository;
  late DashboardSeriesStore series;
  late StreamController<IngestedMessage> messages;
  var decodeCount = 0;

  setUp(() async {
    decodeCount = 0;
    dependencies = await TestDependencies.create();
    await dependencies.brokers.add(const BrokerEntryModel(id: 'a', name: 'A', host: 'a.invalid'));
    await dependencies.brokers.add(const BrokerEntryModel(id: 'b', name: 'B', host: 'b.invalid'), makeActive: false);
    repository = DashboardRepository(dependencies.preferences, dependencies.brokers);
    await repository.initialize();
    messages = StreamController<IngestedMessage>.broadcast(sync: true);
    series = DashboardSeriesStore(
      messages: messages.stream,
      repository: repository,
      variables: dependencies.variables,
      templateResolver: dependencies.templateResolver,
      extractor: DashboardValueExtractor(
        decoder: (source) {
          decodeCount++;
          return jsonDecode(source);
        },
      ),
    )..initialize();
  });

  tearDown(() async {
    await series.dispose();
    repository.dispose();
    await messages.close();
  });

  test('decodes one payload once for multiple matching JSON cards', () async {
    await repository.setCards('a', [_card('temperature', topic: 'sensor', path: 'temperature'), _card('humidity', topic: 'sensor', path: 'values[0]')]);

    messages.add(_message('a', 'sensor', '{"temperature":21.5,"values":[48]}'));

    expect(decodeCount, 1);
    expect(series.currentSeries('a', 'temperature').single.value, 21.5);
    expect(series.currentSeries('a', 'humidity').single.value, 48);
  });

  test('collects while no dashboard route exists and hard-bounds every series', () async {
    await repository.setCards('a', [_card('value', maximum: 3)]);

    for (var value = 1; value <= 5; value++) {
      messages.add(_message('a', 'topic', '$value', second: value));
    }

    expect(series.currentSeries('a', 'value').map((point) => point.value), [3, 4, 5]);
    expect(decodeCount, 0);
  });

  test('notifies only the affected card series', () async {
    await repository.setCards('a', [_card('first', topic: 'first'), _card('second', topic: 'second')]);
    var firstNotifications = 0;
    var secondNotifications = 0;
    series.seriesFor('a', 'first').addListener(() => firstNotifications++);
    series.seriesFor('a', 'second').addListener(() => secondNotifications++);

    messages.add(_message('a', 'first', '1'));

    expect(firstNotifications, 1);
    expect(secondNotifications, 0);
  });

  test('variable changes clear only rerouted series and reject the old topic', () async {
    await dependencies.variables.add(EnvironmentVariableModel(name: 'ID'));
    await dependencies.variables.setValue('ID', 'one');
    await repository.setCards('a', [_card('variable', topic: r'sensor/${ID}')]);
    messages.add(_message('a', 'sensor/one', '1'));
    expect(series.currentSeries('a', 'variable'), hasLength(1));

    await dependencies.variables.setValue('ID', 'two');
    expect(series.currentSeries('a', 'variable'), isEmpty);
    messages
      ..add(_message('a', 'sensor/one', '2'))
      ..add(_message('a', 'sensor/two', '3'));

    expect(series.currentSeries('a', 'variable').map((point) => point.value), [3]);
  });

  test('isolates identical card IDs and topics across brokers', () async {
    await repository.setCards('a', [_card('shared')]);
    await repository.setCards('b', [_card('shared')]);

    messages.add(_message('a', 'topic', '7'));

    expect(series.currentSeries('a', 'shared').single.value, 7);
    expect(series.currentSeries('b', 'shared'), isEmpty);
  });

  test('ignores malformed and nonnumeric data without disturbing existing points', () async {
    await repository.setCards('a', [_card('json', path: 'value')]);
    messages
      ..add(_message('a', 'topic', '{"value":1}'))
      ..add(_message('a', 'topic', '{broken'))
      ..add(_message('a', 'topic', '{"value":true}'));

    expect(series.currentSeries('a', 'json').map((point) => point.value), [1]);
  });
}

GraphCardModel _card(String id, {String topic = 'topic', String? path, int maximum = 500}) {
  return GraphCardModel(id: id, topic: topic, jsonKeyPath: path, displayName: id, colorValue: 0xFF000000, maxDataPoints: maximum);
}

IngestedMessage _message(String brokerId, String topic, String payload, {int second = 0}) {
  return IngestedMessage(
    brokerId: brokerId,
    topic: topic,
    value: TopicNodeValueModel(payload: payload, seq: 1, receivedAt: DateTime(2026, 1, 1, 0, 0, second)),
  );
}
