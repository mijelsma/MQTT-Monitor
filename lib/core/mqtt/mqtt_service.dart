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
import 'publish_result.dart';

typedef Mqtt3ClientFactory = mqtt3_server.MqttServerClient Function(BrokerEntry broker);
typedef Mqtt5ClientFactory = mqtt5_server.MqttServerClient Function(BrokerEntry broker);

const _publishAckTimeout = Duration(seconds: 5);
const _socketTimeoutMs = 5000;

class MqttService {
  MqttService(this._state, {ClientCertificateService? certificateService, Mqtt3ClientFactory? mqtt3ClientFactory, Mqtt5ClientFactory? mqtt5ClientFactory})
    : _certificateService = certificateService ?? ClientCertificateService(),
      _mqtt3ClientFactory = mqtt3ClientFactory ?? ((broker) => mqtt3_server.MqttServerClient.withPort(broker.host, broker.effectiveClientId, broker.port, maxConnectionAttempts: 1)),
      _mqtt5ClientFactory = mqtt5ClientFactory ?? ((broker) => mqtt5_server.MqttServerClient.withPort(broker.host, broker.effectiveClientId, broker.port, maxConnectionAttempts: 1));

  final AppStateManager _state;
  final ClientCertificateService _certificateService;
  final Mqtt3ClientFactory _mqtt3ClientFactory;
  final Mqtt5ClientFactory _mqtt5ClientFactory;

  mqtt3_server.MqttServerClient? _client3;
  mqtt5_server.MqttServerClient? _client5;
  StreamSubscription? _updatesSubscription;
  StreamSubscription? _protocolSubscription;
  StreamSubscription<mqtt3.MqttPublishMessage>? _publishedSubscription3;
  MqttProtocolVersion? _activeProtocol;
  String? _currentBrokerId;
  String? _currentBrokerSignature;
  int _sessionId = 0;
  bool _isFirstSync = true;

  final Map<int, Completer<PublishResult>> _pendingV5Publishes = {};
  final Map<int, Completer<PublishResult>> _pendingV3Publishes = {};

  final _messages = StreamController<MQTTMessage>.broadcast();
  Stream<MQTTMessage> get messageStream => _messages.stream;

  Timer? _rateTimer;
  int _rateCounter = 0;
  int _messageCount = 0;
  int _rateIntervalMs = 0;

  void initialize() {
    _state.addListener(_onStateChanged);
    _startRateTimer();
    _sync();
  }

  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) {
    if (_activeProtocol == MqttProtocolVersion.v5) {
      return _publishV5(topic, payload, qos: qos, retain: retain);
    }
    return _publishV311(topic, payload, qos: qos, retain: retain);
  }

  Future<PublishResult>? _publishV5(String topic, String payload, {required int qos, required bool retain}) {
    final client = _client5;
    if (client == null || client.connectionStatus?.state != mqtt5.MqttConnectionState.connected) {
      return null;
    }
    final builder = mqtt5.MqttPayloadBuilder()..addString(payload);
    int packetId;
    try {
      packetId = client.publishMessage(topic, _mqtt5Qos(qos), builder.payload!, retain: retain);
    } catch (e) {
      return Future.value(PublishResult.localFailure(e.toString()));
    }
    if (qos == 0) {
      return Future.value(PublishResult.unconfirmed(MqttProtocolVersion.v5, 0));
    }
    final completer = Completer<PublishResult>();
    _pendingV5Publishes[packetId] = completer;
    completer.future.whenComplete(() => _pendingV5Publishes.remove(packetId));
    return completer.future.timeout(
      _publishAckTimeout,
      onTimeout: () {
        return PublishResult.timedOut(MqttProtocolVersion.v5, qos);
      },
    );
  }

  Future<PublishResult>? _publishV311(String topic, String payload, {required int qos, required bool retain}) {
    final client = _client3;
    if (client == null || client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      return null;
    }
    final builder = mqtt3.MqttClientPayloadBuilder()..addString(payload);
    int packetId;
    try {
      packetId = client.publishMessage(topic, _mqtt3Qos(qos), builder.payload!, retain: retain);
    } catch (e) {
      return Future.value(PublishResult.localFailure(e.toString()));
    }
    if (qos == 0) {
      return Future.value(PublishResult.unconfirmed(MqttProtocolVersion.v311, 0));
    }
    final completer = Completer<PublishResult>();
    _pendingV3Publishes[packetId] = completer;
    completer.future.whenComplete(() => _pendingV3Publishes.remove(packetId));
    return completer.future.timeout(
      _publishAckTimeout,
      onTimeout: () {
        return PublishResult.timedOut(MqttProtocolVersion.v311, qos);
      },
    );
  }

  bool subscribe(String topic, {int qos = 0}) {
    if (_activeProtocol == MqttProtocolVersion.v5) {
      final client = _client5;
      if (client == null || client.connectionStatus?.state != mqtt5.MqttConnectionState.connected) {
        return false;
      }
      client.subscribe(topic, _mqtt5Qos(qos));
      return true;
    }
    final client = _client3;
    if (client == null || client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      return false;
    }
    client.subscribe(topic, _mqtt3Qos(qos));
    return true;
  }

  bool unsubscribe(String topic) {
    if (_activeProtocol == MqttProtocolVersion.v5) {
      final client = _client5;
      if (client == null || client.connectionStatus?.state != mqtt5.MqttConnectionState.connected) {
        return false;
      }
      client.unsubscribeStringTopic(topic);
      return true;
    }
    final client = _client3;
    if (client == null || client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      return false;
    }
    client.unsubscribe(topic);
    return true;
  }

  void disconnect() {
    _state.write(AppKeys.disconnected, true);
    _teardown();
  }

  void reconnect() {
    _state.write(AppKeys.disconnected, false);
    _currentBrokerId = null;
    _currentBrokerSignature = null;
    _sync();
  }

  MqttProtocolVersion? get activeProtocol => _activeProtocol;

  void _onStateChanged() {
    _sync();

    final intervalMs = _state.read(SettingsKeys.rateIntervalMs);
    if (intervalMs != _rateIntervalMs) _startRateTimer();
  }

  void _sync() {
    final brokers = _state.read(SettingsKeys.brokers);
    final activeBrokerId = _state.read(AppKeys.activeBrokerId);

    final broker = brokers.isEmpty ? null : brokers.firstWhere((b) => b.id == activeBrokerId, orElse: () => brokers.first);

    final brokerSignature = broker == null ? null : jsonEncode(broker.toJson());
    if (broker?.id == _currentBrokerId && brokerSignature == _currentBrokerSignature) {
      return;
    }
    _currentBrokerId = broker?.id;
    _currentBrokerSignature = brokerSignature;

    if (broker == null) {
      _teardown();
      return;
    }

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
      _clearError();
      return;
    }

    _connect(broker);
  }

  Future<void> _connect(BrokerEntry broker) async {
    final session = ++_sessionId;
    _cleanup();
    _failPendingPublishes();
    _resetCounters();

    _state.write(AppKeys.connectionStatus, ConnectionStatus.connecting);
    _clearError();

    switch (broker.protocolVersion) {
      case MqttProtocolVersion.v5:
        _activeProtocol = MqttProtocolVersion.v5;
        await _connectV5(broker, session);
      case MqttProtocolVersion.v311:
        _activeProtocol = MqttProtocolVersion.v311;
        await _connectV311(broker, session);
    }
  }

  Future<void> _connectV311(BrokerEntry broker, int session) async {
    final client = _mqtt3ClientFactory(broker);
    client.secure = broker.useSSL || !broker.clientCertificates.isEmpty;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.socketTimeout = _socketTimeoutMs;
    client.logging(on: false);

    if (!await _configureTlsContext(client, broker, session)) return;

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
    } on HandshakeException catch (e) {
      if (session != _sessionId) return;
      _reportError(ConnectionStatus.errorTlsHandshake, _tlsHandshakeMessage(broker), detail: e.toString());
      return;
    } on SocketException catch (e) {
      if (session != _sessionId) return;
      final status = _socketStatus(e);
      _reportError(status, _socketMessage(status, broker), detail: e.toString());
      return;
    } catch (e) {
      if (session != _sessionId) return;
      var returnCode = client.connectionStatus?.returnCode;
      if (returnCode == null || returnCode == mqtt3.MqttConnectReturnCode.noneSpecified) {
        returnCode = _mqtt3ReturnCodeFromText(e);
      }
      var recoveredLate = false;
      if (returnCode == null || returnCode == mqtt3.MqttConnectReturnCode.noneSpecified) {
        returnCode = await _lateMqtt3ReturnCode(client.connectionStatus, session);
        recoveredLate = returnCode != null;
      }
      final returnCodeMessage = _mqtt3ReturnCodeMessage(broker, returnCode);
      _reportError(ConnectionStatus.error, returnCodeMessage ?? _genericConnectMessage(broker), detail: _detailWithCode(e, returnCode, recoveredLate));
      return;
    }

    if (session != _sessionId) return;

    if (client.connectionStatus?.state != mqtt3.MqttConnectionState.connected) {
      if (session != _sessionId) return;
      final returnCodeMessage = _mqtt3ReturnCodeMessage(broker, client.connectionStatus?.returnCode);
      _reportError(ConnectionStatus.error, returnCodeMessage ?? _brokerRejectedMessage(broker));
      return;
    }

    for (final sub in broker.subscriptions) {
      client.subscribe(sub.topic, _mqtt3Qos(sub.qos));
    }

    _updatesSubscription = client.updates?.listen((messages) {
      if (session != _sessionId) return;
      for (final msg in messages) {
        if (msg.payload is! mqtt3.MqttPublishMessage) {
          _state.write(AppKeys.connectionError, 'Malformed MQTT packet received: expected PUBLISH payload.');
          _state.write(AppKeys.connectionErrorDetail, null);
          continue;
        }
        final publish = msg.payload as mqtt3.MqttPublishMessage;
        final bytes = publish.payload.message;
        final retain = publish.header?.retain ?? false;
        final qos = publish.header?.qos.index ?? 0;
        _onMessage(msg.topic, Uint8List.fromList(bytes), retain: retain, qos: qos);
      }
    });

    _publishedSubscription3 = client.published?.listen((mqtt3.MqttPublishMessage published) {
      final packetId = published.variableHeader?.messageIdentifier;
      if (packetId == null) return;
      final completer = _pendingV3Publishes.remove(packetId);
      if (completer == null || completer.isCompleted) return;
      completer.complete(PublishResult.unconfirmed(MqttProtocolVersion.v311, published.header?.qos.index ?? 1));
    });
  }

  Future<void> _connectV5(BrokerEntry broker, int session) async {
    final client = _mqtt5ClientFactory(broker);
    client.secure = broker.useSSL || !broker.clientCertificates.isEmpty;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.socketTimeout = _socketTimeoutMs;
    client.logging(on: false);

    if (!await _configureTlsContext(client, broker, session)) return;

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
    } on HandshakeException catch (e) {
      if (session != _sessionId) return;
      _reportError(ConnectionStatus.errorTlsHandshake, _tlsHandshakeMessage(broker), detail: e.toString());
      return;
    } on SocketException catch (e) {
      if (session != _sessionId) return;
      final status = _socketStatus(e);
      _reportError(status, _socketMessage(status, broker), detail: e.toString());
      return;
    } catch (e) {
      if (session != _sessionId) return;
      var reasonCode = _mqtt5ConnectReasonCode(client.connectionStatus) ?? _mqtt5ReasonCodeFromText(e);
      var recoveredLate = false;
      if (reasonCode == null) {
        reasonCode = await _lateMqtt5ReasonCode(client.connectionStatus, session);
        recoveredLate = reasonCode != null;
      }
      final reasonMessage = _mqtt5ConnectReasonMessage(broker, reasonCode);
      _reportError(ConnectionStatus.error, reasonMessage ?? _genericConnectMessage(broker), detail: _detailWithCode(e, reasonCode, recoveredLate));
      return;
    }

    if (session != _sessionId) return;

    final connectionStatus = client.connectionStatus;
    if (connectionStatus?.state != mqtt5.MqttConnectionState.connected) {
      final reasonCode = _mqtt5ConnectReasonCode(connectionStatus);
      final reasonMessage = _mqtt5ConnectReasonMessage(broker, reasonCode);
      _reportError(ConnectionStatus.error, reasonMessage ?? _brokerRejectedMessage(broker));
      return;
    }

    final connackNotice = _connectNotice(connectionStatus);
    if (connackNotice != null && (connackNotice.reasonCodes.any((code) => code != 0) || _hasReasonString(connackNotice))) {
      _surfaceReason(connackNotice);
    }

    _protocolSubscription = client.clientEventBus?.on<mqtt5.MqttMessageAvailable>().listen((event) {
      if (session != _sessionId || event.message == null) return;
      final message = event.message!;

      if (message is mqtt5.MqttPublishAckMessage || message is mqtt5.MqttPublishReceivedMessage) {
        final packetId = message is mqtt5.MqttPublishAckMessage ? message.variableHeader?.messageIdentifier : (message as mqtt5.MqttPublishReceivedMessage).variableHeader.messageIdentifier;
        if (packetId != null) {
          final completer = _pendingV5Publishes.remove(packetId);
          if (completer != null && !completer.isCompleted) {
            final notice = MqttReasonNotice.fromMqtt5Message(message);
            final reasonCode = notice?.reasonCodes.isNotEmpty == true ? notice!.reasonCodes.first : 0;
            if (reasonCode >= 0x80) {
              completer.complete(PublishResult.failed(reasonCode: reasonCode, reasonString: notice?.reasonString));
            } else {
              completer.complete(PublishResult.delivered(reasonCode: reasonCode, reasonString: notice?.reasonString));
            }
          }
        }
      }

      final notice = MqttReasonNotice.fromMqtt5Message(message);
      if (notice != null && (notice.reasonCodes.any((code) => code != 0) || _hasReasonString(notice))) {
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
          _state.write(AppKeys.connectionError, 'Malformed MQTT 5 packet received: expected PUBLISH payload.');
          _state.write(AppKeys.connectionErrorDetail, null);
          continue;
        }
        final publish = msg.payload as mqtt5.MqttPublishMessage;
        final bytes = publish.payload.message;
        if (msg.topic == null || msg.topic!.isEmpty || bytes == null) {
          _state.write(AppKeys.connectionError, 'Malformed MQTT 5 PUBLISH packet received.');
          _state.write(AppKeys.connectionErrorDetail, null);
          continue;
        }
        final retain = publish.header?.retain ?? false;
        final qos = publish.header?.qos.index ?? 0;
        _onMessage(msg.topic!, Uint8List.fromList(bytes), retain: retain, qos: qos);
      }
    });
  }

  void _teardown() {
    ++_sessionId;
    _cleanup();
    _resetCounters();
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _clearError();
  }

  void _cleanup() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _protocolSubscription?.cancel();
    _protocolSubscription = null;
    _publishedSubscription3?.cancel();
    _publishedSubscription3 = null;
    try {
      _client3?.disconnect();
    } catch (_) {}
    try {
      _client5?.disconnect();
    } catch (_) {}
    _client3 = null;
    _client5 = null;
  }

  void _failPendingPublishes() {
    final version = _activeProtocol;
    for (final completer in _pendingV5Publishes.values) {
      if (!completer.isCompleted) {
        completer.complete(PublishResult.timedOut(version ?? MqttProtocolVersion.v5, 1));
      }
    }
    for (final completer in _pendingV3Publishes.values) {
      if (!completer.isCompleted) {
        completer.complete(PublishResult.timedOut(version ?? MqttProtocolVersion.v311, 1));
      }
    }
    _pendingV5Publishes.clear();
    _pendingV3Publishes.clear();
  }

  /// Callback called when the client successfully connects.
  void _onConnected() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.connected);
    _clearError();
  }

  /// Callback called when the client disconnects.
  void _onDisconnected311() {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    _state.write(AppKeys.connectionErrorDetail, null);
    _state.write(AppKeys.connectionError, mqtt311BrokerDisconnectMessage);
  }

  void _onDisconnectedV5(mqtt5_server.MqttServerClient client) {
    _state.write(AppKeys.connectionStatus, ConnectionStatus.disconnected);
    MqttReasonNotice? notice;
    try {
      notice = MqttReasonNotice.fromMqtt5Message(client.connectionStatus!.disconnectMessage);
    } catch (_) {}
    _state.write(AppKeys.connectionErrorDetail, notice?.reasonString);
    _state.write(AppKeys.connectionError, notice?.message ?? brokerDisconnectMessage(MqttProtocolVersion.v5));
  }

  MqttReasonNotice? _connectNotice(mqtt5.MqttConnectionStatus? status) {
    if (status == null) return null;
    try {
      return MqttReasonNotice.fromMqtt5Message(status.connectAckMessage);
    } catch (_) {
      return null;
    }
  }

  bool _hasReasonString(MqttReasonNotice notice) => notice.reasonString?.trim().isNotEmpty ?? false;

  void _surfaceReason(MqttReasonNotice notice) {
    _state.write(AppKeys.connectionErrorDetail, notice.reasonString);
    _state.write(AppKeys.connectionError, notice.message);
  }

  Future<bool> _configureTlsContext(dynamic client, BrokerEntry broker, int session) async {
    final certificates = broker.clientCertificates;
    if (certificates.isEmpty) return true;
    try {
      final context = await _certificateService.buildSecurityContext(certificates);
      client.securityContext = context;
      _configureCertificateValidation(client, broker);
      return true;
    } catch (error) {
      if (session != _sessionId) return false;
      _reportError(ConnectionStatus.errorTlsHandshake, 'Could not load the mTLS credentials.\nVerify the Root CA, client certificate, and private key are valid PEM files.', detail: error.toString());
      return false;
    }
  }

  void _configureCertificateValidation(dynamic client, BrokerEntry broker) {
    if (!broker.validateCertificates) {
      client.onBadCertificate = (dynamic _) => true;
      return;
    }

    if (broker.clientCertificates.rootCaPath != null) {
      client.onBadCertificate = (dynamic certificate) {
        if (certificate is! X509Certificate) return false;
        final now = DateTime.now();
        if (now.isBefore(certificate.startValidity) || now.isAfter(certificate.endValidity)) {
          return false;
        }
        return true;
      };
    }
  }

  ConnectionStatus _socketStatus(SocketException e) {
    final code = e.osError?.errorCode;
    return switch (code) {
      1 => ConnectionStatus.errorNotPermitted,
      8 => ConnectionStatus.errorHostNotFound,
      61 || 111 => ConnectionStatus.errorRefused,
      _ => ConnectionStatus.error,
    };
  }

  String _socketMessage(ConnectionStatus status, BrokerEntry broker) {
    final (base, suggestion) = switch (status) {
      ConnectionStatus.errorHostNotFound => ("Could not resolve host '${broker.host}'.", 'Check the hostname for typos and verify your DNS or network settings.'),
      ConnectionStatus.errorNotPermitted => ('The operating system blocked the connection.', 'Check your firewall rules, VPN, or network permissions.'),
      ConnectionStatus.errorRefused => ('The broker refused the connection.', 'Verify the broker is running and listening on port ${broker.port}.'),
      _ => ('Network error reaching the broker.', 'Check your network connection and the broker address.'),
    };

    return '$base\n$suggestion';
  }

  String _tlsHandshakeMessage(BrokerEntry broker) {
    final base = 'The TLS handshake could not be completed.';

    final hasRootCa = broker.clientCertificates.rootCaPath != null;
    final suggestion = broker.validateCertificates
        ? (hasRootCa
              ? 'The broker certificate chain was checked against your Root CA, and expired certificates are rejected, but hostname mismatches (e.g. connecting via an IP address) are tolerated. If the handshake still fails, verify the Root CA actually signed the broker certificate, and that the client certificate and private key match.'
              : 'Provide a Root CA certificate in the broker settings to validate a self-signed broker, or disable "Validate Certificates".')
        : '';

    return suggestion.isEmpty ? base : '$base\n$suggestion';
  }

  String _genericConnectMessage(BrokerEntry broker) {
    return 'The broker did not answer the connection request.\nCheck the broker address, port, credentials, and TLS settings.';
  }

  String _brokerRejectedMessage(BrokerEntry broker) {
    return 'The broker rejected the connection.\nCheck your username, password, Client ID, and TLS settings.';
  }

  /// Atomically surfaces a connection failure: a friendly message for the
  /// notice body and an optional raw technical detail (exception text, OS
  /// error, broker-provided reason string) for the collapsible section.
  void _reportError(ConnectionStatus status, String message, {String? detail}) {
    _state.write(AppKeys.connectionStatus, status);
    _state.write(AppKeys.connectionError, message);
    _state.write(AppKeys.connectionErrorDetail, detail);
  }

  /// Clears the friendly message and its raw detail together.
  void _clearError() {
    _state.write(AppKeys.connectionError, null);
    _state.write(AppKeys.connectionErrorDetail, null);
  }

  /// Maps an MQTT 3.1.1 [MqttConnectReturnCode] to a clean, user-facing
  /// message. Returns `null` for codes that aren't connection failures
  /// (accepted / not yet specified), so the caller can fall back.
  String? _mqtt3ReturnCodeMessage(BrokerEntry broker, mqtt3.MqttConnectReturnCode? code) {
    final (reason, suggestion) = switch (code) {
      mqtt3.MqttConnectReturnCode.unacceptedProtocolVersion => ('Unsupported protocol version', 'The broker does not support MQTT 3.1.1. Try switching to MQTT 5 in the broker settings.'),
      mqtt3.MqttConnectReturnCode.identifierRejected => ('Client identifier rejected', 'Use a different Client ID in the broker settings.'),
      mqtt3.MqttConnectReturnCode.brokerUnavailable => ('Broker unavailable', 'The broker is temporarily unavailable. Try again later.'),
      mqtt3.MqttConnectReturnCode.badUsernameOrPassword => ('Bad username or password', 'Check your username and password in the broker settings.'),
      mqtt3.MqttConnectReturnCode.notAuthorized => ('Not authorized', 'Check your credentials and confirm your account is permitted to connect.'),
      _ => (null, null),
    };

    if (reason == null) return null;
    // The notice shows the broker name/address up top, so the message only
    // carries the reason and what to do about it.
    return '$reason.\n$suggestion';
  }

  /// Safely extracts the MQTT 5 connect reason code from a connection status,
  /// returning `null` if any link in the chain is missing.
  ///
  /// The library copies the CONNACK reason code onto a plain
  /// [MqttConnectionStatus.reasonCode] field before failing the connect, so
  /// that field is preferred. `connectAckMessage` is a `late` field that is
  /// only initialized on a *successful* CONNACK; accessing it otherwise
  /// throws `LateInitializationError`, which we treat as "no reason code".
  mqtt5.MqttConnectReasonCode? _mqtt5ConnectReasonCode(mqtt5.MqttConnectionStatus? status) {
    if (status == null) return null;
    final code = status.reasonCode;
    if (code != null && code != mqtt5.MqttConnectReasonCode.notSet) return code;
    try {
      return status.connectAckMessage.variableHeader?.reasonCode;
    } catch (_) {
      return null;
    }
  }

  String _detailWithCode(Object? error, Enum? code, bool recoveredLate) {
    final raw = error?.toString().trim() ?? '';
    if (!recoveredLate || code == null || raw.isEmpty) return raw;
    if (raw.contains(code.name)) return raw;
    return '$raw\nBroker CONNACK code: $code';
  }

  Future<mqtt3.MqttConnectReturnCode?> _lateMqtt3ReturnCode(mqtt3.MqttClientConnectionStatus? status, int session) async {
    for (var i = 0; i < 20; i++) {
      if (status == null || session != _sessionId) return null;
      final code = status.returnCode;
      if (code != null && code != mqtt3.MqttConnectReturnCode.noneSpecified) return code;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }

  Future<mqtt5.MqttConnectReasonCode?> _lateMqtt5ReasonCode(mqtt5.MqttConnectionStatus? status, int session) async {
    for (var i = 0; i < 20; i++) {
      if (status == null || session != _sessionId) return null;
      final code = status.reasonCode;
      if (code != null && code != mqtt5.MqttConnectReasonCode.notSet) return code;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }

  mqtt5.MqttConnectReasonCode? _mqtt5ReasonCodeFromText(Object error) => _enumByLastSegment(mqtt5.MqttConnectReasonCode.values, RegExp(r'reason code is ([\w.]+)', caseSensitive: false).firstMatch(error.toString())?.group(1));

  mqtt3.MqttConnectReturnCode? _mqtt3ReturnCodeFromText(Object error) => _enumByLastSegment(mqtt3.MqttConnectReturnCode.values, RegExp(r'return code is ([\w.]+)', caseSensitive: false).firstMatch(error.toString())?.group(1));

  T? _enumByLastSegment<T extends Enum>(List<T> values, String? match) {
    final name = match?.split('.').last;
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  String? _mqtt5ConnectReasonMessage(BrokerEntry broker, mqtt5.MqttConnectReasonCode? code) {
    final (reason, suggestion) = switch (code) {
      mqtt5.MqttConnectReasonCode.unspecifiedError => ('Unspecified error', 'The broker did not specify a reason for the rejection.'),
      mqtt5.MqttConnectReasonCode.malformedPacket => ('Malformed connect packet', 'This is likely a client/broker protocol mismatch.'),
      mqtt5.MqttConnectReasonCode.protocolError => ('Protocol error', 'The client and broker disagree on the MQTT protocol. Try a different protocol version.'),
      mqtt5.MqttConnectReasonCode.implementationSpecificError => ('Rejected by broker', 'The broker rejected the connection for an implementation-specific reason.'),
      mqtt5.MqttConnectReasonCode.unsupportedProtocolVersion => ('Unsupported protocol version', 'The broker does not support MQTT 5. Try MQTT 3.1.1 in the broker settings.'),
      mqtt5.MqttConnectReasonCode.clientIdentifierNotValid => ('Invalid client identifier', 'Use a valid Client ID in the broker settings.'),
      mqtt5.MqttConnectReasonCode.badUsernameOrPassword => ('Bad username or password', 'Check your username and password in the broker settings.'),
      mqtt5.MqttConnectReasonCode.notAuthorized => ('Not authorized', 'Check your credentials and confirm your account is permitted to connect.'),
      mqtt5.MqttConnectReasonCode.serverUnavailable => ('Server unavailable', 'The broker is temporarily unavailable. Try again later.'),
      mqtt5.MqttConnectReasonCode.serverBusy => ('Server busy', 'The broker is busy. Try again later.'),
      mqtt5.MqttConnectReasonCode.banned => ('Client banned', 'This client has been banned by the broker administrator.'),
      mqtt5.MqttConnectReasonCode.badAuthenticationMethod => ('Unsupported authentication method', 'The broker does not support the requested authentication method.'),
      mqtt5.MqttConnectReasonCode.topicNameInvalid => ('Invalid Will topic name', 'Check the Will topic in your broker settings.'),
      mqtt5.MqttConnectReasonCode.packetTooLarge => ('Connect packet too large', 'The connect packet exceeded the broker\'s maximum allowed size.'),
      mqtt5.MqttConnectReasonCode.quotaExceeded => ('Quota exceeded', 'An administrative limit has been exceeded. Contact the broker administrator.'),
      mqtt5.MqttConnectReasonCode.payloadFormatInvalid => ('Invalid Will payload format', 'Check the Will payload format in your broker settings.'),
      mqtt5.MqttConnectReasonCode.retainNotSupported => ('Retain not supported', 'The broker does not support retained messages, but a Will retain was requested.'),
      mqtt5.MqttConnectReasonCode.qosNotSupported => ('Will QoS not supported', 'The broker does not support the QoS level set for the Will message.'),
      mqtt5.MqttConnectReasonCode.useAnotherServer => ('Use another server', 'The broker suggests connecting to a different server.'),
      mqtt5.MqttConnectReasonCode.serverMoved => ('Server moved', 'The broker has moved. Update the broker address.'),
      mqtt5.MqttConnectReasonCode.connectionRateExceeded => ('Connection rate exceeded', 'Too many connection attempts. Wait a moment and try again.'),
      _ => (null, null),
    };

    if (reason == null) return null;
    return '$reason.\n$suggestion';
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
    _failPendingPublishes();
    _rateTimer?.cancel();
    _state.removeListener(_onStateChanged);
    _messages.close();
  }
}
