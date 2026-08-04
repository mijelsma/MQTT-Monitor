import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt3_server;
import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;
import 'package:mqtt5_client/mqtt5_server_client.dart' as mqtt5_server;

import '../../models/broker_entry.dart';
import '../../models/mqtt_protocol_version.dart';
import '../../models/startup_connection.dart';
import '../state/app_state.dart';
import '../state/keys/app_keys.dart';
import '../state/keys/settings_keys.dart';
import 'client_certificate_service.dart';
import 'connection_status.dart';
import 'mqtt_message.dart';
import 'mqtt_reason.dart';

typedef Mqtt3ClientFactory =
    mqtt3_server.MqttServerClient Function(BrokerEntry broker);
typedef Mqtt5ClientFactory =
    mqtt5_server.MqttServerClient Function(BrokerEntry broker);

/// Service responsible for managing the MQTT connection and message flow.
class MqttService {
  // Constructor takes the app state manager to read settings and update connection status.
  MqttService(
    this._state, {
    ClientCertificateService? certificateService,
    Mqtt3ClientFactory? mqtt3ClientFactory,
    Mqtt5ClientFactory? mqtt5ClientFactory,
  }) : _certificateService = certificateService ?? ClientCertificateService(),
       _mqtt3ClientFactory =
           mqtt3ClientFactory ??
           ((broker) => mqtt3_server.MqttServerClient.withPort(
             broker.host,
             broker.effectiveClientId,
             broker.port,
           )),
       _mqtt5ClientFactory =
           mqtt5ClientFactory ??
           ((broker) => mqtt5_server.MqttServerClient.withPort(
             broker.host,
             broker.effectiveClientId,
             broker.port,
           ));

  // Reference to the app state manager for reading settings and updating connection status.
  final AppStateManager _state;
  final ClientCertificateService _certificateService;
  final Mqtt3ClientFactory _mqtt3ClientFactory;
  final Mqtt5ClientFactory _mqtt5ClientFactory;

  mqtt3_server.MqttServerClient? _client3;
  mqtt5_server.MqttServerClient? _client5;
  StreamSubscription? _updatesSubscription;
  StreamSubscription? _protocolSubscription;
  MqttProtocolVersion? _activeProtocol;
  String? _currentBrokerId;
  String? _currentBrokerSignature;
  int _sessionId = 0;
  bool _isFirstSync = true;

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

  /// Publishes a message to the given topic.
  /// Returns `true` if the message was sent, `false` if the client is not connected.
  bool publish(
    String topic,
    String payload, {
    int qos = 0,
    bool retain = false,
  }) {
    if (_activeProtocol == MqttProtocolVersion.v5) {
      final client = _client5;
      if (client == null ||
          client.connectionStatus?.state !=
              mqtt5.MqttConnectionState.connected) {
        return false;
      }
      final builder = mqtt5.MqttPayloadBuilder()..addString(payload);
      client.publishMessage(
        topic,
        _mqtt5Qos(qos),
        builder.payload!,
        retain: retain,
      );
      return true;
    }

    final client = _client3;
    if (client == null ||
        client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      return false;
    }
    final builder = mqtt3.MqttClientPayloadBuilder()..addString(payload);
    client.publishMessage(
      topic,
      _mqtt3Qos(qos),
      builder.payload!,
      retain: retain,
    );
    return true;
  }

  bool subscribe(String topic, {int qos = 0}) {
    if (_activeProtocol == MqttProtocolVersion.v5) {
      final client = _client5;
      if (client == null ||
          client.connectionStatus?.state !=
              mqtt5.MqttConnectionState.connected) {
        return false;
      }
      client.subscribe(topic, _mqtt5Qos(qos));
      return true;
    }
    final client = _client3;
    if (client == null ||
        client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      return false;
    }
    client.subscribe(topic, _mqtt3Qos(qos));
    return true;
  }

  bool unsubscribe(String topic) {
    if (_activeProtocol == MqttProtocolVersion.v5) {
      final client = _client5;
      if (client == null ||
          client.connectionStatus?.state !=
              mqtt5.MqttConnectionState.connected) {
        return false;
      }
      client.unsubscribeStringTopic(topic);
      return true;
    }
    final client = _client3;
    if (client == null ||
        client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      return false;
    }
    client.unsubscribe(topic);
    return true;
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
    _currentBrokerSignature = null;
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

    final broker = brokers.isEmpty
        ? null
        : brokers.firstWhere(
            (b) => b.id == activeBrokerId,
            orElse: () => brokers.first,
          );

    final brokerSignature = broker == null ? null : jsonEncode(broker.toJson());
    if (broker?.id == _currentBrokerId &&
        brokerSignature == _currentBrokerSignature) {
      return;
    }
    _currentBrokerId = broker?.id;
    _currentBrokerSignature = brokerSignature;

    if (broker == null) {
      _teardown();
      return;
    }

    // On the very first sync (app startup), apply the startup connection preference.
    if (_isFirstSync) {
      _isFirstSync = false;
      final mode = _state.read(SettingsKeys.startupConnection);
      switch (mode) {
        case StartupConnection.alwaysConnect:
          _state.write(AppKeys.disconnected, false);
        case StartupConnection.stayDisconnected:
          _state.write(AppKeys.disconnected, true);
        case StartupConnection.lastStatus:
          break; // keep existing disconnected flag
      }
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

    _activeProtocol = broker.protocolVersion;
    if (broker.protocolVersion == MqttProtocolVersion.v5) {
      await _connectV5(broker, session);
    } else {
      await _connectV311(broker, session);
    }
  }

  Future<void> _connectV311(BrokerEntry broker, int session) async {
    final client = _mqtt3ClientFactory(broker);
    client.secure = broker.useSSL || !broker.clientCertificates.isEmpty;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.logging(on: false);

    if (!await _configureTlsContext(client, broker, session)) return;

    if (broker.useSSL && !broker.validateCertificates) {
      client.onBadCertificate = (_) => true;
    }

    client.onConnected = () {
      if (session == _sessionId) _onConnected();
    };
    client.onDisconnected = () {
      if (session == _sessionId) _onDisconnected311();
    };
    client.onAutoReconnect = () {
      if (session == _sessionId) _onDisconnected311();
    };
    client.onAutoReconnected = () {
      if (session == _sessionId) _onConnected();
    };

    _client3 = client;

    try {
      await client.connect(broker.username, broker.password);
    } on HandshakeException {
      if (session != _sessionId) return;
      _state.write(
        AppKeys.connectionStatus,
        ConnectionStatus.errorTlsHandshake,
      );
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

    if (client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      _state.write(AppKeys.connectionStatus, ConnectionStatus.error);
      _state.write(
        AppKeys.connectionError,
        client.connectionStatus?.toString(),
      );
      return;
    }

    for (final sub in broker.subscriptions) {
      client.subscribe(sub.topic, _mqtt3Qos(sub.qos));
    }

    _updatesSubscription = client.updates?.listen((messages) {
      if (session != _sessionId) return;
      for (final msg in messages) {
        if (msg.payload is! mqtt3.MqttPublishMessage) {
          _state.write(
            AppKeys.connectionError,
            'Malformed MQTT packet received: expected PUBLISH payload.',
          );
          continue;
        }
        final publish = msg.payload as mqtt3.MqttPublishMessage;
        final bytes = publish.payload.message;
        final retain = publish.header?.retain ?? false;
        final qos = publish.header?.qos.index ?? 0;
        _onMessage(
          msg.topic,
          Uint8List.fromList(bytes),
          retain: retain,
          qos: qos,
        );
      }
    });
  }

  Future<void> _connectV5(BrokerEntry broker, int session) async {
    final client = _mqtt5ClientFactory(broker);
    client.secure = broker.useSSL || !broker.clientCertificates.isEmpty;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.logging(on: false);

    if (!await _configureTlsContext(client, broker, session)) return;

    if (broker.useSSL && !broker.validateCertificates) {
      client.onBadCertificate = (_) => true;
    }

    client.onConnected = () {
      if (session == _sessionId) _onConnected();
    };
    client.onDisconnected = () {
      if (session == _sessionId) _onDisconnectedV5(client);
    };
    client.onAutoReconnect = () {
      if (session == _sessionId) {
        _state.write(AppKeys.connectionStatus, ConnectionStatus.connecting);
      }
    };
    client.onAutoReconnected = () {
      if (session == _sessionId) _onConnected();
    };

    _client5 = client;

    try {
      await client.connect(broker.username, broker.password);
    } on HandshakeException {
      if (session != _sessionId) return;
      _state.write(
        AppKeys.connectionStatus,
        ConnectionStatus.errorTlsHandshake,
      );
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

    final connectionStatus = client.connectionStatus;
    if (connectionStatus?.state != mqtt5.MqttConnectionState.connected) {
      final notice = _connectNotice(connectionStatus);
      _state.write(AppKeys.connectionStatus, ConnectionStatus.error);
      _state.write(
        AppKeys.connectionError,
        notice?.message ?? connectionStatus?.toString(),
      );
      return;
    }

    final connackNotice = _connectNotice(connectionStatus);
    if (connackNotice != null &&
        (connackNotice.reasonCodes.any((code) => code != 0) ||
            _hasReasonString(connackNotice))) {
      _surfaceReason(connackNotice);
    }

    // mqtt5_client exposes decoded protocol events through its event bus. The
    // bus is created during connect, so register immediately after CONNACK for
    // subsequent PUBACK/PUBREC/SUBACK/UNSUBACK/DISCONNECT packets.
    // ignore: invalid_use_of_protected_member
    _protocolSubscription = client.clientEventBus
        ?.on<mqtt5.MqttMessageAvailable>()
        .listen((event) {
          if (session != _sessionId || event.message == null) return;
          final notice = MqttReasonNotice.fromMqtt5Message(event.message!);
          if (notice != null &&
              (notice.reasonCodes.any((code) => code != 0) ||
                  _hasReasonString(notice))) {
            _surfaceReason(notice);
          }
        });

    for (final sub in broker.subscriptions) {
      client.subscribe(sub.topic, _mqtt5Qos(sub.qos));
    }

    _updatesSubscription = client.updates?.listen((messages) {
      if (session != _sessionId) return;
      for (final msg in messages) {
        if (msg.payload is! mqtt5.MqttPublishMessage) {
          _state.write(
            AppKeys.connectionError,
            'Malformed MQTT 5 packet received: expected PUBLISH payload.',
          );
          continue;
        }
        final publish = msg.payload as mqtt5.MqttPublishMessage;
        final bytes = publish.payload.message;
        if (msg.topic == null || msg.topic!.isEmpty || bytes == null) {
          _state.write(
            AppKeys.connectionError,
            'Malformed MQTT 5 PUBLISH packet received.',
          );
          continue;
        }
        final retain = publish.header?.retain ?? false;
        final qos = publish.header?.qos.index ?? 0;
        _onMessage(
          msg.topic!,
          Uint8List.fromList(bytes),
          retain: retain,
          qos: qos,
        );
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
    _protocolSubscription?.cancel();
    _protocolSubscription = null;
    try {
      _client3?.disconnect();
    } catch (_) {}
    try {
      _client5?.disconnect();
    } catch (_) {}
    _client3 = null;
    _client5 = null;
  }

  /// Callback called when the client successfully connects.
  void _onConnected() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.connected);
    _state.write(AppKeys.connectionError, null);
  }

  /// Callback called when the client disconnects.
  void _onDisconnected311() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _state.write(AppKeys.connectionError, mqtt311BrokerDisconnectMessage);
  }

  void _onDisconnectedV5(mqtt5_server.MqttServerClient client) {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    MqttReasonNotice? notice;
    try {
      notice = MqttReasonNotice.fromMqtt5Message(
        client.connectionStatus!.disconnectMessage,
      );
    } catch (_) {
      // A raw network loss has no MQTT DISCONNECT packet.
    }
    _state.write(
      AppKeys.connectionError,
      notice?.message ?? brokerDisconnectMessage(MqttProtocolVersion.v5),
    );
  }

  MqttReasonNotice? _connectNotice(mqtt5.MqttConnectionStatus? status) {
    if (status == null) return null;
    try {
      return MqttReasonNotice.fromMqtt5Message(status.connectAckMessage);
    } catch (_) {
      return null;
    }
  }

  bool _hasReasonString(MqttReasonNotice notice) =>
      notice.reasonString?.trim().isNotEmpty ?? false;

  void _surfaceReason(MqttReasonNotice notice) {
    _state.write(AppKeys.connectionError, notice.message);
  }

  Future<bool> _configureTlsContext(
    dynamic client,
    BrokerEntry broker,
    int session,
  ) async {
    final certificates = broker.clientCertificates;
    if (certificates.isEmpty) return true;
    try {
      client.securityContext = await _certificateService.buildSecurityContext(
        certificates,
      );
      return true;
    } catch (error) {
      if (session != _sessionId) return false;
      _state.write(
        AppKeys.connectionStatus,
        ConnectionStatus.errorTlsHandshake,
      );
      _state.write(AppKeys.connectionError, error.toString());
      return false;
    }
  }

  /// Handles an incoming message on the given topic.
  void _onMessage(
    String topic,
    Uint8List payload, {
    bool retain = false,
    int qos = 0,
  }) {
    final data = utf8.decode(payload, allowMalformed: true);
    _messages.add(
      MQTTMessage(
        topic: topic,
        payload: data,
        receivedAt: DateTime.now(),
        retain: retain,
        qos: qos,
      ),
    );
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
      _state.write(
        AppKeys.messageRate,
        (_rateCounter * 1000 / intervalMs).round(),
      );
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

  mqtt3.MqttQos _mqtt3Qos(int qos) => switch (qos) {
    1 => mqtt3.MqttQos.atLeastOnce,
    2 => mqtt3.MqttQos.exactlyOnce,
    _ => mqtt3.MqttQos.atMostOnce,
  };

  mqtt5.MqttQos _mqtt5Qos(int qos) => switch (qos) {
    1 => mqtt5.MqttQos.atLeastOnce,
    2 => mqtt5.MqttQos.exactlyOnce,
    _ => mqtt5.MqttQos.atMostOnce,
  };

  void dispose() {
    ++_sessionId;
    _cleanup();
    _rateTimer?.cancel();
    _state.removeListener(_onStateChanged);
    _messages.close();
  }
}
