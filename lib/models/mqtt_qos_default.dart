/// The user's choice of default QoS for new entries.
///
/// On top of the three MQTT QoS levels, [lastUsed] resolves to whatever
/// the user most recently picked in any QoS selector — so a new publish,
/// shortcut, or subscription automatically adopts the QoS the user has
/// been actively working with.
enum MqttQosDefault {
  /// QoS 0 — at most once. Fire-and-forget, no broker ack.
  qos0,

  /// QoS 1 — at least once. Broker acknowledges receipt.
  qos1,

  /// QoS 2 — exactly once. Strongest delivery guarantee, 4× overhead.
  qos2,

  /// Reuse the most recently picked QoS across the whole app.
  lastUsed;

  /// Compact text label rendered alongside the icon.
  String get shortLabel => switch (this) {
    MqttQosDefault.qos0 => 'QoS 0',
    MqttQosDefault.qos1 => 'QoS 1',
    MqttQosDefault.qos2 => 'QoS 2',
    MqttQosDefault.lastUsed => 'Last used',
  };

  /// Resolves this setting to an actual MQTT QoS value, falling back to
  /// [lastUsedValue] when the user picked [lastUsed].
  int resolve(int lastUsedValue) => switch (this) {
    MqttQosDefault.lastUsed => lastUsedValue,
    MqttQosDefault.qos0 => 0,
    MqttQosDefault.qos1 => 1,
    MqttQosDefault.qos2 => 2,
  };

  /// Maps a stored or last-used integer to the closest explicit option.
  static MqttQosDefault fromQos(int qos) => switch (qos) {
    0 => MqttQosDefault.qos0,
    1 => MqttQosDefault.qos1,
    _ => MqttQosDefault.qos2,
  };
}
