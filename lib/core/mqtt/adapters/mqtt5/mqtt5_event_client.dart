import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:event_bus/event_bus.dart' as events;
import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;
import 'package:mqtt5_client/mqtt5_server_client.dart' as mqtt5_server;

import '../shared/time_sliced_mqtt_socket_reader.dart';

/// Exposes MQTT 5 protocol events from within the package client subclass.
class Mqtt5EventClient extends mqtt5_server.MqttServerClient {
  /// Creates a client using the default MQTT port.
  Mqtt5EventClient(super.server, super.clientIdentifier, {super.maxConnectionAttempts});

  /// Creates a client using an explicit [port].
  Mqtt5EventClient.withPort(super.server, super.clientIdentifier, super.port, {super.maxConnectionAttempts}) : super.withPort();

  mqtt5.MqttConnectionStatus? _brokerDisconnectStatus;

  @override
  mqtt5.MqttConnectionStatus? get connectionStatus => connectionHandler == null && _brokerDisconnectStatus != null ? _brokerDisconnectStatus : super.connectionStatus;

  /// Connects through a packet-framing transport that cannot monopolize the
  /// UI isolate while a broker delivers a large retained-message burst.
  @override
  Future<mqtt5.MqttConnectionStatus?> connect([String? username, String? password]) async {
    _brokerDisconnectStatus = null;
    instantiationCorrect = true;
    clientEventBus = mqtt5.MqttEventBus.fromEventBus(events.EventBus());
    clientEventBus?.on<mqtt5.DisconnectOnNoPingResponse>().listen(disconnectOnNoPingResponse);
    connectionHandler = _TimeSlicedMqtt5ConnectionHandler(
      clientEventBus,
      maxConnectionAttempts: maxConnectionAttempts,
      socketOptions: socketOptions,
      socketTimeout: socketTimeout == null ? null : Duration(milliseconds: socketTimeout!),
    );
    if (useWebSocket) {
      connectionHandler.secure = false;
      connectionHandler.useWebSocket = true;
      connectionHandler.useAlternateWebSocketImplementation = useAlternateWebSocketImplementation;
      if (websocketProtocolString != null) {
        connectionHandler.websocketProtocols = websocketProtocolString;
      }
    }
    if (secure) {
      connectionHandler.secure = true;
      connectionHandler.useWebSocket = false;
      connectionHandler.useAlternateWebSocketImplementation = false;
      connectionHandler.securityContext = securityContext;
    }
    connectionHandler.onBadCertificate = onBadCertificate;
    return _connectClient(username, password);
  }

  // mqtt5_client creates and owns its handler inside connect(). This small
  // copy of protected setup is the stable seam for swapping the TCP receiver.
  // Keep it aligned with MqttClient.connect when upgrading the package.
  Future<mqtt5.MqttConnectionStatus?> _connectClient(String? username, String? password) async {
    checkCredentials(username, password);
    connectionMessage?.authenticateAs(username, password);
    if (websocketProtocolString != null) {
      connectionHandler.websocketProtocols = websocketProtocolString;
    }
    connectionHandler.onDisconnected = internalDisconnect;
    connectionHandler.onConnected = onConnected;
    connectionHandler.onAutoReconnect = onAutoReconnect;
    connectionHandler.onAutoReconnected = onAutoReconnected;
    connectionHandler.onFailedConnectionAttempt = onFailedConnectionAttempt;
    connectionHandler.registerForMessage(mqtt5.MqttMessageType.disconnect, _processDisconnect);
    publishingManager = mqtt5.MqttPublishingManager(connectionHandler, clientEventBus);
    authenticationManager ??= mqtt5.MqttAuthenticationManager();
    authenticationManager!.connectionHandler = connectionHandler;
    subscriptionsManager = mqtt5.MqttSubscriptionManager(connectionHandler, clientEventBus);
    subscriptionsManager!.onSubscribed = onSubscribed;
    subscriptionsManager!.onUnsubscribed = onUnsubscribed;
    subscriptionsManager!.onSubscribeFail = onSubscribeFail;
    subscriptionsManager!.resubscribeOnAutoReconnect = resubscribeOnAutoReconnect;
    if (keepAlivePeriod > mqtt5.MqttConstants.defaultKeepAlive) {
      keepAlive = mqtt5.MqttConnectionKeepAlive(connectionHandler, clientEventBus, keepAlivePeriod, disconnectOnNoResponsePeriod);
      if (pongCallback != null) keepAlive!.pongCallback = pongCallback;
    }
    final connectMessage = getConnectMessage(username, password);
    if (connectMessage.payload.clientIdentifier.isEmpty) {
      connectMessage.payload.clientIdentifier = clientIdentifier;
    }
    connectionMessage = connectMessage;
    return connectionHandler.connect(server, port, connectMessage);
  }

  bool _processDisconnect(mqtt5.MqttMessage message) {
    if (message is mqtt5.MqttDisconnectMessage) {
      _brokerDisconnectStatus = mqtt5.MqttConnectionStatus()
        ..state = mqtt5.MqttConnectionState.disconnected
        ..disconnectMessage = message
        ..disconnectionOrigin = mqtt5.MqttDisconnectionOrigin.brokerSolicited;
      final reconnect = autoReconnect;
      autoReconnect = false;
      internalDisconnect();
      autoReconnect = reconnect;
    }
    return true;
  }

  /// Returns decoded protocol events without external protected-member access.
  Stream<mqtt5.MqttMessageAvailable> get protocolEvents => clientEventBus?.on<mqtt5.MqttMessageAvailable>() ?? const Stream<mqtt5.MqttMessageAvailable>.empty();
}

class _TimeSlicedMqtt5ConnectionHandler extends mqtt5_server.MqttSynchronousServerConnectionHandler {
  _TimeSlicedMqtt5ConnectionHandler(super.clientEventBus, {required super.maxConnectionAttempts, required super.socketOptions, required super.socketTimeout});

  dynamic _connection;

  @override
  void connectAckReceived(mqtt5.MqttConnectAckMessageAvailable event) {
    final message = event.message;
    if (message is mqtt5.MqttConnectAckMessage) {
      connectionStatus.connectAckMessage = message;
    }
    super.connectAckReceived(event);
  }

  @override
  dynamic get connection => _connection;

  @override
  set connection(dynamic value) {
    if (value is mqtt5_server.MqttServerNormalConnection) {
      _connection = _TimeSlicedMqtt5ServerConnection(clientEventBus, socketOptions, socketTimeout);
      return;
    }
    if (value is mqtt5_server.MqttServerSecureConnection) {
      _connection = _TimeSlicedMqtt5ServerConnection(clientEventBus, socketOptions, socketTimeout, secure: true, securityContext: value.context, onBadCertificate: value.onBadCertificate);
      return;
    }
    _connection = value;
  }
}

class _TimeSlicedMqtt5ServerConnection extends mqtt5_server.MqttServerConnection {
  _TimeSlicedMqtt5ServerConnection(super.eventBus, super.socketOptions, super.socketTimeout, {this.secure = false, this.securityContext, this.onBadCertificate});

  final bool secure;
  final SecurityContext? securityContext;
  final bool Function(X509Certificate certificate)? onBadCertificate;
  TimeSlicedMqttSocketReader<mqtt5.MqttMessage>? _reader;

  @override
  Future<mqtt5.MqttConnectionStatus?> connect(String server, int port) => _open(server, port);

  @override
  Future<mqtt5.MqttConnectionStatus?> connectAuto(String server, int port) => _open(server, port);

  Future<mqtt5.MqttConnectionStatus?> _open(String server, int port) async {
    _reader?.dispose();
    final Socket socket;
    if (secure) {
      socket = await SecureSocket.connect(server, port, context: securityContext, onBadCertificate: onBadCertificate, timeout: socketTimeout);
    } else {
      socket = await Socket.connect(server, port, timeout: socketTimeout);
    }
    for (final option in socketOptions) {
      socket.setRawOption(option);
    }
    client = socket;
    _reader = TimeSlicedMqttSocketReader<mqtt5.MqttMessage>(input: socket, decodePacket: _decodePacket, onMessage: _emitMessage, onError: _onDecodeError, onDone: onDone, protocolLabel: 'MQTT 5');
    return null;
  }

  mqtt5.MqttMessage _decodePacket(Uint8List packet) {
    final message = mqtt5.MqttMessage.createFrom(mqtt5.MqttByteBuffer.fromList(packet));
    if (message == null) {
      throw const FormatException('MQTT 5 packet decoded to null.');
    }
    return message;
  }

  void _emitMessage(mqtt5.MqttMessage message) {
    final bus = clientEventBus;
    if (bus == null || bus.streamController.isClosed) return;
    if (message.header?.messageType == mqtt5.MqttMessageType.connectAck) {
      bus.fire(mqtt5.MqttConnectAckMessageAvailable(message));
    } else {
      bus.fire(mqtt5.MqttMessageAvailable(message));
    }
  }

  void _onDecodeError(Object error) => onError(error);

  @override
  void disconnect({bool auto = false}) {
    _disposeReader();
    super.disconnect(auto: auto);
  }

  @override
  void onError(dynamic error) {
    _disposeReader();
    super.onError(error);
  }

  @override
  void onDone() {
    _disposeReader();
    super.onDone();
  }

  void _disposeReader() {
    final reader = _reader;
    _reader = null;
    reader?.dispose();
    unawaited(reader?.subscription.cancel());
  }
}
