import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';
import 'package:mqtt_monitor/models/subscription_history_policy.dart';

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
    await history.dispose();
    await messages.close();
  });

  MQTTMessage message(String topic, String payload, int second) => MQTTMessage(topic: topic, payload: payload, receivedAt: DateTime(2026, 1, 1, 0, 0, second));

  SubscriptionEntry subscription(String id, String filter, {bool enabled = true, int retention = 10}) => SubscriptionEntry(
    id: id,
    topic: filter,
    history: SubscriptionHistoryPolicy(enabled: enabled, retention: retention),
  );

  Future<void> addBroker(String id, List<SubscriptionEntry> subscriptions, {bool makeActive = true}) {
    return brokers
        .add(
          BrokerEntry(id: id, name: id, host: '$id.invalid', subscriptions: subscriptions),
          makeActive: makeActive,
        )
        .then((_) {});
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('bounds matching history while preserving sequence numbers', () async {
    await addBroker('broker', [subscription('all', '#', retention: 2)]);

    messages
      ..add(message('sensor/value', 'one', 1))
      ..add(message('sensor/value', 'two', 2))
      ..add(message('sensor/value', 'three', 3));
    await settle();

    final values = history.getHistory('sensor/value');
    expect(values.map((value) => value.payload), ['two', 'three']);
    expect(values.map((value) => value.seq), [2, 3]);
  });

  test('disabled history skips sequence, value, and buffer allocation', () async {
    await addBroker('broker', [subscription('all', '#', enabled: false)]);

    messages.add(message('sensor/value', 'ignored', 1));
    await settle();

    expect(history.bufferCount, 0);
    expect(history.getHistory('sensor/value'), isEmpty);
    expect(history.resolutionFor('sensor/value').enabled, isFalse);
  });

  test('overlapping enabled filters use the greatest retention', () async {
    await addBroker('broker', [subscription('all', 'sensors/#', retention: 2), subscription('specific', 'sensors/+/value', retention: 4), subscription('disabled', 'sensors/device/#', enabled: false)]);

    for (var index = 1; index <= 5; index++) {
      messages.add(message('sensors/device/value', '$index', index));
    }
    await settle();

    expect(history.getHistory('sensors/device/value').map((value) => value.payload), ['2', '3', '4', '5']);
  });

  test('disabling history preserves existing values and skips new work', () async {
    await addBroker('broker', [subscription('all', '#', retention: 3)]);
    messages.add(message('sensor/value', 'kept', 1));
    await settle();

    final broker = brokers.activeBroker!;
    await brokers.update(broker.copyWith(subscriptions: [broker.subscriptions.single.copyWith(history: const SubscriptionHistoryPolicy(enabled: false, retention: 3))]));
    messages.add(message('sensor/value', 'ignored', 2));
    await settle();

    expect(history.getHistory('sensor/value').single.payload, 'kept');
  });

  test('confirmed global maximum trims existing live buffers', () async {
    await state.write(SettingsKeys.maximumHistoryRetention, 100);
    await addBroker('broker', [subscription('all', '#', retention: 100)]);
    for (var index = 1; index <= 60; index++) {
      messages.add(message('sensor/value', '$index', index % 60));
    }
    await settle();

    expect(history.countBuffersAbove(50), 1);
    history.trimToMaximum(50);

    expect(history.getHistory('sensor/value'), hasLength(50));
    expect(history.getHistory('sensor/value').first.payload, '11');
  });

  test('clearTopics resets only the selected topic and its sequence', () async {
    await addBroker('broker', [subscription('all', '#')]);
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

  test('same topic on different brokers has independent policy', () async {
    await addBroker('first', [subscription('shared', 'sensor/value', enabled: false)]);
    await addBroker('second', [subscription('shared', 'sensor/value', retention: 2)], makeActive: false);

    messages.add(message('sensor/value', 'first', 1));
    await settle();
    expect(history.bufferCount, 0);

    await brokers.select('second');
    messages.add(message('sensor/value', 'second', 2));
    await settle();

    expect(history.getHistory('sensor/value').single.payload, 'second');
  });
}
