/// One validated request to publish an MQTT message.
class PublishCommand {
  const PublishCommand({required this.topicTemplate, this.payload = '', this.payloadIsJson = false, this.qos = 0, this.retain = false});

  final String topicTemplate;
  final String payload;
  final bool payloadIsJson;
  final int qos;
  final bool retain;
}
