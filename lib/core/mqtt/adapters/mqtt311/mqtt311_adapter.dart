import 'dart:async';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt3_server;

import '../../../../core/broker/models/broker_entry_model.dart';
import '../../../../core/mqtt/models/mqtt_protocol_version_model.dart';
import '../../connection_status.dart';
import '../../mqtt_connection_failure.dart';
import '../../mqtt_message.dart';
import '../../interfaces/mqtt_protocol_adapter_interface.dart';
import '../../mqtt_protocol_event.dart';
import '../../mqtt_reason.dart';
import '../../publish_result.dart';
import '../shared/mqtt_connection_error_mapper.dart';
import '../shared/mqtt_tls_configurator.dart';
import 'mqtt311_event_client.dart';

/// Creates the MQTT 3.1.1 package client used for [broker].
typedef Mqtt311ClientFactory = mqtt3_server.MqttServerClient Function(BrokerEntryModel broker);

const _socketTimeoutMs = 5000;
const _keepAliveSeconds = 10;
const _pingResponseTimeoutSeconds = 5;

/// Adapts the mqtt_client package to the application MQTT session contract.
class Mqtt311Adapter implements MqttProtocolAdapterInterface {
  /// Creates an MQTT 3.1.1 adapter for [broker].
  Mqtt311Adapter(this._broker, {MqttTlsConfigurator? tlsConfigurator, Mqtt311ClientFactory? clientFactory, Duration publishAckTimeout = const Duration(seconds: 5)})
    : _tlsConfigurator = tlsConfigurator ?? MqttTlsConfigurator(),
      _clientFactory = clientFactory ?? ((profile) => Mqtt311EventClient.withPort(profile.host, profile.effectiveClientId, profile.port, maxConnectionAttempts: 1)),
      _publishAckTimeout = publishAckTimeout;

  final BrokerEntryModel _broker;
  final MqttTlsConfigurator _tlsConfigurator;
  final Mqtt311ClientFactory _clientFactory;
  final Duration _publishAckTimeout;
  final StreamController<MqttProtocolEvent> _events = StreamController<MqttProtocolEvent>.broadcast();
  final StreamController<MQTTMessage> _messages = StreamController<MQTTMessage>.broadcast();
  final Map<int, _PendingPublish> _pendingPublishes = {};

  mqtt3_server.MqttServerClient? _client;
  StreamSubscription<List<mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>>>? _updatesSubscription;
  StreamSubscription<mqtt3.MqttPublishMessage>? _publishedSubscription;
  bool _disposed = false;
  bool _connectedOnce = false;

  /// Returns MQTT 3.1.1 as the implemented protocol.
  @override
  MqttProtocolVersionModel get protocolVersion => MqttProtocolVersionModel.v311;

  /// Returns lifecycle and diagnostic events.
  @override
  Stream<MqttProtocolEvent> get events => _events.stream;

  /// Returns decoded application messages.
  @override
  Stream<MQTTMessage> get messages => _messages.stream;

  /// Returns whether the mqtt_client package reports a connected state.
  @override
  bool get isConnected => _client?.connectionStatus?.state == mqtt3.MqttConnectionState.connected;

  /// Configures, connects, and subscribes the MQTT 3.1.1 client.
  @override
  Future<void> connect() async {
    final client = _clientFactory(_broker);
    _client = client;
    if (client is Mqtt311EventClient) client.onAutoReconnectFailure = _onAutoReconnectFailure;
    client.secure = _broker.useSSL || !_broker.clientCertificates.isEmpty;
    client.keepAlivePeriod = _keepAliveSeconds;
    client.disconnectOnNoResponsePeriod = _pingResponseTimeoutSeconds;
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
      var code = client.connectionStatus?.returnCode;
      if (code == null || code == mqtt3.MqttConnectReturnCode.noneSpecified) {
        code = _returnCodeFromText(error);
      }
      var recoveredLate = false;
      if (code == null || code == mqtt3.MqttConnectReturnCode.noneSpecified) {
        code = await _lateReturnCode(client.connectionStatus);
        recoveredLate = code != null;
      }
      throw MqttConnectionFailure(ConnectionStatus.error, _returnCodeMessage(code) ?? MqttConnectionErrorMapper.genericConnect(_broker), detail: _detailWithCode(error, code, recoveredLate));
    }

    if (_disposed) return;
    if (!isConnected) {
      throw MqttConnectionFailure(ConnectionStatus.error, _returnCodeMessage(client.connectionStatus?.returnCode) ?? MqttConnectionErrorMapper.brokerRejected(_broker));
    }

    _updatesSubscription = client.updates?.listen(_onUpdates, onError: _onClientStreamError);
    _publishedSubscription = client.published?.listen(_onPublished, onError: _onClientStreamError);
  }

  /// Publishes [payload] and maps MQTT 3.1.1 acknowledgements conservatively.
  @override
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) {
    final client = _client;
    if (client == null || !isConnected) return null;
    final builder = mqtt3.MqttClientPayloadBuilder()..addString(payload);
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

  /// Subscribes to [topic] through the connected MQTT 3.1.1 client.
  @override
  bool subscribe(String topic, {int qos = 0}) {
    final client = _client;
    if (client == null || !isConnected) return false;
    client.subscribe(topic, _qos(qos));
    return true;
  }

  /// Unsubscribes from [topic] through the connected MQTT 3.1.1 client.
  @override
  bool unsubscribe(String topic) {
    final client = _client;
    if (client == null || !isConnected) return false;
    client.unsubscribe(topic);
    return true;
  }

  /// Disconnects the package client and releases adapter-owned resources.
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _updatesSubscription?.cancel();
    await _publishedSubscription?.cancel();
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
    if (_disposed) return;
    _connectedOnce = true;
    _events.add(const MqttProtocolEvent.connected());
  }

  void _onAutoReconnect() {
    if (!_disposed) _events.add(const MqttProtocolEvent.disconnected(message: unexpectedBrokerDisconnectMessage));
  }

  void _onAutoReconnectFailure(Object error) {
    if (_disposed || !_connectedOnce) return;
    final failure = MqttConnectionErrorMapper.interrupted(error, _broker);
    _events.add(MqttProtocolEvent.failure(failure.status, failure.message, detail: failure.detail));
  }

  /// Converts asynchronous package-stream errors into visible session errors.
  void _onClientStreamError(Object error, [StackTrace? _]) {
    if (_disposed || !_connectedOnce) return;
    final failure = MqttConnectionErrorMapper.interrupted(error, _broker);
    _events.add(MqttProtocolEvent.failure(failure.status, failure.message, detail: failure.detail));
  }

  /// Emits the MQTT 3.1.1 broker-disconnect limitation.
  void _onDisconnected() {
    if (!_disposed) {
      _events.add(const MqttProtocolEvent.disconnected(message: mqtt311BrokerDisconnectMessage));
    }
  }

  /// Converts package update batches into application messages and notices.
  void _onUpdates(List<mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>> updates) {
    if (_disposed) return;
    for (final received in updates) {
      if (received.payload is! mqtt3.MqttPublishMessage) {
        _events.add(const MqttProtocolEvent.notice('Malformed MQTT packet received: expected PUBLISH payload.'));
        continue;
      }
      final publish = received.payload as mqtt3.MqttPublishMessage;
      _messages.add(MQTTMessage.fromPayloadBytes(topic: received.topic, payloadBytes: publish.payload.message, receivedAt: DateTime.now(), retain: publish.header?.retain ?? false, qos: publish.header?.qos.index ?? 0));
    }
  }

  /// Completes a pending publish when mqtt_client emits its PUBACK signal.
  void _onPublished(mqtt3.MqttPublishMessage message) {
    final packetId = message.variableHeader?.messageIdentifier;
    if (packetId == null) return;
    final pending = _pendingPublishes.remove(packetId);
    if (pending == null || pending.completer.isCompleted) return;
    pending.timer?.cancel();
    pending.completer.complete(PublishResult.unconfirmed(protocolVersion, pending.qos));
  }

  /// Maps an integer QoS to the mqtt_client package enum.
  mqtt3.MqttQos _qos(int qos) => switch (qos) {
    1 => mqtt3.MqttQos.atLeastOnce,
    2 => mqtt3.MqttQos.exactlyOnce,
    _ => mqtt3.MqttQos.atMostOnce,
  };

  /// Returns a user-facing rejection message for [code].
  String? _returnCodeMessage(mqtt3.MqttConnectReturnCode? code) {
    final (reason, suggestion) = switch (code) {
      mqtt3.MqttConnectReturnCode.unacceptedProtocolVersion => ('Unsupported protocol version', 'The broker does not support MQTT 3.1.1. Try switching to MQTT 5 in the broker settings.'),
      mqtt3.MqttConnectReturnCode.identifierRejected => ('Client identifier rejected', 'Use a different Client ID in the broker settings.'),
      mqtt3.MqttConnectReturnCode.brokerUnavailable => ('Broker unavailable', 'The broker is temporarily unavailable. Try again later.'),
      mqtt3.MqttConnectReturnCode.badUsernameOrPassword => ('Bad username or password', 'Check your username and password in the broker settings.'),
      mqtt3.MqttConnectReturnCode.notAuthorized => ('Not authorized', 'Check your credentials and confirm your account is permitted to connect.'),
      _ => (null, null),
    };
    return reason == null ? null : '$reason.\n$suggestion';
  }

  /// Polls briefly for a return code written after a failed connect future.
  Future<mqtt3.MqttConnectReturnCode?> _lateReturnCode(mqtt3.MqttClientConnectionStatus? status) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (_disposed || status == null) return null;
      final code = status.returnCode;
      if (code != null && code != mqtt3.MqttConnectReturnCode.noneSpecified) {
        return code;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }

  /// Extracts a return code from mqtt_client exception text when necessary.
  mqtt3.MqttConnectReturnCode? _returnCodeFromText(Object error) {
    final match = RegExp(r'return code is ([\w.]+)', caseSensitive: false).firstMatch(error.toString())?.group(1)?.split('.').last;
    if (match == null) return null;
    for (final code in mqtt3.MqttConnectReturnCode.values) {
      if (code.name == match) return code;
    }
    return null;
  }

  /// Adds a late broker return code to raw diagnostics when absent.
  String _detailWithCode(Object error, mqtt3.MqttConnectReturnCode? code, bool recoveredLate) {
    final raw = error.toString().trim();
    if (!recoveredLate || code == null || raw.isEmpty || raw.contains(code.name)) {
      return raw;
    }
    return '$raw\nBroker CONNACK code: $code';
  }
}

/// Tracks one MQTT 3.1.1 publish awaiting a package acknowledgement.
class _PendingPublish {
  /// Creates pending publish state for [qos].
  _PendingPublish(this.qos);

  final int qos;
  final Completer<PublishResult> completer = Completer<PublishResult>();
  Timer? timer;
}
