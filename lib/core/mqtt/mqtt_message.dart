import 'dart:convert';
import 'dart:typed_data';

/// A single received MQTT message: topic path, decoded text, and original bytes.
class MQTTMessage {
  const MQTTMessage({required this.topic, required this.payload, required this.receivedAt, this.payloadBytes, this.retain = false, this.qos = 0});

  /// Creates a message with both representations of the wire payload.
  factory MQTTMessage.fromPayloadBytes({required String topic, required List<int> payloadBytes, required DateTime receivedAt, bool retain = false, int qos = 0}) {
    final bytes = Uint8List.fromList(payloadBytes);
    return MQTTMessage(topic: topic, payload: utf8.decode(bytes, allowMalformed: true), payloadBytes: bytes, receivedAt: receivedAt, retain: retain, qos: qos);
  }

  final String topic;
  final String payload;

  /// An owned copy of the original MQTT wire payload.
  final List<int>? payloadBytes;
  final DateTime receivedAt;
  final bool retain;
  final int qos;
}
