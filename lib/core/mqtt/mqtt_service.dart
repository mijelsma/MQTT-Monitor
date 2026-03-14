import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../models/broker_entry.dart';
import '../state/app_state.dart';
import '../state/keys/app_keys.dart';
import '../state/keys/settings_keys.dart';
import 'connection_status.dart';
import 'mqtt_message.dart';

/// Service responsible for managing the MQTT connection and message flow.
class MqttService {
  // Constructor takes the app state manager to read settings and update connection status.
  MqttService(this._state);

  // Reference to the app state manager for reading settings and updating connection status.
  final AppStateManager _state;

  MqttServerClient? _client;
  StreamSubscription? _updatesSubscription;
  String? _currentBrokerId;
  int _sessionId = 0;

  // Stream controller for incoming MQTT messages.
  final _messages = StreamController<MQTTMessage>.broadcast();
  Stream<MQTTMessage> get messageStream => _messages.stream;

  // Timer and counters for calculating message rate.
  Timer? _rateTimer;
  int _rateCounter = 0;
  int _messageCount = 0;
  int _rateIntervalMs = 0;

  /// Sets up listeners and connects to the active broker.
  void initialize() {
    _state.addListener(_onStateChanged);
    _startRateTimer();
    _sync();
  }

  /// Disconnect from the current broker (user-initiated).
  void disconnect() {
    _state.write(AppKeys.disconnected, true);
    _teardown();
  }

  /// Reconnect to the active broker (user-initiated).
  void reconnect() {
    _state.write(AppKeys.disconnected, false);
    _currentBrokerId = null;
    _sync();
  }

  /// Reacts to app state changes (broker switched, settings changed, etc).
  void _onStateChanged() {
    _sync();

    final intervalMs = _state.read(SettingsKeys.rateIntervalMs);
    if (intervalMs != _rateIntervalMs) _startRateTimer();
  }

  /// Ensures the MQTT connection matches the current app state.
  void _sync() {
    final brokers = _state.read(SettingsKeys.brokers);
    final activeBrokerId = _state.read(AppKeys.activeBrokerId);

    final broker = brokers.isEmpty ? null : brokers.firstWhere((b) => b.id == activeBrokerId, orElse: () => brokers.first);

    if (broker?.id == _currentBrokerId) return;
    _currentBrokerId = broker?.id;

    if (broker == null) {
      _teardown();
      return;
    }

    if (_state.read(AppKeys.disconnected)) {
      _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
      _state.write(AppKeys.connectionError, null);
      return;
    }

    _connect(broker);
  }

  /// Connects to the given broker and subscribes to its topics.
  Future<void> _connect(BrokerEntry broker) async {
    final session = ++_sessionId;
    _cleanup();
    _resetCounters();

    _state.write(AppKeys.connectionStatus, ConnectionStatus.connecting);
    _state.write(AppKeys.connectionError, null);

    final client = MqttServerClient.withPort(broker.host, broker.effectiveClientId, broker.port);
    client.secure = broker.useSSL;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.logging(on: false);

    if (broker.useSSL && !broker.validateCertificates) {
      client.onBadCertificate = (_) => true;
    }

    client.onConnected = () {
      if (session == _sessionId) _onConnected();
    };
    client.onDisconnected = () {
      if (session == _sessionId) _onDisconnected();
    };
    client.onAutoReconnected = () {
      if (session == _sessionId) _onConnected();
    };

    _client = client;

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

    if (session != _sessionId) return;

    for (final sub in broker.subscriptions) {
      final qos = switch (sub.qos) {
        1 => MqttQos.atLeastOnce,
        2 => MqttQos.exactlyOnce,
        _ => MqttQos.atMostOnce,
      };
      client.subscribe(sub.topic, qos);
    }

    _updatesSubscription = client.updates?.listen((messages) {
      if (session != _sessionId) return;
      for (final msg in messages) {
        final publish = msg.payload as MqttPublishMessage;
        final bytes = publish.payload.message;
        final retain = publish.header?.retain ?? false;
        final qos = publish.header?.qos.index ?? 0;
        _onMessage(msg.topic, Uint8List.fromList(bytes), retain: retain, qos: qos);
      }
    });
  }

  /// Disconnect and reset everything.
  void _teardown() {
    ++_sessionId;
    _cleanup();
    _resetCounters();
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Cancel subscriptions and dispose the client.
  void _cleanup() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
  }

  /// Callback called when the client successfully connects.
  void _onConnected() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.connected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Callback called when the client disconnects.
  void _onDisconnected() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Handles an incoming message on the given topic.
  void _onMessage(String topic, Uint8List payload, {bool retain = false, int qos = 0}) {
    final data = utf8.decode(payload, allowMalformed: true);
    _messages.add(MQTTMessage(topic: topic, payload: data, receivedAt: DateTime.now(), retain: retain, qos: qos));
    _rateCounter++;
    _messageCount++;
  }

  /// Starts (or restarts) the message rate timer.
  void _startRateTimer() {
    final intervalMs = _state.read(SettingsKeys.rateIntervalMs);
    _rateTimer?.cancel();
    _rateIntervalMs = intervalMs;
    _rateCounter = 0;

    _rateTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _state.write(AppKeys.messageRate, (_rateCounter * 1000 / intervalMs).round());
      _state.write(AppKeys.messageCount, _messageCount);
      _rateCounter = 0;
    });
  }

  void _resetCounters() {
    _rateCounter = 0;
    _messageCount = 0;
    _state.write(AppKeys.messageCount, 0);
    _state.write(AppKeys.messageRate, 0);
  }
}
