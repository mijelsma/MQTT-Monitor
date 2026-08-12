import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/ingestion/ingested_message.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';

import '../../support/test_dependencies.dart';

void main() {
  test('creates one ordered value sequence per active broker and concrete topic', () async {
    final dependencies = await TestDependencies.create();
    final brokers = dependencies.brokers;
    await brokers.add(const BrokerEntry(id: 'first', name: 'First', host: 'first.invalid'));
    await brokers.add(const BrokerEntry(id: 'second', name: 'Second', host: 'second.invalid'), makeActive: false);
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
}

MQTTMessage _message(String topic, String payload, int second) => MQTTMessage(topic: topic, payload: payload, receivedAt: DateTime(2026, 1, 1, 0, 0, second));
