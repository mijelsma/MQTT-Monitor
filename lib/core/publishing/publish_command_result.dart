import '../mqtt/publish_result.dart';
import 'publish_command_failure.dart';

/// Domain result for validation, connectivity, and MQTT acknowledgement.
class PublishCommandResult {
  const PublishCommandResult.failure(this.failure, {this.detail}) : transportResult = null;
  const PublishCommandResult.sent(this.transportResult) : failure = null, detail = null;

  final PublishCommandFailure? failure;
  final String? detail;
  final PublishResult? transportResult;

  bool get wasSent => transportResult != null;
}
