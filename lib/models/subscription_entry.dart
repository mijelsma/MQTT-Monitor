import 'dart:math';

import 'subscription_history_policy.dart';

class SubscriptionEntry {
  const SubscriptionEntry({required this.id, required this.topic, this.qos = 0, this.name, this.history = const SubscriptionHistoryPolicy()});

  /// Creates a new subscription with an opaque stable identity.
  factory SubscriptionEntry.create({required String topic, int qos = 0, String? name, SubscriptionHistoryPolicy history = const SubscriptionHistoryPolicy()}) {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return SubscriptionEntry(id: '$timestamp-$random', topic: topic, qos: qos, name: name, history: history);
  }

  final String id;
  final String topic;
  final int qos;
  final String? name;
  final SubscriptionHistoryPolicy history;

  SubscriptionEntry copyWith({String? topic, int? qos, String? name, SubscriptionHistoryPolicy? history, bool clearName = false}) {
    return SubscriptionEntry(id: id, topic: topic ?? this.topic, qos: qos ?? this.qos, name: clearName ? null : name ?? this.name, history: history ?? this.history);
  }

  factory SubscriptionEntry.fromJson(Map<String, dynamic> json) {
    return SubscriptionEntry(id: json['id'] as String, topic: json['topic'] as String, qos: json['qos'] as int, name: json['name'] as String?, history: SubscriptionHistoryPolicy.fromJson(Map<String, dynamic>.from(json['history'] as Map)));
  }

  Map<String, dynamic> toJson() => {'id': id, 'topic': topic, 'qos': qos, if (name != null) 'name': name, 'history': history.toJson()};
}
