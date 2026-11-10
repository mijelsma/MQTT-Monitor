/// Canonicalizes concrete MQTT topics the way the monitor topic tree does.
///
/// MQTT permits empty topic levels (for example `/sensor/value` or
/// `sensor/value/`). The monitor tree strips those empty levels, so every
/// projection keyed by a tree node path must use the same canonical form.
abstract final class TopicPath {
  /// Returns [topic] with empty levels removed.
  static String canonical(String topic) => topic.split('/').where((segment) => segment.isNotEmpty).join('/');
}
