/// A single received MQTT message: topic path + decoded string payload.
class MQTTMessage {
  const MQTTMessage({required this.topic, required this.payload, required this.receivedAt});

  final String topic;
  final String payload;
  final DateTime receivedAt;
}
