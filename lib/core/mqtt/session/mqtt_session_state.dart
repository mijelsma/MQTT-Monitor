import '../../../core/mqtt/models/mqtt_protocol_version_model.dart';
import '../connection_status.dart';

/// Represents the complete observable state of the active MQTT session.
class MqttSessionState {
  /// Creates an immutable session state snapshot.
  const MqttSessionState({this.status = ConnectionStatus.disconnected, this.error, this.errorDetail, this.messageCount = 0, this.messageRate = 0, this.activeProtocol});

  final ConnectionStatus status;
  final String? error;
  final String? errorDetail;
  final int messageCount;
  final int messageRate;
  final MqttProtocolVersionModel? activeProtocol;

  /// Returns whether the active protocol client can publish messages.
  bool get isConnected => status == ConnectionStatus.connected;

  /// Compares all observable session values.
  @override
  bool operator ==(Object other) {
    return other is MqttSessionState && other.status == status && other.error == error && other.errorDetail == errorDetail && other.messageCount == messageCount && other.messageRate == messageRate && other.activeProtocol == activeProtocol;
  }

  /// Produces a stable hash for the complete state snapshot.
  @override
  int get hashCode => Object.hash(status, error, errorDetail, messageCount, messageRate, activeProtocol);
}
