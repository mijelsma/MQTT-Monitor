/// The current value stored at a leaf (or updated branch) node.
class TopicNodeValueModel {
  const TopicNodeValueModel({required this.payload, required this.seq, required this.receivedAt, this.payloadBytes, this.retain = false, this.qos = 0});

  final String payload;

  /// Original MQTT payload bytes, retained alongside decoded [payload].
  final List<int>? payloadBytes;
  final int seq;
  final DateTime receivedAt;
  final bool retain;
  final int qos;
}
