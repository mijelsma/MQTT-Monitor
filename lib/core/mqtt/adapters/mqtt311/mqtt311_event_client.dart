import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:event_bus/event_bus.dart' as events;
import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt3_server;

import '../shared/time_sliced_mqtt_socket_reader.dart';

/// MQTT 3.1.1 package client with a time-sliced desktop TCP/TLS receive path.
class Mqtt311EventClient extends mqtt3_server.MqttServerClient {
  Mqtt311EventClient(super.server, super.clientIdentifier, {super.maxConnectionAttempts});

  Mqtt311EventClient.withPort(super.server, super.clientIdentifier, super.port, {super.maxConnectionAttempts}) : super.withPort();

  /// Connects through a packet-framing transport that cannot monopolize the
  /// UI isolate while a broker delivers a large retained-message burst.
  @override
  Future<mqtt3.MqttClientConnectionStatus?> connect([String? username, String? password]) async {
    mqtt3.MqttClientEnvironment.isWebClient = false;
    instantiationCorrect = true;
    clientEventBus = mqtt3.MqttEventBus.fromEventBus(events.EventBus());
    clientEventBus?.on<mqtt3.DisconnectOnNoPingResponse>().listen(disconnectOnNoPingResponse);
    clientEventBus?.on<mqtt3.DisconnectOnNoMessageSent>().listen(disconnectOnNoMessageSent);
    final acknowledgementTimeoutMs = socketTimeout ?? connectTimeoutPeriod;
    final handler = _TimeSlicedMqtt311ConnectionHandler(
      clientEventBus,
      maxConnectionAttempts: maxConnectionAttempts,
      reconnectTimePeriod: acknowledgementTimeoutMs,
      socketOptions: socketOptions,
      socketTimeout: socketTimeout == null ? null : Duration(milliseconds: socketTimeout!),
    );
    if (useWebSocket) {
      handler.secure = false;
      handler.useWebSocket = true;
      handler.useAlternateWebSocketImplementation = useAlternateWebSocketImplementation;
      if (handler.useAlternateWebSocketImplementation) {
        handler.securityContext = securityContext;
      }
      if (websocketHeaders != null) {
        handler.websocketHeaders = websocketHeaders;
      }
    }
    if (secure) {
      handler.secure = true;
      handler.useWebSocket = false;
      handler.useAlternateWebSocketImplementation = false;
      handler.securityContext = securityContext;
    }
    handler.onBadCertificate = onBadCertificate as bool Function(Object certificate)?;
    connectionHandler = handler;
    return _connectClient(username, password);
  }

  // mqtt_client builds its concrete connection handler inside connect(), so
  // replacing only the TCP receiver requires mirroring this protected setup.
  // Keep this method aligned with MqttClient.connect when upgrading the package.
  Future<mqtt3.MqttClientConnectionStatus?> _connectClient(String? username, String? password) async {
    checkCredentials(username, password);
    connectionMessage?.authenticateAs(username, password);
    final handler = connectionHandler;
    if (handler == null) throw StateError('connectionHandler is null');
    if (websocketProtocolString != null) {
      handler.websocketProtocols = websocketProtocolString;
    }
    handler.onDisconnected = internalDisconnect;
    handler.onConnected = onConnected;
    handler.onAutoReconnect = onAutoReconnect;
    handler.onAutoReconnected = onAutoReconnected;
    handler.onFailedConnectionAttempt = onFailedConnectionAttempt;
    publishingManager = mqtt3.PublishingManager(handler, clientEventBus)..manuallyAcknowledgeQos1 = manuallyAcknowledgeQos1;
    subscriptionsManager = mqtt3.SubscriptionsManager(handler, publishingManager, clientEventBus);
    subscriptionsManager!.onSubscribed = onSubscribed;
    subscriptionsManager!.onUnsubscribed = onUnsubscribed;
    subscriptionsManager!.onSubscribeFail = onSubscribeFail;
    subscriptionsManager!.resubscribeOnAutoReconnect = resubscribeOnAutoReconnect;
    if (keepAlivePeriod != mqtt3.MqttClientConstants.defaultKeepAlive) {
      keepAlive = mqtt3.MqttConnectionKeepAlive(handler, clientEventBus, keepAlivePeriod, disconnectOnNoResponsePeriod);
      if (pongCallback != null) keepAlive!.pongCallback = pongCallback;
      if (pingCallback != null) keepAlive!.pingCallback = pingCallback;
    }
    final connectMessage = getConnectMessage(username, password);
    if (connectMessage.payload.clientIdentifier.isEmpty) {
      connectMessage.payload.clientIdentifier = clientIdentifier;
    }
    connectMessage.variableHeader?.keepAlive = keepAlivePeriod;
    connectionMessage = connectMessage;
    return handler.connect(server, port, connectMessage);
  }
}

class _TimeSlicedMqtt311ConnectionHandler extends mqtt3_server.SynchronousMqttServerConnectionHandler {
  _TimeSlicedMqtt311ConnectionHandler(super.clientEventBus, {required super.maxConnectionAttempts, required super.reconnectTimePeriod, required super.socketOptions, required super.socketTimeout});

  late mqtt3.MqttConnectionBase<Object> _connection;

  @override
  mqtt3.MqttConnectionBase<Object> get connection => _connection;

  @override
  set connection(dynamic value) {
    if (value is mqtt3_server.MqttServerNormalConnection) {
      _connection = _TimeSlicedMqtt311NormalConnection(clientEventBus, socketOptions, socketTimeout);
      return;
    }
    if (value is mqtt3_server.MqttServerSecureConnection) {
      _connection = _TimeSlicedMqtt311SecureConnection(value.context, clientEventBus, value.onBadCertificate, socketOptions, socketTimeout);
      return;
    }
    _connection = value;
  }
}

mixin _TimeSlicedMqtt311Input<T extends Object> on mqtt3_server.MqttServerConnection<T> {
  TimeSlicedMqttSocketReader<mqtt3.MqttMessage>? _reader;

  @override
  StreamSubscription<Uint8List> onListen() {
    final socket = client;
    if (socket is! Stream<Uint8List>) throw StateError('socket is null');
    _reader?.dispose();
    final reader = TimeSlicedMqttSocketReader<mqtt3.MqttMessage>(input: socket, decodePacket: (packet) => mqtt3.MqttMessage.createFrom(mqtt3.MqttByteBuffer.fromList(packet)), onMessage: _emitMessage, onError: _onDecodeError, onDone: onDone, protocolLabel: 'MQTT 3.1.1');
    _reader = reader;
    return reader.subscription;
  }

  void _emitMessage(mqtt3.MqttMessage message) {
    final bus = clientEventBus;
    if (message.header?.messageType == mqtt3.MqttMessageType.connectAck) {
      bus?.fire(mqtt3.ConnectAckMessageAvailable(message));
    } else {
      bus?.fire(mqtt3.MessageAvailable(message));
    }
  }

  void _onDecodeError(Object error) => onError(error);

  @override
  void stopListening() {
    _disposeDecoder();
    super.stopListening();
  }

  @override
  void onError(dynamic error) {
    _disposeDecoder();
    super.onError(error);
  }

  @override
  void onDone() {
    _disposeDecoder();
    super.onDone();
  }

  void _disposeDecoder() {
    _reader?.dispose();
    _reader = null;
  }
}

class _TimeSlicedMqtt311NormalConnection extends mqtt3_server.MqttServerNormalConnection with _TimeSlicedMqtt311Input<Socket> {
  _TimeSlicedMqtt311NormalConnection(super.eventBus, super.socketOptions, super.socketTimeout);
}

class _TimeSlicedMqtt311SecureConnection extends mqtt3_server.MqttServerSecureConnection with _TimeSlicedMqtt311Input<SecureSocket> {
  _TimeSlicedMqtt311SecureConnection(super.context, super.eventBus, super.onBadCertificate, super.socketOptions, super.socketTimeout);
}
