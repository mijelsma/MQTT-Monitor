import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../state/app_state.dart';
import '../../state/keys/app_keys.dart';
import '../../state/keys/settings_keys.dart';
import '../../ui/settings/models/broker_entry.dart';
import 'models/connection_status.dart';

class MqttService {
  // Private constructor for singleton pattern
  MqttService._();

  // Singleton instance
  static final MqttService instance = MqttService._();

  // Reference to the app state manager for reading/writing state.
  final AppStateManager _state = AppStateManager.instance;

  // The currently active MQTT client, if any.
  MqttServerClient? _client;

  // The ID of the currently connected broker, used to detect changes and avoid unnecessary reconnects.
  String? _currentBrokerId;

  // Bumped on every new connection attempt so stale async callbacks are ignored.
  int _sessionId = 0;

  void initialize() {
    // Listen to state changes (app state) to react to broker config updates and connect/disconnect requests.
    _state.addListener(_onStateChanged);

    // Initial sync to connect to the broker if one is already configured.
    _syncBrokerConnection();
  }

  /// User initiated disconnect
  void disconnect() {
    _state.write(AppKeys.disconnected, true);
    _disconnect();
  }

  /// User initiated reconnect
  void reconnect() {
    // Clear the disconnected flag and re-sync to connect to the current broker.
    _state.write(AppKeys.disconnected, false);

    // Without this reset, _syncBroker's deduplication guard would see the same broker ID and so the reconnect would be silently ignored.
    _currentBrokerId = null;

    // Sync to connect to the broker.
    _syncBrokerConnection();
  }

  /// when the app state changes, e.g. broker config is updated or user requests connect/disconnect, sync the MQTT connection accordingly.
  void _onStateChanged() => _syncBrokerConnection();

  /// Sync the MQTT connection based on the current app state.
  /// This is called on every app state change.
  void _syncBrokerConnection() {
    final brokers = _state.read(SettingsKeys.brokers);
    final activeBrokerId = _state.read(AppKeys.activeBrokerId);

    // Resolve the active broker based on the stored activeBrokerId and available brokers.
    final broker = brokers.isEmpty ? null : brokers.firstWhere((b) => b.id == activeBrokerId, orElse: () => brokers.first);

    // Deduplication guard: _syncBrokerConnection is called on every state write (via _onStateChanged), including writes made
    // inside _connect itself (e.g. connectionStatus = connecting). Without this check those internal writes would re-trigger _connect in an infinite loop.
    if (broker?.id == _currentBrokerId) return;

    // Update before connecting/disconnecting so internal state writes triggered by those
    // calls are caught by the guard above and don't cause a reconnect loop.
    _currentBrokerId = broker?.id;

    // If there's no broker to connect to, or the user has explicitly chosen to disconnect, then disconnect. Otherwise, connect to the new broker.
    if (broker == null) {
      _disconnect();
      return;
    }

    // Do not connect if we want to stay disconnected
    if (_state.read(AppKeys.disconnected)) {
      _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
      _state.write(AppKeys.connectionError, null);
      return;
    }

    // Connect to the new broker.
    _connect(broker);
  }

  /// Connect to the given broker
  Future<void> _connect(BrokerEntry broker) async {
    // Increment the session ID so callbacks from any previous connection become invalid. All callbacks check this value before acting.
    final session = ++_sessionId;

    // Destroy any previous MQTT client instance.
    _destroyClient();

    // Update application state to reflect that we are connecting.
    _state.write(AppKeys.connectionStatus, ConnectionStatus.connecting);
    _state.write(AppKeys.connectionError, null);

    // TODO: Make clientId configurable in broker settings.
    const clientId = 'mqtt_monitor';

    final client = MqttServerClient.withPort(broker.host, clientId, broker.port)
      ..logging(on: false)
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..secure = broker.useSSL;

    // Configure security context for SSL/TLS if needed.
    if (broker.useSSL) {
      // Use the platform's default certificate store.
      client.securityContext = SecurityContext.defaultContext;

      // Allow self-signed certificates when validation is disabled.
      // Useful for local brokers or internal environments.
      if (!broker.validateCertificates) {
        client.onBadCertificate = (_) => true;
      }
    }

    // Each callback checks the session ID to ensure it belongs to the
    // currently active client instance.
    client.onConnected = () {
      if (session == _sessionId) _onConnected();
    };

    client.onDisconnected = () {
      if (session == _sessionId) _onDisconnected();
    };

    client.onAutoReconnected = () {
      if (session == _sessionId) _onAutoReconnected();
    };

    // Set up the connection message with client ID and clean session.
    final connMsg = MqttConnectMessage().withClientIdentifier(clientId).withWillQos(MqttQos.atMostOnce).startClean();

    // Apply authentication if provided.
    if (broker.username?.isNotEmpty == true) {
      connMsg.authenticateAs(broker.username!, broker.password ?? '');
    }

    client.connectionMessage = connMsg;

    // Store client so other parts of the service can access it.
    _client = client;

    // Attempt to connect.
    try {
      await client.connect();
    } on HandshakeException {
      if (session != _sessionId) return;
      _state.write(AppKeys.connectionStatus, ConnectionStatus.errorTlsHandshake);
      _state.write(AppKeys.connectionError, null);
      return;
    } on SocketException catch (e) {
      if (session != _sessionId) return;
      final code = e.osError?.errorCode;
      final status = switch (code) {
        1 => ConnectionStatus.errorNotPermitted,
        8 => ConnectionStatus.errorHostNotFound,
        61 || 111 => ConnectionStatus.errorRefused,
        _ => ConnectionStatus.error,
      };
      _state.write(AppKeys.connectionStatus, status);
      _state.write(AppKeys.connectionError, null);
      return;
    } on NoConnectionException {
      if (session != _sessionId) return;
      _state.write(AppKeys.connectionStatus, ConnectionStatus.errorRefused);
      _state.write(AppKeys.connectionError, null);
      return;
    } catch (e) {
      if (session != _sessionId) return;
      _state.write(AppKeys.connectionStatus, ConnectionStatus.error);
      _state.write(AppKeys.connectionError, e.toString());
      return;
    }

    // If we reach this point and the session is still valid, then the connection was successful.
    if (session != _sessionId) return;

    // Update state to connected.
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      _state.write(AppKeys.connectionStatus, ConnectionStatus.error);
      _state.write(AppKeys.connectionError, 'state: ${client.connectionStatus?.state}');
      return;
    }

    // Subscribe to the topics configured for this broker.
    for (final sub in broker.subscriptions) {
      // Convert stored QoS index to MQTT QoS enum.
      final qos = MqttQos.values.firstWhere((q) => q.index == sub.qos, orElse: () => MqttQos.atMostOnce);
      client.subscribe(sub.topic, qos);
    }

    // Listen for incoming messages and route them to the handler.
    client.updates?.listen((messages) {
      // Again guard against callbacks from a stale session.
      if (session != _sessionId) {
        return;
      }

      // Handle the received messages.
      _onMessageReceived(messages);
    });
  }

  /// Disconnect and clean up the current client
  void _disconnect() {
    ++_sessionId;
    _destroyClient();
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Clean up the current client
  void _destroyClient() {
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
  }

  /// Callback for when a connection is successfully established.
  void _onConnected() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.connected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Callback for when the connection is lost.
  void _onDisconnected() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Callback for when an auto-reconnect succeeds.
  void _onAutoReconnected() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.connected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Callback for when messages are received.
  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final payload = msg.payload;
      if (payload is MqttPublishMessage) {
        final data = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
        print('[MQTT] ${msg.topic}: $data');
      }
    }
  }
}
