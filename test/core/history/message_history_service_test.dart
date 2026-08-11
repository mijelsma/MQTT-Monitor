import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';

import '../../support/test_dependencies.dart';

void main() {
  final state = AppStateManager.instance;
  late StreamController<MQTTMessage> messages;
  late MessageHistoryService history;
  late BrokerRepository brokers;

  setUp(() async {
    final dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
    messages = StreamController<MQTTMessage>.broadcast();
    history = MessageHistoryService.fromStream(messages.stream, state, brokers)..initialize();
  });

  tearDown(() async {
    history.dispose();
    await messages.close();
  });

  MQTTMessage message(String topic, String payload, int second) => MQTTMessage(topic: topic, payload: payload, receivedAt: DateTime(2026, 1, 1, 0, 0, second));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('trims normal history while preserving monotonic sequence numbers', () async {
    await state.write(SettingsKeys.defaultHistorySize, 2);

    messages
      ..add(message('sensor/value', 'one', 1))
      ..add(message('sensor/value', 'two', 2))
      ..add(message('sensor/value', 'three', 3));
    await settle();

    final values = history.getHistory('sensor/value');
    expect(values.map((value) => value.payload), ['two', 'three']);
    expect(values.map((value) => value.seq), [2, 3]);
  });

  test('increased monitoring uses the larger per-topic buffer', () async {
    await state.write(SettingsKeys.defaultHistorySize, 1);
    await state.write(SettingsKeys.increasedHistorySize, 3);
    history.enableIncreased('sensor/value');

    for (var i = 1; i <= 4; i++) {
      messages.add(message('sensor/value', '$i', i));
    }
    await settle();

    expect(history.getHistory('sensor/value').map((value) => value.payload), ['2', '3', '4']);
  });

  test('clearTopics resets only the selected topic and its sequence', () async {
    messages
      ..add(message('one', 'a', 1))
      ..add(message('two', 'b', 1));
    await settle();

    history.clearTopics(['one']);
    messages.add(message('one', 'new', 2));
    await settle();

    expect(history.getHistory('one').single.seq, 1);
    expect(history.getHistory('two').single.payload, 'b');
  });

  test('switching brokers clears all session history', () async {
    await brokers.add(const BrokerEntry(id: 'first', name: 'First', host: 'first.invalid'));
    await brokers.add(const BrokerEntry(id: 'second', name: 'Second', host: 'second.invalid'), makeActive: false);
    await brokers.select('first');
    messages.add(message('sensor/value', 'old session', 1));
    await settle();

    await brokers.select('second');

    expect(history.getHistory('sensor/value'), isEmpty);
  });
}
