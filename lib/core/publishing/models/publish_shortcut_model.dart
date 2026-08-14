/// Immutable configuration for one broker-scoped publish shortcut.
class PublishShortcutModel {
  PublishShortcutModel({required this.id, required this.name, required this.topic, this.payload = '', this.payloadFormatIsJson = false, this.qos = 0, this.retain = false, required this.colorValue, List<String> brokerIds = const []}) : brokerIds = List.unmodifiable(brokerIds);

  final String id;
  final String name;
  final String topic;
  final String payload;
  final bool payloadFormatIsJson;
  final int qos;
  final bool retain;
  final int colorValue;
  final List<String> brokerIds;

  bool get isGlobal => brokerIds.isEmpty;

  PublishShortcutModel copyWith({String? name, String? topic, String? payload, bool? payloadFormatIsJson, int? qos, bool? retain, int? colorValue, List<String>? brokerIds}) {
    return PublishShortcutModel(id: id, name: name ?? this.name, topic: topic ?? this.topic, payload: payload ?? this.payload, payloadFormatIsJson: payloadFormatIsJson ?? this.payloadFormatIsJson, qos: qos ?? this.qos, retain: retain ?? this.retain, colorValue: colorValue ?? this.colorValue, brokerIds: brokerIds ?? this.brokerIds);
  }

  factory PublishShortcutModel.fromJson(Map<String, dynamic> json) {
    return PublishShortcutModel(id: json['id'] as String, name: json['name'] as String, topic: json['topic'] as String, payload: json['payload'] as String, payloadFormatIsJson: json['payloadFormatIsJson'] as bool, qos: json['qos'] as int, retain: json['retain'] as bool, colorValue: json['color'] as int, brokerIds: (json['brokerIds'] as List).cast<String>());
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'topic': topic, 'payload': payload, 'payloadFormatIsJson': payloadFormatIsJson, 'qos': qos, 'retain': retain, 'color': colorValue, 'brokerIds': brokerIds};
}
