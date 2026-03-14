/// A single received MQTT message: topic path + decoded string payload.
class MQTTMessage {
  const MQTTMessage({required this.topic, required this.payload, required this.receivedAt, this.retain = false, this.qos = 0});

  final String topic;
  final String payload;
  final DateTime receivedAt;
  final bool retain;
  final int qos;
}
