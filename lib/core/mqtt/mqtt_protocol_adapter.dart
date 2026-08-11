import '../../models/broker_entry.dart';
import '../../models/mqtt_protocol_version.dart';
import 'mqtt_message.dart';
import 'mqtt_protocol_event.dart';
import 'publish_result.dart';

/// Creates the protocol adapter required by [broker].
typedef MqttProtocolAdapterFactory = MqttProtocolAdapter Function(BrokerEntry broker);

/// Isolates one MQTT package and one live protocol-client lifecycle.
abstract interface class MqttProtocolAdapter {
  /// Returns the MQTT protocol implemented by this adapter.
  MqttProtocolVersion get protocolVersion;

  /// Returns lifecycle and diagnostic events from the protocol client.
  Stream<MqttProtocolEvent> get events;

  /// Returns decoded application messages received from subscribed topics.
  Stream<MQTTMessage> get messages;

  /// Returns whether the underlying client is currently connected.
  bool get isConnected;

  /// Connects and installs the configured broker subscriptions.
  Future<void> connect();

  /// Publishes a payload or returns `null` when the client is disconnected.
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false});

  /// Subscribes to [topic] when connected.
  bool subscribe(String topic, {int qos = 0});

  /// Unsubscribes from [topic] when connected.
  bool unsubscribe(String topic);

  /// Disconnects and releases all streams, timers, and pending publishes.
  Future<void> dispose();
}
