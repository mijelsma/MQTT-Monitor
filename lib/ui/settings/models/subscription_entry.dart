class SubscriptionEntry {
  const SubscriptionEntry({required this.topic, this.qos = 0, this.name});

  final String topic;
  final int qos;
  final String? name;

  SubscriptionEntry copyWith({String? topic, int? qos, String? name}) => SubscriptionEntry(topic: topic ?? this.topic, qos: qos ?? this.qos, name: name ?? this.name);
}
