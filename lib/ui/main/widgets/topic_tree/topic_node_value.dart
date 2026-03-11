/// The current value stored at a leaf (or updated branch) node.
class TopicNodeValue {
  const TopicNodeValue({required this.payload, required this.seq});

  /// The latest decoded MQTT payload string.
  final String payload;

  /// Monotonically increasing counter — incremented on every value update.
  /// Used by row widgets to detect when a new value has arrived and trigger the
  /// pulse animation without doing an equality check on the payload string.
  final int seq;
}
