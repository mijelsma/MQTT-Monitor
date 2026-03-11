import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../state/app_state.dart';
import '../../state/keys/app_keys.dart';
import '../../state/keys/settings_keys.dart';
import '../../ui/settings/models/broker_entry.dart';
import 'models/connection_status.dart';
import 'models/mqtt_message.dart';

class MqttService {
  // Private constructor for singleton pattern
  MqttService._();

  // Singleton instance
  static final MqttService instance = MqttService._();

  // Reference to the app state manager for reading/writing state.
  final AppStateManager _state = AppStateManager.instance;

  // The currently active MQTT client, if any.
  MqttServerClient? _client;

  // Subscription to the client's updates stream.
  StreamSubscription? _updatesSubscription;

  // The ID of the currently connected broker, used to detect changes and avoid unnecessary reconnects.
  String? _currentBrokerId;

  // Bumped on every new connection attempt so stale async callbacks are ignored.
  int _sessionId = 0;

  // Broadcast stream of all received MQTT messages.
  final StreamController<TopicMessage> _messageStreamController = StreamController<TopicMessage>.broadcast();

  /// Stream of every MQTT message received across all subscriptions.
  Stream<TopicMessage> get messageStream => _messageStreamController.stream;

  // Message rate tracking
  Timer? _rateTimer;
  int _rateCounter = 0;
  int _messageCount = 0;
  int _currentRateIntervalMs = 0;

  /// Initialize the service by setting up listeners and syncing the initial broker connection.
  void initialize() {
    // Listen to state changes (app state) to react to broker config updates and connect/disconnect requests.
    _state.addListener(_onStateChanged);

    // Start the periodic rate timer.
    _startRateTimer();

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

  /// Start or restart the rate timer based on the current configured interval.
  void _startRateTimer() {
    final intervalMs = _state.read(SettingsKeys.rateIntervalMs);

    // Cancel any existing timer.
    _rateTimer?.cancel();

    // Update the current interval tracker.
    _currentRateIntervalMs = intervalMs;
    _rateCounter = 0;

    // The timer updates the message rate and count in state at the configured interval, and resets the counter.
    _rateTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      // Calculate the message rate based on the number of messages received since the last timer tick and the interval, then write it to state.
      final rate = (_rateCounter * 1000 / intervalMs).round();

      // Write the updated rate and total message count to state.
      _state.write(AppKeys.messageRate, rate);
      _state.write(AppKeys.messageCount, _messageCount);

      // Reset the counter for the next interval.
      _rateCounter = 0;
    });
  }

  /// when the app state changes, e.g. broker config is updated or user requests connect/disconnect, sync the MQTT connection accordingly.
  void _onStateChanged() {
    _syncBrokerConnection();
    _syncRateTimer();
  }

  /// Restart the rate timer if the configured interval has changed.
  void _syncRateTimer() {
    final intervalMs = _state.read(SettingsKeys.rateIntervalMs);
    if (intervalMs != _currentRateIntervalMs) _startRateTimer();
  }

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

    // Reset message counters for the new broker.
    _rateCounter = 0;
    _messageCount = 0;
    _state.write(AppKeys.messageCount, 0);
    _state.write(AppKeys.messageRate, 0);

    // Update application state to reflect that we are connecting.
    _state.write(AppKeys.connectionStatus, ConnectionStatus.connecting);
    _state.write(AppKeys.connectionError, null);

    // Use the broker's configured client ID.
    final clientId = broker.effectiveClientId;

    // Create a new MQTT client instance with the broker's host, port, and SSL settings.
    final client = MqttServerClient.withPort(broker.host, clientId, broker.port);
    client.secure = broker.useSSL;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.logging(on: false);

    // Disable certificate validation if configured.
    if (broker.useSSL && !broker.validateCertificates) {
      client.onBadCertificate = (_) => true;
    }

    // Wire up callbacks, each guarded by the session ID.
    client.onConnected = () {
      if (session == _sessionId) _onConnected();
    };

    // Register disconnection callbacks.
    client.onDisconnected = () {
      if (session == _sessionId) _onDisconnected();
    };

    // Register auto-reconnection callback.
    client.onAutoReconnected = () {
      if (session == _sessionId) _onAutoReconnected();
    };

    // Store client so other parts of the service can access it.
    _client = client;

    // Attempt to connect.
    try {
      await client.connect(broker.username, broker.password);
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
    } catch (e) {
      if (session != _sessionId) return;
      _state.write(AppKeys.connectionStatus, ConnectionStatus.error);
      _state.write(AppKeys.connectionError, e.toString());
      return;
    }

    // If we reach this point and the session is still valid, then the connection was successful.
    if (session != _sessionId) return;

    // Subscribe to the topics configured for this broker and listen for messages.
    for (final sub in broker.subscriptions) {
      final qos = switch (sub.qos) {
        1 => MqttQos.atLeastOnce,
        2 => MqttQos.exactlyOnce,
        _ => MqttQos.atMostOnce,
      };
      client.subscribe(sub.topic, qos);
    }

    // Listen for incoming messages on the updates stream.
    _updatesSubscription = client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      if (session != _sessionId) return;
      for (final msg in messages) {
        final payload = msg.payload as MqttPublishMessage;
        final bytes = payload.payload.message;
        _onMessageReceived(msg.topic, Uint8List.fromList(bytes));
      }
    });
  }

  /// Disconnect and clean up the current client
  void _disconnect() {
    ++_sessionId;
    _destroyClient();
    _rateCounter = 0;
    _messageCount = 0;
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _state.write(AppKeys.connectionError, null);
    _state.write(AppKeys.messageCount, 0);
    _state.write(AppKeys.messageRate, 0);
  }

  /// Clean up the current client
  void _destroyClient() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
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

  /// Callback for when a message is received.
  void _onMessageReceived(String topic, Uint8List payload) {
    final data = utf8.decode(payload, allowMalformed: true);
    _messageStreamController.add(TopicMessage(topic: topic, payload: data, receivedAt: DateTime.now()));

    // Update running counters (written to state by the rate timer).
    _rateCounter++;
    _messageCount++;
  }
}
