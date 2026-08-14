import '../mqtt/publish_result.dart';

/// Minimal transport boundary required by publishing commands.
abstract interface class PublishTransport {
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false});
}
