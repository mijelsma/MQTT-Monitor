import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/history_policy_resolver.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_history_policy_model.dart';

void main() {
  const resolver = HistoryPolicyResolver();

  SubscriptionEntryModel subscription(String id, String topic, {bool enabled = true, int retention = 10}) => SubscriptionEntryModel(
    id: id,
    topic: topic,
    history: SubscriptionHistoryPolicyModel(enabled: enabled, retention: retention),
  );

  test('reports unmatched, disabled, and enabled states separately', () {
    final subscriptions = [subscription('disabled', 'disabled/#', enabled: false), subscription('enabled', 'enabled/#', retention: 25)];

    final unmatched = resolver.resolve('other/value', subscriptions, maximumRetention: 500);
    final disabled = resolver.resolve('disabled/value', subscriptions, maximumRetention: 500);
    final enabled = resolver.resolve('enabled/value', subscriptions, maximumRetention: 500);

    expect(unmatched.matchesSubscription, isFalse);
    expect(disabled.matchesSubscription, isTrue);
    expect(disabled.enabled, isFalse);
    expect(enabled.enabled, isTrue);
    expect(enabled.retention, 25);
  });

  test('largest enabled overlap wins and the global maximum is enforced', () {
    final resolution = resolver.resolve('sensors/device/value', [subscription('small', 'sensors/#', retention: 20), subscription('large', 'sensors/+/value', retention: 100), subscription('off', 'sensors/device/#', enabled: false, retention: 200)], maximumRetention: 50);

    expect(resolution.enabled, isTrue);
    expect(resolution.retention, 50);
  });
}
