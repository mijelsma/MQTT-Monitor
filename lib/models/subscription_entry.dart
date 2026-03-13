class SubscriptionEntry {
  const SubscriptionEntry({required this.topic, this.qos = 0, this.name});

  final String topic;
  final int qos;
  final String? name;

  SubscriptionEntry copyWith({String? topic, int? qos, String? name}) => SubscriptionEntry(topic: topic ?? this.topic, qos: qos ?? this.qos, name: name ?? this.name);

  factory SubscriptionEntry.fromJson(Map<String, dynamic> json) => SubscriptionEntry(topic: json['topic'] as String? ?? '', qos: json['qos'] as int? ?? 0, name: json['name'] as String?);

  Map<String, dynamic> toJson() => {'topic': topic, 'qos': qos, if (name != null) 'name': name};
}
