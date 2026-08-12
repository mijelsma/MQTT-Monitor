import 'dart:convert';

/// Validates concrete MQTT topic names used for publishing.
abstract final class MqttTopicName {
  static const int _maximumUtf8Bytes = 65535;

  static String? validate(String topic) {
    if (topic.isEmpty) return 'A topic is required.';
    if (topic.contains('\u0000')) {
      return 'Topics cannot contain a null character.';
    }
    if (topic.contains('+') || topic.contains('#')) {
      return 'Publish topics cannot contain wildcards.';
    }
    if (utf8.encode(topic).length > _maximumUtf8Bytes) {
      return 'The topic is longer than MQTT allows.';
    }
    return null;
  }
}
