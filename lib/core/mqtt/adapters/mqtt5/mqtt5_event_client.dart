import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;
import 'package:mqtt5_client/mqtt5_server_client.dart' as mqtt5_server;

/// Exposes MQTT 5 protocol events from within the package client subclass.
class Mqtt5EventClient extends mqtt5_server.MqttServerClient {
  /// Creates a client using the default MQTT port.
  Mqtt5EventClient(super.server, super.clientIdentifier, {super.maxConnectionAttempts});

  /// Creates a client using an explicit [port].
  Mqtt5EventClient.withPort(super.server, super.clientIdentifier, super.port, {super.maxConnectionAttempts}) : super.withPort();

  /// Returns decoded protocol events without external protected-member access.
  Stream<mqtt5.MqttMessageAvailable> get protocolEvents => clientEventBus?.on<mqtt5.MqttMessageAvailable>() ?? const Stream<mqtt5.MqttMessageAvailable>.empty();
}
