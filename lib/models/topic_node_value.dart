/// The current value stored at a leaf (or updated branch) node.
class TopicNodeValue {
  const TopicNodeValue({required this.payload, required this.seq, required this.receivedAt, this.retain = false, this.qos = 0});

  final String payload;
  final int seq;
  final DateTime receivedAt;
  final bool retain;
  final int qos;
}
