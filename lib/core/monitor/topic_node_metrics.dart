/// Incremental concrete-topic and message totals for one topic subtree.
class TopicNodeMetrics {
  const TopicNodeMetrics({this.topicCount = 0, this.messageCount = 0});

  final int topicCount;
  final int messageCount;

  TopicNodeMetrics add({int topics = 0, int messages = 0}) => TopicNodeMetrics(topicCount: topicCount + topics, messageCount: messageCount + messages);

  TopicNodeMetrics subtract(TopicNodeMetrics other) => TopicNodeMetrics(topicCount: topicCount - other.topicCount, messageCount: messageCount - other.messageCount);

  @override
  bool operator ==(Object other) => other is TopicNodeMetrics && other.topicCount == topicCount && other.messageCount == messageCount;

  @override
  int get hashCode => Object.hash(topicCount, messageCount);
}
