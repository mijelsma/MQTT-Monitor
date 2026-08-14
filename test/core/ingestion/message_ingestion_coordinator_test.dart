import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/ingestion/ingested_message.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';

import '../../support/test_dependencies.dart';

void main() {
  test('creates one ordered value sequence per active broker and concrete topic', () async {
    final dependencies = await TestDependencies.create();
    final brokers = dependencies.brokers;
    await brokers.add(const BrokerEntryModel(id: 'first', name: 'First', host: 'first.invalid'));
    await brokers.add(const BrokerEntryModel(id: 'second', name: 'Second', host: 'second.invalid'), makeActive: false);
    final source = StreamController<MQTTMessage>.broadcast(sync: true);
    final ingestion = MessageIngestionCoordinator.fromStream(source.stream, brokers)..initialize();
    final received = <IngestedMessage>[];
    final subscription = ingestion.messages.listen(received.add);

    source
      ..add(_message('same/topic', 'one', 1))
      ..add(_message('same/topic', 'two', 2))
      ..add(_message('other/topic', 'other', 3));

    expect(received.map((message) => message.brokerId), everyElement('first'));
    expect(received.map((message) => message.value.seq), [1, 2, 1]);

    await brokers.select('second');
    source.add(_message('same/topic', 'new broker', 4));

    expect(received.last.brokerId, 'second');
    expect(received.last.value.seq, 1);

    await subscription.cancel();
    await ingestion.dispose();
    await source.close();
  });

  test('queued traffic from a replaced broker is discarded before the next session', () async {
    final dependencies = await TestDependencies.create();
    final brokers = dependencies.brokers;
    await brokers.add(const BrokerEntryModel(id: 'first', name: 'First', host: 'first.invalid'));
    await brokers.add(const BrokerEntryModel(id: 'second', name: 'Second', host: 'second.invalid'), makeActive: false);
    final source = StreamController<MQTTMessage>.broadcast(sync: true);
    final ingestion = MessageIngestionCoordinator.fromStream(source.stream, brokers, timeSliced: true)..initialize();
    final received = <IngestedMessage>[];
    final subscription = ingestion.messages.listen(received.add);

    for (var index = 0; index < 1000; index++) {
      source.add(_message('first/$index', '$index', 1));
    }
    expect(received, isEmpty);

    await brokers.select('second');
    source.add(_message('second/live', 'new', 2));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(received.where((message) => message.brokerId == 'first'), isEmpty);
    expect(received.last.brokerId, 'second');
    expect(received.last.topic, 'second/live');
    expect(received.last.value.seq, 1);

    await subscription.cancel();
    await ingestion.dispose();
    await source.close();
  });
}

MQTTMessage _message(String topic, String payload, int second) => MQTTMessage(topic: topic, payload: payload, receivedAt: DateTime(2026, 1, 1, 0, 0, second));
