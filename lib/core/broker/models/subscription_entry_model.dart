import 'dart:math';

import 'subscription_history_policy_model.dart';

class SubscriptionEntryModel {
  const SubscriptionEntryModel({required this.id, required this.topic, this.qos = 0, this.name, this.history = const SubscriptionHistoryPolicyModel()});

  /// Creates a new subscription with an opaque stable identity.
  factory SubscriptionEntryModel.create({required String topic, int qos = 0, String? name, SubscriptionHistoryPolicyModel history = const SubscriptionHistoryPolicyModel()}) {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return SubscriptionEntryModel(id: '$timestamp-$random', topic: topic, qos: qos, name: name, history: history);
  }

  final String id;
  final String topic;
  final int qos;
  final String? name;
  final SubscriptionHistoryPolicyModel history;

  SubscriptionEntryModel copyWith({String? topic, int? qos, String? name, SubscriptionHistoryPolicyModel? history, bool clearName = false}) {
    return SubscriptionEntryModel(id: id, topic: topic ?? this.topic, qos: qos ?? this.qos, name: clearName ? null : name ?? this.name, history: history ?? this.history);
  }

  factory SubscriptionEntryModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionEntryModel(id: json['id'] as String, topic: json['topic'] as String, qos: json['qos'] as int, name: json['name'] as String?, history: SubscriptionHistoryPolicyModel.fromJson(Map<String, dynamic>.from(json['history'] as Map)));
  }

  Map<String, dynamic> toJson() => {'id': id, 'topic': topic, 'qos': qos, if (name != null) 'name': name, 'history': history.toJson()};
}
