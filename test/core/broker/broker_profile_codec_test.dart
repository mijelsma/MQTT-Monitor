import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_profile_codec.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_history_policy_model.dart';

void main() {
  const codec = BrokerProfileCodec();

  test('stable subscription ID and history policy round-trip', () {
    const broker = BrokerEntryModel(
      id: 'broker',
      name: 'Broker',
      host: 'broker.invalid',
      subscriptions: [SubscriptionEntryModel(id: 'subscription', topic: 'devices/+/state', qos: 2, history: SubscriptionHistoryPolicyModel(enabled: false, retention: 250))],
    );

    final decoded = codec.decode(codec.encode(const [broker]));

    expect(decoded.single.subscriptions.single.id, 'subscription');
    expect(decoded.single.subscriptions.single.history, const SubscriptionHistoryPolicyModel(enabled: false, retention: 250));
  });

  test('pre-policy development subscriptions are rejected', () {
    const raw = '[{"id":"broker","name":"Broker","host":"host","subscriptions":[{"topic":"#","qos":1}]}]';

    expect(() => codec.decode(raw), throwsFormatException);
  });

  test('duplicate IDs and filters are rejected inside a broker', () {
    const duplicateId = '[{"id":"broker","name":"Broker","host":"host","subscriptions":[{"id":"same","topic":"one/#","qos":1,"history":{"enabled":true,"retention":10}},{"id":"same","topic":"two/#","qos":1,"history":{"enabled":true,"retention":10}}]}]';
    const duplicateFilter = '[{"id":"broker","name":"Broker","host":"host","subscriptions":[{"id":"one","topic":"same/#","qos":1,"history":{"enabled":true,"retention":10}},{"id":"two","topic":"same/#","qos":1,"history":{"enabled":true,"retention":10}}]}]';

    expect(() => codec.decode(duplicateId), throwsFormatException);
    expect(() => codec.decode(duplicateFilter), throwsFormatException);
  });

  test('invalid wildcard grammar and retention are rejected', () {
    const badFilter = '[{"id":"broker","name":"Broker","host":"host","subscriptions":[{"id":"sub","topic":"bad/#/filter","qos":1,"history":{"enabled":true,"retention":10}}]}]';
    const badRetention = '[{"id":"broker","name":"Broker","host":"host","subscriptions":[{"id":"sub","topic":"#","qos":1,"history":{"enabled":true,"retention":5001}}]}]';

    expect(() => codec.decode(badFilter), throwsFormatException);
    expect(() => codec.decode(badRetention), throwsFormatException);
  });
}
