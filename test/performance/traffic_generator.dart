import 'dart:convert';

import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';

/// Payload shapes used by the repeatable performance-acceptance scenarios.
enum TrafficPayload { smallText, smallJson, malformedUtf8, json10Kb, json1Mb }

/// Creates deterministic MQTT traffic without broker or wall-clock variance.
class TrafficGenerator {
  TrafficGenerator({this.topicCount = 100, DateTime? startedAt}) : assert(topicCount > 0), startedAt = startedAt ?? DateTime.utc(2026, 1, 1);

  final int topicCount;
  final DateTime startedAt;

  static final String _malformedUtf8 = utf8.decode(const [0xff, 0xfe, 0x61], allowMalformed: true);
  static final String _json10Kb = _sizedJson(10 * 1024);
  static final String _json1Mb = _sizedJson(1024 * 1024);

  /// Creates one message at [sequence], with timestamps representing [messagesPerSecond].
  MQTTMessage message(int sequence, {TrafficPayload payload = TrafficPayload.smallText, int messagesPerSecond = 1000}) {
    assert(sequence >= 0);
    assert(messagesPerSecond > 0);
    return MQTTMessage(
      topic: 'devices/device-${sequence % topicCount}/value',
      payload: payloadFor(payload, sequence),
      receivedAt: startedAt.add(Duration(microseconds: sequence * 1000000 ~/ messagesPerSecond)),
      qos: sequence % 3,
      retain: sequence.isEven,
    );
  }

  /// Creates a message whose concrete topic has not appeared earlier in the sequence.
  MQTTMessage uniqueTopicMessage(int sequence, {String root = 'iot', TrafficPayload payload = TrafficPayload.smallText, int messagesPerSecond = 1000}) {
    assert(sequence >= 0);
    assert(messagesPerSecond > 0);
    return MQTTMessage(
      topic: '$root/device-$sequence/value',
      payload: payloadFor(payload, sequence),
      receivedAt: startedAt.add(Duration(microseconds: sequence * 1000000 ~/ messagesPerSecond)),
      qos: 0,
    );
  }

  /// Creates [count] messages on distinct concrete topics.
  Iterable<MQTTMessage> uniqueTopicMessages(int count, {String root = 'iot', TrafficPayload payload = TrafficPayload.smallText, int messagesPerSecond = 1000, int startSequence = 0}) sync* {
    for (var offset = 0; offset < count; offset++) {
      yield uniqueTopicMessage(startSequence + offset, root: root, payload: payload, messagesPerSecond: messagesPerSecond);
    }
  }

  /// Creates [count] deterministic messages.
  Iterable<MQTTMessage> messages(int count, {TrafficPayload payload = TrafficPayload.smallText, int messagesPerSecond = 1000, int startSequence = 0}) sync* {
    for (var offset = 0; offset < count; offset++) {
      yield message(startSequence + offset, payload: payload, messagesPerSecond: messagesPerSecond);
    }
  }

  /// Returns a cached payload for large fixtures so generator allocation is not timed.
  String payloadFor(TrafficPayload payload, int sequence) => switch (payload) {
    TrafficPayload.smallText => '$sequence',
    TrafficPayload.smallJson => '{"metrics":{"value":$sequence,"secondary":${sequence + 1}},"status":"ok"}',
    TrafficPayload.malformedUtf8 => 'invalid-$_malformedUtf8-$sequence',
    TrafficPayload.json10Kb => _json10Kb,
    TrafficPayload.json1Mb => _json1Mb,
  };

  static String _sizedJson(int targetBytes) {
    const prefix = '{"metrics":{"value":42,"secondary":43},"padding":"';
    const suffix = '"}';
    return '$prefix${List.filled(targetBytes - prefix.length - suffix.length, 'x').join()}$suffix';
  }
}
