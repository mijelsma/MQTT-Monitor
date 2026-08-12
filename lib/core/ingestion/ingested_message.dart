import '../../models/topic_node_value.dart';

/// One broker-scoped message prepared once for every downstream projection.
class IngestedMessage {
  const IngestedMessage({required this.brokerId, required this.topic, required this.value});

  final String brokerId;
  final String topic;
  final TopicNodeValue value;
}
