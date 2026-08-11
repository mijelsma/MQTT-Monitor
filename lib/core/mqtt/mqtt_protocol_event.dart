import 'connection_status.dart';

/// Identifies a lifecycle or diagnostic event emitted by a protocol adapter.
enum MqttProtocolEventType { connected, reconnecting, disconnected, notice, failure }

/// Carries protocol lifecycle changes without exposing package packet types.
class MqttProtocolEvent {
  /// Creates a protocol event with optional diagnostic information.
  const MqttProtocolEvent(this.type, {this.status, this.message, this.detail});

  final MqttProtocolEventType type;
  final ConnectionStatus? status;
  final String? message;
  final String? detail;

  /// Creates a successful connection event.
  const MqttProtocolEvent.connected() : this(MqttProtocolEventType.connected);

  /// Creates an automatic reconnect event.
  const MqttProtocolEvent.reconnecting() : this(MqttProtocolEventType.reconnecting);

  /// Creates a broker-driven disconnection event.
  const MqttProtocolEvent.disconnected({String? message, String? detail}) : this(MqttProtocolEventType.disconnected, message: message, detail: detail);

  /// Creates a non-terminal protocol notice.
  const MqttProtocolEvent.notice(String message, {String? detail}) : this(MqttProtocolEventType.notice, message: message, detail: detail);

  /// Creates a terminal connection failure event.
  const MqttProtocolEvent.failure(ConnectionStatus status, String message, {String? detail}) : this(MqttProtocolEventType.failure, status: status, message: message, detail: detail);
}
