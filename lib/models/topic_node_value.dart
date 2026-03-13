/// The current value stored at a leaf (or updated branch) node.
class TopicNodeValue {
  const TopicNodeValue({required this.payload, required this.seq});

  final String payload;
  final int seq;
}
