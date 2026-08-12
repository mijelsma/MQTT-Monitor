import '../core/history/history_policy_rules.dart';

/// Persisted history configuration for one broker subscription.
class SubscriptionHistoryPolicy {
  const SubscriptionHistoryPolicy({this.enabled = HistoryPolicyRules.defaultEnabled, this.retention = HistoryPolicyRules.defaultRetention});

  final bool enabled;
  final int retention;

  /// Returns a copy with selected values changed.
  SubscriptionHistoryPolicy copyWith({bool? enabled, int? retention}) {
    return SubscriptionHistoryPolicy(enabled: enabled ?? this.enabled, retention: retention ?? this.retention);
  }

  /// Decodes the complete current policy representation.
  factory SubscriptionHistoryPolicy.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryPolicy(enabled: json['enabled'] as bool, retention: json['retention'] as int);
  }

  /// Encodes the complete current policy representation.
  Map<String, dynamic> toJson() => {'enabled': enabled, 'retention': retention};

  @override
  bool operator ==(Object other) {
    return other is SubscriptionHistoryPolicy && other.enabled == enabled && other.retention == retention;
  }

  @override
  int get hashCode => Object.hash(enabled, retention);
}
