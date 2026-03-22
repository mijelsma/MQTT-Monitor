import 'dart:ui';

/// A pre-configured publish shortcut with a topic, QoS, retain flag, and color.
///
/// Shortcuts can be global (available across all brokers) or scoped to
/// specific brokers, similar to environment variables.
class PublishShortcut {
  PublishShortcut({required this.name, required this.topic, this.payload = '', this.payloadFormatIsJson = false, this.qos = 0, this.retain = false, required this.color, this.brokerIds = const []});

  final String name;
  final String topic;
  final String payload;
  final bool payloadFormatIsJson;
  final int qos;
  final bool retain;
  final int color;

  /// When empty the shortcut is global (available for any broker).
  /// When set it is scoped to those specific brokers.
  final List<String> brokerIds;

  bool get isGlobal => brokerIds.isEmpty;

  Color get displayColor => Color(color);

  PublishShortcut copyWith({String? name, String? topic, String? payload, bool? payloadFormatIsJson, int? qos, bool? retain, int? color, List<String>? brokerIds}) {
    return PublishShortcut(name: name ?? this.name, topic: topic ?? this.topic, payload: payload ?? this.payload, payloadFormatIsJson: payloadFormatIsJson ?? this.payloadFormatIsJson, qos: qos ?? this.qos, retain: retain ?? this.retain, color: color ?? this.color, brokerIds: brokerIds ?? this.brokerIds);
  }

  factory PublishShortcut.fromJson(Map<String, dynamic> json) {
    return PublishShortcut(
      name: json['name'] as String,
      topic: json['topic'] as String,
      payload: json['payload'] as String? ?? '',
      payloadFormatIsJson: json['payloadFormatIsJson'] as bool? ?? false,
      qos: json['qos'] as int? ?? 0,
      retain: json['retain'] as bool? ?? false,
      color: json['color'] as int,
      brokerIds: (json['brokerIds'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'topic': topic, 'payload': payload, 'payloadFormatIsJson': payloadFormatIsJson, 'qos': qos, 'retain': retain, 'color': color, 'brokerIds': brokerIds};
}
