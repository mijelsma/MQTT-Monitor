import 'package:flutter/material.dart';

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

  /// The icon shown in the QoS picker. The fixed levels render the QoS
  /// number in a rounded badge ([QosLevelIcon]); "last used" uses a
  /// history icon to signal "remember the previous pick".
  Widget get icon => switch (this) {
    MqttQosDefault.lastUsed => const Icon(Icons.history_rounded, size: 20),
    MqttQosDefault.qos0 => const QosLevelIcon(level: 0),
    MqttQosDefault.qos1 => const QosLevelIcon(level: 1),
    MqttQosDefault.qos2 => const QosLevelIcon(level: 2),
  };

  /// Compact text label rendered alongside the icon.
  String get shortLabel => switch (this) {
    MqttQosDefault.qos0 => 'Q0',
    MqttQosDefault.qos1 => 'Q1',
    MqttQosDefault.qos2 => 'Q2',
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

  /// Best-effort mapping from a stored integer (e.g. legacy data or a
  /// last-used value) to the closest explicit option.
  static MqttQosDefault fromQos(int qos) => switch (qos) {
    0 => MqttQosDefault.qos0,
    1 => MqttQosDefault.qos1,
    _ => MqttQosDefault.qos2,
  };
}

/// A small rounded-square badge that renders the QoS number. Material's
/// icon set ships numbered icons only from 1 onwards (`filter_1`, `looks_one`,
/// `looks_two`, ...), so a custom widget keeps the 0/1/2 series visually
/// consistent.
class QosLevelIcon extends StatelessWidget {
  const QosLevelIcon({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(width: 1.5, color: color),
      ),
      child: Text(
        '$level',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1, color: color),
      ),
    );
  }
}
