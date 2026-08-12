import '../../models/subscription_entry.dart';
import '../mqtt/mqtt_topic_filter.dart';
import 'history_policy_resolution.dart';
import 'history_policy_rules.dart';

/// Resolves overlapping subscription policies for concrete MQTT topics.
class HistoryPolicyResolver {
  const HistoryPolicyResolver();

  /// Uses the greatest enabled retention among all matching filters.
  HistoryPolicyResolution resolve(String topic, Iterable<SubscriptionEntry> subscriptions, {required int maximumRetention}) {
    HistoryPolicyRules.validateMaximum(maximumRetention);
    var matched = false;
    var retention = 0;
    for (final subscription in subscriptions) {
      if (!MqttTopicFilter.matches(subscription.topic, topic)) continue;
      matched = true;
      final policy = subscription.history;
      if (policy.enabled && policy.retention > retention) {
        retention = policy.retention;
      }
    }
    if (retention > 0) {
      return HistoryPolicyResolution.enabled(retention.clamp(HistoryPolicyRules.minimumRetention, maximumRetention));
    }
    return matched ? const HistoryPolicyResolution.disabled() : const HistoryPolicyResolution.unmatched();
  }
}
