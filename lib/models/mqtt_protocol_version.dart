/// MQTT wire-protocol version used by a broker profile.
enum MqttProtocolVersion {
  v311,
  v5;

  String get displayName => switch (this) {
    v311 => 'MQTT 3.1.1',
    v5 => 'MQTT 5.0',
  };
}
