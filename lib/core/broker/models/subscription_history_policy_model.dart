import '../../history/history_policy_rules.dart';

/// Persisted history configuration for one broker subscription.
class SubscriptionHistoryPolicyModel {
  const SubscriptionHistoryPolicyModel({this.enabled = HistoryPolicyRules.defaultEnabled, this.retention = HistoryPolicyRules.defaultRetention});

  final bool enabled;
  final int retention;

  /// Returns a copy with selected values changed.
  SubscriptionHistoryPolicyModel copyWith({bool? enabled, int? retention}) {
    return SubscriptionHistoryPolicyModel(enabled: enabled ?? this.enabled, retention: retention ?? this.retention);
  }

  /// Decodes the complete current policy representation.
  factory SubscriptionHistoryPolicyModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryPolicyModel(enabled: json['enabled'] as bool, retention: json['retention'] as int);
  }

  /// Encodes the complete current policy representation.
  Map<String, dynamic> toJson() => {'enabled': enabled, 'retention': retention};

  @override
  bool operator ==(Object other) {
    return other is SubscriptionHistoryPolicyModel && other.enabled == enabled && other.retention == retention;
  }

  @override
  int get hashCode => Object.hash(enabled, retention);
}
