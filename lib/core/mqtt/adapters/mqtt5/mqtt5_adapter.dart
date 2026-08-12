import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;

import '../../../../models/broker_entry.dart';
import '../../../../models/mqtt_protocol_version.dart';
import '../../connection_status.dart';
import '../../mqtt_connection_failure.dart';
import '../../mqtt_message.dart';
import '../../mqtt_protocol_adapter.dart';
import '../../mqtt_protocol_event.dart';
import '../../mqtt_reason.dart';
import '../../publish_result.dart';
import '../shared/mqtt_connection_error_mapper.dart';
import '../shared/mqtt_tls_configurator.dart';
import 'mqtt5_event_client.dart';

/// Creates the observable MQTT 5 package client used for [broker].
typedef Mqtt5ClientFactory = Mqtt5EventClient Function(BrokerEntry broker);

const _socketTimeoutMs = 5000;

/// Adapts the mqtt5_client package to the application MQTT session contract.
class Mqtt5Adapter implements MqttProtocolAdapter {
  /// Creates an MQTT 5 adapter for [broker].
  Mqtt5Adapter(this._broker, {MqttTlsConfigurator? tlsConfigurator, Mqtt5ClientFactory? clientFactory, Duration publishAckTimeout = const Duration(seconds: 5)})
    : _tlsConfigurator = tlsConfigurator ?? MqttTlsConfigurator(),
      _clientFactory = clientFactory ?? ((profile) => Mqtt5EventClient.withPort(profile.host, profile.effectiveClientId, profile.port, maxConnectionAttempts: 1)),
      _publishAckTimeout = publishAckTimeout;

  final BrokerEntry _broker;
  final MqttTlsConfigurator _tlsConfigurator;
  final Mqtt5ClientFactory _clientFactory;
  final Duration _publishAckTimeout;
  final StreamController<MqttProtocolEvent> _events = StreamController<MqttProtocolEvent>.broadcast();
  final StreamController<MQTTMessage> _messages = StreamController<MQTTMessage>.broadcast();
  final Map<int, _PendingPublish> _pendingPublishes = {};

  Mqtt5EventClient? _client;
  StreamSubscription<List<mqtt5.MqttReceivedMessage<mqtt5.MqttMessage>>>? _updatesSubscription;
  StreamSubscription<mqtt5.MqttMessageAvailable>? _protocolSubscription;
  bool _disposed = false;

  /// Returns MQTT 5 as the implemented protocol.
  @override
  MqttProtocolVersion get protocolVersion => MqttProtocolVersion.v5;

  /// Returns lifecycle and diagnostic events.
  @override
  Stream<MqttProtocolEvent> get events => _events.stream;

  /// Returns decoded application messages.
  @override
  Stream<MQTTMessage> get messages => _messages.stream;

  /// Returns whether mqtt5_client reports a connected state.
  @override
  bool get isConnected => _client?.connectionStatus?.state == mqtt5.MqttConnectionState.connected;

  /// Configures, connects, and subscribes the MQTT 5 client.
  @override
  Future<void> connect() async {
    final client = _clientFactory(_broker);
    _client = client;
    client.secure = _broker.useSSL || !_broker.clientCertificates.isEmpty;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = false;
    client.socketTimeout = _socketTimeoutMs;
    client.logging(on: false);
    try {
      await _tlsConfigurator.configure(client, _broker);
    } on Object catch (error) {
      throw MqttConnectionErrorMapper.mtls(error);
    }

    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onAutoReconnect = _onAutoReconnect;
    client.onAutoReconnected = _onConnected;

    try {
      await client.connect(_broker.username, _broker.password);
    } on HandshakeException catch (error) {
      throw MqttConnectionErrorMapper.tlsHandshake(error, _broker);
    } on SocketException catch (error) {
      throw MqttConnectionErrorMapper.socket(error, _broker);
    } on Object catch (error) {
      var code = _connectReasonCode(client.connectionStatus) ?? _reasonCodeFromText(error);
      var recoveredLate = false;
      if (code == null) {
        code = await _lateReasonCode(client.connectionStatus);
        recoveredLate = code != null;
      }
      throw MqttConnectionFailure(ConnectionStatus.error, _connectReasonMessage(code) ?? MqttConnectionErrorMapper.genericConnect(_broker), detail: _detailWithCode(error, code, recoveredLate));
    }

    if (_disposed) return;
    if (!isConnected) {
      final code = _connectReasonCode(client.connectionStatus);
      throw MqttConnectionFailure(ConnectionStatus.error, _connectReasonMessage(code) ?? MqttConnectionErrorMapper.brokerRejected(_broker));
    }

    final notice = _connectNotice(client.connectionStatus);
    if (notice != null && _shouldSurface(notice)) {
      _events.add(MqttProtocolEvent.notice(notice.message, detail: notice.reasonString));
    }
    _protocolSubscription = client.protocolEvents.listen(_onProtocolMessage);
    _updatesSubscription = client.updates?.listen(_onUpdates);
  }

  /// Publishes [payload] and resolves MQTT 5 broker reason codes.
  @override
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) {
    final client = _client;
    if (client == null || !isConnected) return null;
    final builder = mqtt5.MqttPayloadBuilder()..addString(payload);
    final int packetId;
    try {
      packetId = client.publishMessage(topic, _qos(qos), builder.payload!, retain: retain);
    } on Object catch (error) {
      return Future<PublishResult>.value(PublishResult.localFailure(error.toString()));
    }
    if (qos == 0) {
      return Future<PublishResult>.value(PublishResult.unconfirmed(protocolVersion, qos));
    }
    final pending = _PendingPublish(qos);
    _pendingPublishes[packetId] = pending;
    pending.timer = Timer(_publishAckTimeout, () {
      if (_pendingPublishes.remove(packetId) == pending && !pending.completer.isCompleted) {
        pending.completer.complete(PublishResult.timedOut(protocolVersion, qos));
      }
    });
    return pending.completer.future;
  }

  /// Subscribes to [topic] through the connected MQTT 5 client.
  @override
  bool subscribe(String topic, {int qos = 0}) {
    final client = _client;
    if (client == null || !isConnected) return false;
    client.subscribe(topic, _qos(qos));
    return true;
  }

  /// Unsubscribes from [topic] through the connected MQTT 5 client.
  @override
  bool unsubscribe(String topic) {
    final client = _client;
    if (client == null || !isConnected) return false;
    client.unsubscribeStringTopic(topic);
    return true;
  }

  /// Disconnects the package client and releases adapter-owned resources.
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _updatesSubscription?.cancel();
    await _protocolSubscription?.cancel();
    for (final pending in _pendingPublishes.values) {
      pending.timer?.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.complete(PublishResult.timedOut(protocolVersion, pending.qos));
      }
    }
    _pendingPublishes.clear();
    try {
      _client?.disconnect();
    } on Object {
      // Package disconnect is best effort during teardown.
    }
    await _events.close();
    await _messages.close();
  }

  /// Emits a successful connection event for current package callbacks.
  void _onConnected() {
    if (!_disposed) _events.add(const MqttProtocolEvent.connected());
  }

  /// Emits a connecting state for automatic reconnect attempts.
  void _onAutoReconnect() {
    if (!_disposed) _events.add(const MqttProtocolEvent.reconnecting());
  }

  /// Extracts and emits a broker-driven MQTT 5 disconnect reason.
  void _onDisconnected() {
    if (_disposed) return;
    MqttReasonNotice? notice;
    try {
      notice = MqttReasonNotice.fromMqtt5Message(_client!.connectionStatus!.disconnectMessage);
    } on Object {
      // A missing disconnect packet is valid for transport-level disconnects.
    }
    _events.add(MqttProtocolEvent.disconnected(message: notice?.message ?? brokerDisconnectMessage(protocolVersion), detail: notice?.reasonString));
  }

  /// Converts package update batches into application messages and notices.
  void _onUpdates(List<mqtt5.MqttReceivedMessage<mqtt5.MqttMessage>> updates) {
    if (_disposed) return;
    for (final received in updates) {
      if (received.payload is! mqtt5.MqttPublishMessage) {
        _events.add(const MqttProtocolEvent.notice('Malformed MQTT 5 packet received: expected PUBLISH payload.'));
        continue;
      }
      final publish = received.payload as mqtt5.MqttPublishMessage;
      final bytes = publish.payload.message;
      if (received.topic == null || received.topic!.isEmpty || bytes == null) {
        _events.add(const MqttProtocolEvent.notice('Malformed MQTT 5 PUBLISH packet received.'));
        continue;
      }
      _messages.add(MQTTMessage(topic: received.topic!, payload: utf8.decode(Uint8List.fromList(bytes), allowMalformed: true), receivedAt: DateTime.now(), retain: publish.header?.retain ?? false, qos: publish.header?.qos.index ?? 0));
    }
  }

  /// Resolves publish acknowledgements and emits broker reason notices.
  void _onProtocolMessage(mqtt5.MqttMessageAvailable event) {
    if (_disposed || event.message == null) return;
    final message = event.message!;
    if (message is mqtt5.MqttPublishAckMessage || message is mqtt5.MqttPublishReceivedMessage) {
      final packetId = message is mqtt5.MqttPublishAckMessage ? message.variableHeader?.messageIdentifier : (message as mqtt5.MqttPublishReceivedMessage).variableHeader.messageIdentifier;
      if (packetId != null) {
        final pending = _pendingPublishes.remove(packetId);
        if (pending != null && !pending.completer.isCompleted) {
          pending.timer?.cancel();
          final notice = MqttReasonNotice.fromMqtt5Message(message);
          final reasonCode = notice?.reasonCodes.isNotEmpty == true ? notice!.reasonCodes.first : 0;
          pending.completer.complete(reasonCode >= 0x80 ? PublishResult.failed(reasonCode: reasonCode, reasonString: notice?.reasonString) : PublishResult.delivered(reasonCode: reasonCode, reasonString: notice?.reasonString));
        }
      }
    }
    final notice = MqttReasonNotice.fromMqtt5Message(message);
    if (notice != null && _shouldSurface(notice)) {
      _events.add(MqttProtocolEvent.notice(notice.message, detail: notice.reasonString));
    }
  }

  /// Returns whether [notice] contains meaningful broker diagnostics.
  bool _shouldSurface(MqttReasonNotice notice) {
    return notice.reasonCodes.any((code) => code != 0) || (notice.reasonString?.trim().isNotEmpty ?? false);
  }

  /// Extracts a successful CONNACK notice when available.
  MqttReasonNotice? _connectNotice(mqtt5.MqttConnectionStatus? status) {
    if (status == null) return null;
    try {
      return MqttReasonNotice.fromMqtt5Message(status.connectAckMessage);
    } on Object {
      return null;
    }
  }

  /// Extracts the MQTT 5 connect reason code without touching late data unsafely.
  mqtt5.MqttConnectReasonCode? _connectReasonCode(mqtt5.MqttConnectionStatus? status) {
    if (status == null) return null;
    final code = status.reasonCode;
    if (code != null && code != mqtt5.MqttConnectReasonCode.notSet) return code;
    try {
      return status.connectAckMessage.variableHeader?.reasonCode;
    } on Object {
      return null;
    }
  }

  /// Polls briefly for a reason code written after a failed connect future.
  Future<mqtt5.MqttConnectReasonCode?> _lateReasonCode(mqtt5.MqttConnectionStatus? status) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (_disposed || status == null) return null;
      final code = status.reasonCode;
      if (code != null && code != mqtt5.MqttConnectReasonCode.notSet) {
        return code;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }

  /// Extracts a reason code from mqtt5_client exception text when necessary.
  mqtt5.MqttConnectReasonCode? _reasonCodeFromText(Object error) {
    final match = RegExp(r'reason code is ([\w.]+)', caseSensitive: false).firstMatch(error.toString())?.group(1)?.split('.').last;
    if (match == null) return null;
    for (final code in mqtt5.MqttConnectReasonCode.values) {
      if (code.name == match) return code;
    }
    return null;
  }

  /// Adds a late broker reason code to raw diagnostics when absent.
  String _detailWithCode(Object error, mqtt5.MqttConnectReasonCode? code, bool recoveredLate) {
    final raw = error.toString().trim();
    if (!recoveredLate || code == null || raw.isEmpty || raw.contains(code.name)) {
      return raw;
    }
    return '$raw\nBroker CONNACK code: $code';
  }

  /// Returns a user-facing rejection message for [code].
  String? _connectReasonMessage(mqtt5.MqttConnectReasonCode? code) {
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
    return reason == null ? null : '$reason.\n$suggestion';
  }

  /// Maps an integer QoS to the mqtt5_client package enum.
  mqtt5.MqttQos _qos(int qos) => switch (qos) {
    1 => mqtt5.MqttQos.atLeastOnce,
    2 => mqtt5.MqttQos.exactlyOnce,
    _ => mqtt5.MqttQos.atMostOnce,
  };
}

/// Tracks one MQTT 5 publish awaiting a protocol acknowledgement.
class _PendingPublish {
  /// Creates pending publish state for [qos].
  _PendingPublish(this.qos);

  final int qos;
  final Completer<PublishResult> completer = Completer<PublishResult>();
  Timer? timer;
}
