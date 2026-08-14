import 'connection_status.dart';

/// Reports a safe connection failure from a protocol adapter.
class MqttConnectionFailure implements Exception {
  /// Creates a failure with user-facing text and optional technical detail.
  const MqttConnectionFailure(this.status, this.message, {this.detail});

  final ConnectionStatus status;
  final String message;
  final String? detail;

  /// Returns the user-facing failure message.
  @override
  String toString() => message;
}
