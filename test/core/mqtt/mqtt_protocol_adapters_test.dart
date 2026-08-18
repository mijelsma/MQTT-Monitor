import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart' as events;
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;
import 'package:mqtt_monitor/core/mqtt/connection_status.dart';
import 'package:mqtt_monitor/core/mqtt/adapters/mqtt311/mqtt311_adapter.dart';
import 'package:mqtt_monitor/core/mqtt/adapters/mqtt311/mqtt311_event_client.dart';
import 'package:mqtt_monitor/core/mqtt/adapters/mqtt5/mqtt5_adapter.dart';
import 'package:mqtt_monitor/core/mqtt/adapters/mqtt5/mqtt5_event_client.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_reason.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_connection_intent_store.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_session_controller.dart';
import 'package:mqtt_monitor/core/broker/repositories/broker_repository.dart';
import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;
import 'package:mqtt_monitor/core/mqtt/publish_result.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/mqtt_protocol_version_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';

import '../../support/test_dependencies.dart';

/// Simulates the mqtt_client API used by the MQTT 3.1.1 adapter.
class _FakeMqtt3Client extends Mqtt311EventClient {
  /// Creates a disconnected fake package client.
  _FakeMqtt3Client() : super('unused', 'test-client');

  final status = mqtt3.MqttClientConnectionStatus();
  final updatesController = StreamController<List<mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>>>.broadcast();
  final publishedController = StreamController<mqtt3.MqttPublishMessage>.broadcast();
  final subscriptions = <({String topic, mqtt3.MqttQos qos})>[];
  final unsubscriptions = <String>[];
  final publications = <({String topic, mqtt3.MqttQos qos, String payload, bool retain})>[];

  /// When non-null, the next QoS 1/2 publish's `published` event is
  /// delayed by this duration, so tests can simulate an in-flight state.
  Duration? ackDelay;

  /// When true, never emit `published` for QoS 1/2 publishes so the
  /// publish times out from the caller's perspective.
  bool suppressAcks = false;

  /// When true (default), every published message is also delivered back
  /// through the `updates` stream, mirroring the way a real broker
  /// echoes messages to a subscriber on the same topic. Tests that
  /// simulate ACL filtering set this to false.
  bool echoesToSubscriber = true;
  int connectCalls = 0;
  int disconnectCalls = 0;
  String? connectedUsername;
  String? connectedPassword;

  /// Returns the mutable package connection status.
  @override
  mqtt3.MqttClientConnectionStatus get connectionStatus => status;

  /// Returns received MQTT package messages.
  @override
  Stream<List<mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>>> get updates => updatesController.stream;

  /// Returns MQTT 3.1.1 publish acknowledgement signals.
  @override
  Stream<mqtt3.MqttPublishMessage>? get published => publishedController.stream;

  /// Records credentials and completes a successful connection.
  @override
  Future<mqtt3.MqttClientConnectionStatus?> connect([String? username, String? password]) async {
    connectCalls++;
    connectedUsername = username;
    connectedPassword = password;
    status.state = mqtt3.MqttConnectionState.connected;
    onConnected?.call();
    return status;
  }

  /// Records a subscription request.
  @override
  mqtt3.Subscription? subscribe(String topic, mqtt3.MqttQos qosLevel) {
    subscriptions.add((topic: topic, qos: qosLevel));
    return null;
  }

  /// Records an unsubscription request.
  @override
  void unsubscribe(String topic, {expectAcknowledge = false}) {
    unsubscriptions.add(topic);
  }

  /// Records a publish and optionally emits its acknowledgement and echo.
  @override
  int publishMessage(String topic, mqtt3.MqttQos qualityOfService, dynamic data, {bool retain = false}) {
    final bytes = Uint8Buffer()..addAll(List<int>.from(data));
    final packetId = publications.length + 1;
    publications.add((topic: topic, qos: qualityOfService, payload: utf8.decode(bytes), retain: retain));
    if (!suppressAcks && (qualityOfService == mqtt3.MqttQos.atLeastOnce || qualityOfService == mqtt3.MqttQos.exactlyOnce)) {
      final ackMessage = mqtt3.MqttPublishMessage().toTopic(topic).withQos(qualityOfService).withMessageIdentifier(packetId).publishData(bytes);
      if (ackDelay == null) {
        publishedController.add(ackMessage);
      } else {
        Timer(ackDelay!, () => publishedController.add(ackMessage));
      }
    }
    // Simulate a real broker: deliver the published message back to the
    // Echo the published message back through the updates stream so any
    // subscriber on the same topic (including the publisher) sees it,
    // mirroring a real broker.
    if (echoesToSubscriber) {
      addPublish(topic, bytes, qos: qualityOfService.index, retain: retain);
    }
    return packetId;
  }

  /// Records package-client disconnection.
  @override
  void disconnect() {
    disconnectCalls++;
    status.state = mqtt3.MqttConnectionState.disconnected;
  }

  /// Simulates a connection closed by the broker.
  void brokerDisconnect() {
    status.state = mqtt3.MqttConnectionState.disconnected;
    onDisconnected?.call();
  }

  /// Simulates mqtt_client beginning an automatic reconnect cycle.
  void beginAutoReconnect() {
    status.state = mqtt3.MqttConnectionState.disconnected;
    onAutoReconnect?.call();
  }

  /// Simulates mqtt_client completing an automatic reconnect cycle.
  void finishAutoReconnect() {
    status.state = mqtt3.MqttConnectionState.connected;
    onAutoReconnected?.call();
  }

  void failAutoReconnect(Object error) => onAutoReconnectFailure?.call(error);

  void failUpdates(Object error) => updatesController.addError(error);

  /// Emits an update with a non-PUBLISH MQTT packet.
  void addMalformedUpdate() {
    updatesController.add([mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>('invalid', mqtt3.MqttConnectMessage())]);
  }

  /// Emits a received publish with [bytes] as its payload.
  void addPublish(String topic, List<int> bytes, {int qos = 0, bool retain = false}) {
    final builder = mqtt3.MqttClientPayloadBuilder();
    for (final byte in bytes) {
      builder.addByte(byte);
    }
    final message = mqtt3.MqttPublishMessage()
        .toTopic(topic)
        .withQos(switch (qos) {
          1 => mqtt3.MqttQos.atLeastOnce,
          2 => mqtt3.MqttQos.exactlyOnce,
          _ => mqtt3.MqttQos.atMostOnce,
        })
        .publishData(builder.payload!);
    message.setRetain(state: retain);
    updatesController.add([mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>(topic, message)]);
  }

  /// Closes fake-owned stream controllers.
  Future<void> close() async {
    await updatesController.close();
    await publishedController.close();
  }
}

/// A re-export of the event_bus package's [EventBus] so the fake MQTT 5
/// client can construct one without depending on the package directly.
typedef _EventBus = events.EventBus;

/// A minimal MQTT 5 fake that supports the event-bus packet flow the
/// adapter uses to match PUBACK/PUBREC back to pending publishes.
class _FakeMqtt5Client extends Mqtt5EventClient {
  /// Creates a disconnected fake package client.
  _FakeMqtt5Client() : super('unused', 'test-client');

  final status = mqtt5.MqttConnectionStatus();
  final updatesController = StreamController<List<mqtt5.MqttReceivedMessage<mqtt5.MqttMessage>>>.broadcast();
  // ignore: invalid_use_of_protected_member
  final eventBus = mqtt5.MqttEventBus.fromEventBus(_EventBus());
  final subscriptions = <({String topic, mqtt5.MqttQos qos})>[];
  final publications = <({String topic, mqtt5.MqttQos qos, String payload, bool retain})>[];
  mqtt5.MqttConnectReasonCode? nextConnackReason = mqtt5.MqttConnectReasonCode.success;

  /// When a publish arrives, the reason code we will respond with in the
  /// PUBACK. `null` means no PUBACK is sent (timed out from caller's view).
  mqtt5.MqttPublishReasonCode? nextPubackReason = mqtt5.MqttPublishReasonCode.success;

  /// When true, `connect()` returns without ever setting
  /// [MqttConnectionState.connected] or filling in a CONNACK. This mirrors
  /// the way a 3.1.1-only Mosquitto just drops the socket on a MQTT 5
  /// CONNECT packet. Used to test the timeout-driven auto-fallback.
  bool neverConnacks = false;
  int connectCalls = 0;
  int disconnectCalls = 0;
  String? connectedUsername;
  String? connectedPassword;

  /// Returns the mutable package connection status.
  @override
  mqtt5.MqttConnectionStatus get connectionStatus => status;

  /// Returns received MQTT package messages.
  @override
  // ignore: invalid_use_of_protected_member
  Stream<List<mqtt5.MqttReceivedMessage<mqtt5.MqttMessage>>>? get updates => updatesController.stream;

  /// Returns the fake protocol event stream consumed by the MQTT 5 adapter.
  /// Records credentials and returns the configured CONNACK outcome.
  @override
  Stream<mqtt5.MqttMessageAvailable> get protocolEvents => eventBus.on<mqtt5.MqttMessageAvailable>();

  /// Records a subscription request.
  @override
  Future<mqtt5.MqttConnectionStatus?> connect([String? username, String? password]) async {
    connectCalls++;
    connectedUsername = username;
    connectedPassword = password;
    if (neverConnacks) {
      // Simulate a broker that just dropped the socket without ever
      // sending a CONNACK. The state stays in "disconnected" and no
      // connectAckMessage is set.
      status.state = mqtt5.MqttConnectionState.disconnected;
      return status;
    }
    // `withReasonCode` returns the reason code, not the message; build the
    // message separately and set the variable header's reason code.
    final msg = mqtt5.MqttConnectAckMessage()..variableHeader?.reasonCode = nextConnackReason ?? mqtt5.MqttConnectReasonCode.success;
    status.connectAckMessage = msg;
    // Real mqtt5 client never transitions to "connected" when CONNACK
    // returns a non-success reason code. Mirror that here.
    if (nextConnackReason == null || nextConnackReason == mqtt5.MqttConnectReasonCode.success) {
      status.state = mqtt5.MqttConnectionState.connected;
      onConnected?.call();
    } else {
      status.state = mqtt5.MqttConnectionState.disconnected;
    }
    return status;
  }

  /// Accepts an unsubscription request without recording it.
  @override
  mqtt5.MqttSubscription? subscribe(String topic, mqtt5.MqttQos qosLevel) {
    subscriptions.add((topic: topic, qos: qosLevel));
    return null;
  }

  /// Records a publish and optionally emits an MQTT 5 acknowledgement.
  @override
  void unsubscribeStringTopic(String topic) {}

  /// Records package-client disconnection.
  @override
  int publishMessage(String topic, mqtt5.MqttQos qualityOfService, dynamic data, {bool retain = false, List<mqtt5.MqttUserProperty>? userProperties}) {
    final packetId = publications.length + 1;
    publications.add((topic: topic, qos: qualityOfService, payload: utf8.decode(List<int>.from(data)), retain: retain));
    final reason = nextPubackReason;
    if (reason != null && (qualityOfService == mqtt5.MqttQos.atLeastOnce || qualityOfService == mqtt5.MqttQos.exactlyOnce)) {
      final ack = mqtt5.MqttPublishAckMessage().withMessageIdentifier(packetId).withReasonCode(reason);
      // ignore: invalid_use_of_protected_member
      eventBus.fire(mqtt5.MqttMessageAvailable(ack));
    }
    return packetId;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    status.state = mqtt5.MqttConnectionState.disconnected;
  }

  /// Simulates mqtt5_client beginning an automatic reconnect cycle.
  void beginAutoReconnect() {
    status.state = mqtt5.MqttConnectionState.disconnected;
    onAutoReconnect?.call();
  }

  /// Simulates mqtt5_client completing an automatic reconnect cycle.
  void finishAutoReconnect() {
    status.state = mqtt5.MqttConnectionState.connected;
    onAutoReconnected?.call();
  }

  void failAutoReconnect(Object error) => onAutoReconnectFailure?.call(error);

  void failUpdates(Object error) => updatesController.addError(error);

  void transportDisconnect() {
    status.state = mqtt5.MqttConnectionState.disconnected;
    onDisconnected?.call();
  }

  void brokerDisconnect(mqtt5.MqttDisconnectReasonCode reasonCode, {String? reasonString}) {
    var message = mqtt5.MqttDisconnectMessage().withReasonCode(reasonCode);
    if (reasonString != null) message = message.withReasonString(reasonString);
    status
      ..state = mqtt5.MqttConnectionState.disconnected
      ..disconnectMessage = message
      ..disconnectionOrigin = mqtt5.MqttDisconnectionOrigin.brokerSolicited;
    onDisconnected?.call();
  }

  /// Emits a received publish with [bytes] as its payload.
  void addPublish(String topic, List<int> bytes, {int qos = 0, bool retain = false}) {
    final builder = mqtt5.MqttPayloadBuilder();
    for (final byte in bytes) {
      builder.addByte(byte);
    }
    final message = mqtt5.MqttPublishMessage()
        .toTopic(topic)
        .withQos(switch (qos) {
          1 => mqtt5.MqttQos.atLeastOnce,
          2 => mqtt5.MqttQos.exactlyOnce,
          _ => mqtt5.MqttQos.atMostOnce,
        })
        .withMessageIdentifier(publications.length + 1000)
        .publishData(builder.payload!);
    message.setRetain(state: retain);
    updatesController.add([mqtt5.MqttReceivedMessage<mqtt5.MqttMessage>(topic, message)]);
  }

  /// Closes fake-owned stream controllers.
  Future<void> close() async {
    await updatesController.close();
  }
}

void main() {
  test('wire payloads consistently retain decoded text and original bytes', () {
    final valid = MQTTMessage.fromPayloadBytes(topic: 'valid', payloadBytes: utf8.encode('héllo'), receivedAt: DateTime(2026));
    final malformed = MQTTMessage.fromPayloadBytes(topic: 'invalid', payloadBytes: [0xFF, 0x61], receivedAt: DateTime(2026));

    expect(valid.payload, 'héllo');
    expect(valid.payloadBytes, utf8.encode('héllo'));
    expect(valid.payloadByteLength, 6);
    expect(malformed.payload, '\uFFFDa');
    expect(malformed.payloadBytes, [0xFF, 0x61]);
    expect(malformed.payloadByteLength, 2);
  });

  late BrokerRepository brokers;
  late MqttConnectionIntentStore intents;
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
    intents = MqttConnectionIntentStore(dependencies.preferences);
  });

  /// Creates a session using real adapters around optional fake clients.
  MqttSessionController createSession({Mqtt311ClientFactory? mqtt311ClientFactory, Mqtt5ClientFactory? mqtt5ClientFactory}) {
    return MqttSessionController(
      dependencies.connectionPreferences,
      brokers,
      intents,
      logger: dependencies.logger,
      adapterFactory: (broker) => switch (broker.protocolVersion) {
        MqttProtocolVersionModel.v311 => Mqtt311Adapter(broker, clientFactory: mqtt311ClientFactory),
        MqttProtocolVersionModel.v5 => Mqtt5Adapter(broker, clientFactory: mqtt5ClientFactory),
      },
    );
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('connects, subscribes, publishes each QoS, and unsubscribes with a fake client', () async {
    const broker = BrokerEntryModel(
      id: 'broker-1',
      name: 'Test',
      host: 'broker.invalid',
      username: 'user',
      password: 'secret',
      subscriptions: [
        SubscriptionEntryModel(id: 'sensors', topic: 'sensors/+', qos: 1),
        SubscriptionEntryModel(id: 'alerts', topic: 'alerts/#', qos: 2),
      ],
    );
    final fake = _FakeMqtt3Client();
    await brokers.add(broker);
    final service = createSession(mqtt311ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);

    service.initialize();
    await settle();

    expect(fake.connectCalls, 1);
    expect(fake.connectedUsername, 'user');
    expect(fake.connectedPassword, 'secret');
    expect(fake.keepAlivePeriod, 10);
    expect(fake.disconnectOnNoResponsePeriod, 5);
    expect(fake.subscriptions, [(topic: 'sensors/+', qos: mqtt3.MqttQos.atLeastOnce), (topic: 'alerts/#', qos: mqtt3.MqttQos.exactlyOnce)]);
    expect(service.connectionStatus, ConnectionStatus.connected);

    // Each publish returns a Future<PublishResult>?; null means the
    // local client rejected the call. Under MQTT 3.1.1 any successful
    // publish resolves to `noConfirmation` because the protocol cannot
    // distinguish success from a silently ACL-dropped message.
    final futures = [service.publish('out/0', 'zero', qos: 0), service.publish('out/1', 'one', qos: 1, retain: true), service.publish('out/2', 'two', qos: 2)];
    for (final future in futures) {
      expect(future, isNotNull);
    }
    final results = await Future.wait(futures.cast<Future>());
    for (final result in results) {
      expect(result.kind, PublishResultKind.noConfirmation, reason: 'MQTT 3.1.1 can never report a real delivery, even at QoS 1/2');
    }
    expect(fake.publications.map((value) => value.qos), [mqtt3.MqttQos.atMostOnce, mqtt3.MqttQos.atLeastOnce, mqtt3.MqttQos.exactlyOnce]);
    expect(fake.publications[1].retain, isTrue);

    await brokers.update(
      brokers.brokers.single.copyWith(
        subscriptions: const [
          SubscriptionEntryModel(id: 'sensors', topic: 'sensors/+', qos: 1),
          SubscriptionEntryModel(id: 'alerts', topic: 'alerts/#', qos: 2),
          SubscriptionEntryModel(id: 'dynamic', topic: 'dynamic/topic', qos: 2),
        ],
      ),
    );
    await settle();
    await brokers.update(
      brokers.brokers.single.copyWith(
        subscriptions: const [
          SubscriptionEntryModel(id: 'sensors', topic: 'sensors/+', qos: 1),
          SubscriptionEntryModel(id: 'alerts', topic: 'alerts/#', qos: 2),
        ],
      ),
    );
    await settle();
    expect(fake.subscriptions.last, (topic: 'dynamic/topic', qos: mqtt3.MqttQos.exactlyOnce));
    expect(fake.unsubscriptions, ['dynamic/topic']);
  });

  test('disconnect and reconnect replace the active session', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid');
    final clients = <_FakeMqtt3Client>[];
    await brokers.add(broker);
    final service = createSession(
      mqtt311ClientFactory: (_) {
        final client = _FakeMqtt3Client();
        clients.add(client);
        return client;
      },
    );
    addTearDown(service.dispose);
    addTearDown(() async {
      for (final client in clients) {
        await client.close();
      }
    });

    service.initialize();
    await settle();
    service.disconnect();
    await settle();

    expect(clients.single.disconnectCalls, 1);
    expect(service.connectionStatus, ConnectionStatus.disconnected);
    expect(service.publish('offline', 'ignored'), isNull);

    service.reconnect();
    await settle();

    expect(clients, hasLength(2));
    expect(clients.last.connectCalls, 1);
    expect(service.connectionStatus, ConnectionStatus.connected);
  });

  test('editing a profile reconnects and applies its new subscriptions', () async {
    const broker = BrokerEntryModel(id: 'same-id', name: 'Test', host: 'first.invalid');
    final clients = <_FakeMqtt3Client>[];
    await brokers.add(broker);
    final service = createSession(
      mqtt311ClientFactory: (_) {
        final client = _FakeMqtt3Client();
        clients.add(client);
        return client;
      },
    );
    addTearDown(service.dispose);
    addTearDown(() async {
      for (final client in clients) {
        await client.close();
      }
    });
    service.initialize();
    await settle();

    await brokers.update(
      broker.copyWith(
        host: 'second.invalid',
        subscriptions: const [SubscriptionEntryModel(id: 'new', topic: 'new/#', qos: 1)],
      ),
    );
    await settle();

    expect(clients, hasLength(2));
    expect(clients.first.disconnectCalls, 1);
    expect(clients.last.subscriptions, [(topic: 'new/#', qos: mqtt3.MqttQos.atLeastOnce)]);
  });

  test('broker disconnect explains MQTT 3.1.1 limitation', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid');
    final fake = _FakeMqtt3Client();
    await brokers.add(broker);
    final service = createSession(mqtt311ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.brokerDisconnect();
    await settle();

    expect(service.connectionStatus, ConnectionStatus.disconnected);
    expect(service.connectionError, mqtt311BrokerDisconnectMessage);
  });

  test('MQTT 3.1.1 auto-reconnect immediately surfaces the lost connection', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid');
    final fake = _FakeMqtt3Client();
    await brokers.add(broker);
    final service = createSession(mqtt311ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    expect(fake.keepAlivePeriod, 10);
    expect(fake.disconnectOnNoResponsePeriod, 5);

    fake.beginAutoReconnect();
    await settle();
    expect(service.connectionStatus, ConnectionStatus.disconnected);
    expect(service.connectionError, unexpectedBrokerDisconnectMessage);

    fake.finishAutoReconnect();
    await settle();
    expect(service.connectionStatus, ConnectionStatus.connected);
    expect(service.connectionError, isNull);
  });

  test('MQTT 3.1.1 auto-reconnect socket failures become visible session errors', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid');
    final fake = _FakeMqtt3Client();
    await brokers.add(broker);
    final service = createSession(mqtt311ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.beginAutoReconnect();
    fake.failAutoReconnect(const SocketException('Operation timed out'));
    await settle();

    expect(service.connectionStatus, ConnectionStatus.error);
    expect(service.connectionError, contains('Network error reaching the broker'));
    expect(service.connectionErrorDetail, contains('Operation timed out'));
  });

  test('MQTT 5 auto-reconnect surfaces loss and clears it after reconnecting', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
    final fake = _FakeMqtt5Client();
    await brokers.add(broker);
    final service = createSession(mqtt5ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    expect(fake.keepAlivePeriod, 10);
    expect(fake.disconnectOnNoResponsePeriod, 5);

    fake.beginAutoReconnect();
    await settle();
    expect(service.connectionStatus, ConnectionStatus.disconnected);
    expect(service.connectionError, unexpectedBrokerDisconnectMessage);

    fake.finishAutoReconnect();
    await settle();
    expect(service.connectionStatus, ConnectionStatus.connected);
    expect(service.connectionError, isNull);
  });

  test('MQTT 5 auto-reconnect socket failures become visible session errors', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
    final fake = _FakeMqtt5Client();
    await brokers.add(broker);
    final service = createSession(mqtt5ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.beginAutoReconnect();
    fake.failAutoReconnect(const SocketException('Operation timed out'));
    await settle();

    expect(service.connectionStatus, ConnectionStatus.error);
    expect(service.connectionError, contains('Network error reaching the broker'));
    expect(service.connectionErrorDetail, contains('Operation timed out'));
  });

  test('non-socket reconnect failures are also mapped into visible errors', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid');
    final fake = _FakeMqtt3Client();
    await brokers.add(broker);
    final service = createSession(mqtt311ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.beginAutoReconnect();
    fake.failAutoReconnect(TimeoutException('Reconnect timed out'));
    await settle();

    expect(service.connectionStatus, ConnectionStatus.error);
    expect(service.connectionError, contains('connection to the broker timed out'));
    expect(service.connectionErrorDetail, contains('Reconnect timed out'));
  });

  test('errors from MQTT client streams cannot remain unhandled or connected', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
    final fake = _FakeMqtt5Client();
    await brokers.add(broker);
    final service = createSession(mqtt5ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.failUpdates(const FormatException('Invalid remaining length'));
    await settle();

    expect(service.connectionStatus, ConnectionStatus.error);
    expect(service.connectionError, contains('invalid MQTT data'));
    expect(service.connectionErrorDetail, contains('Invalid remaining length'));
  });

  test('MQTT 5 transport closure without a DISCONNECT packet is visible', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
    final fake = _FakeMqtt5Client();
    await brokers.add(broker);
    final service = createSession(mqtt5ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.transportDisconnect();
    await settle();

    expect(service.connectionStatus, ConnectionStatus.disconnected);
    expect(service.connectionError, unexpectedBrokerDisconnectMessage);
  });

  test('MQTT 5 broker DISCONNECT preserves its reason and reason string', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
    final fake = _FakeMqtt5Client();
    await brokers.add(broker);
    final service = createSession(mqtt5ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.brokerDisconnect(mqtt5.MqttDisconnectReasonCode.keepAliveTimeout, reasonString: 'Idle connection expired');
    await settle();

    expect(service.connectionStatus, ConnectionStatus.disconnected);
    expect(service.connectionError, 'DISCONNECT: Idle connection expired');
    expect(service.connectionErrorDetail, 'Idle connection expired');
  });

  test('malformed updates are reported and invalid UTF-8 is decoded safely', () async {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid');
    final fake = _FakeMqtt3Client();
    await brokers.add(broker);
    final service = createSession(mqtt311ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.addMalformedUpdate();
    await settle();
    expect(service.connectionError, contains('Malformed MQTT packet'));

    final nextMessage = service.messageStream.first;
    fake.addPublish('binary/value', [0xff, 0x61], qos: 1, retain: true);
    final message = await nextMessage;

    expect(message.topic, 'binary/value');
    expect(message.payload, '\uFFFDa');
    expect(message.qos, 1);
    expect(message.retain, isTrue);
  });

  group('honest publish feedback', () {
    test('MQTT 5 QoS 1 PUBACK with reason 0 resolves to delivered (green path)', () async {
      const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
      final fake = _FakeMqtt5Client();
      await brokers.add(broker);
      final service = createSession(mqtt5ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);

      service.initialize();
      await settle();
      expect(service.activeProtocol, MqttProtocolVersionModel.v5);

      fake.nextPubackReason = mqtt5.MqttPublishReasonCode.success;
      final result = await service.publish('test/hello', 'hi', qos: 1)!;
      expect(result, isA<PublishResult>());
      expect(result.kind, PublishResultKind.delivered, reason: 'MQTT 5 PUBACK with reason 0 means a real success.');
      expect(result.reasonCode, 0);
    });

    test('MQTT 5 QoS 1 PUBACK with reason 0x87 (Not authorized) resolves to failed with parsed reason', () async {
      const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
      final fake = _FakeMqtt5Client();
      await brokers.add(broker);
      final service = createSession(mqtt5ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);

      service.initialize();
      await settle();

      fake.nextPubackReason = mqtt5.MqttPublishReasonCode.notAuthorized;
      final result = await service.publish('forbidden/topic', 'oops', qos: 1)!;
      expect(result.kind, PublishResultKind.failed);
      expect(result.reasonCode, 0x87);
      expect(result.reason, contains('Not authorized'));
      expect(
        result.reason,
        contains('135'),
        reason:
            'Reason code is shown alongside the label so the user '
            'can map it back to a broker log.',
      );
    });

    test('MQTT 5 QoS 2 PUBREC with Quota Exceeded resolves to failed with parsed reason', () async {
      const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
      final fake = _FakeMqtt5Client();
      await brokers.add(broker);
      final service = createSession(mqtt5ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);

      service.initialize();
      await settle();

      fake.nextPubackReason = mqtt5.MqttPublishReasonCode.quotaExceeded;
      final result = await service.publish('limited/topic', 'oops', qos: 2)!;
      expect(result.kind, PublishResultKind.failed);
      expect(result.reasonCode, 0x97);
      expect(result.reason, contains('Quota exceeded'));
    });

    test('MQTT 5 QoS 0 resolves immediately to noConfirmation (no ack possible)', () async {
      const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
      final fake = _FakeMqtt5Client();
      await brokers.add(broker);
      final service = createSession(mqtt5ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);

      service.initialize();
      await settle();

      final result = await service.publish('test/zero', 'hi', qos: 0)!;
      expect(result, isA<PublishResult>());
      expect(
        result.kind,
        PublishResultKind.noConfirmation,
        reason:
            'QoS 0 is fire-and-forget, so the UI must never show '
            'a confident green check.',
      );
    });

    test('MQTT 3.1.1 QoS 1 with successful PUBACK still resolves to noConfirmation (3.1.1 cannot tell)', () async {
      const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid');
      final fake = _FakeMqtt3Client();
      await brokers.add(broker);
      final service = createSession(mqtt311ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);

      service.initialize();
      await settle();

      final result = await service.publish('forbidden/topic', 'oops', qos: 1)!;
      expect(
        result.kind,
        PublishResultKind.noConfirmation,
        reason:
            'MQTT 3.1.1 PUBACK carries no failure reason; even on '
            'success we must not claim a confident delivery.',
      );
      expect(result.reason, contains('MQTT 3.1.1'));
    });

    test('publish times out when no PUBACK arrives and resolves to timedOut', () async {
      const broker = BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid', protocolVersion: MqttProtocolVersionModel.v5);
      final fake = _FakeMqtt5Client();
      await brokers.add(broker);
      final service = createSession(mqtt5ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);

      service.initialize();
      await settle();

      // Suppress PUBACK so the future times out. A 5s timeout is
      // baked into the service, so we use a short test wrapper:
      fake.nextPubackReason = null;
      final result = await service.publish('test/timeout', 'hi', qos: 1)!.timeout(const Duration(seconds: 8), onTimeout: () => PublishResult.timedOut(MqttProtocolVersionModel.v5, 1));
      expect(result.kind, PublishResultKind.timedOut);
    });

    test('publish returns null when the local client is not connected', () async {
      await brokers.add(const BrokerEntryModel(id: 'broker-1', name: 'Test', host: 'broker.invalid'));
      final service = createSession(mqtt311ClientFactory: (_) => _FakeMqtt3Client());
      addTearDown(service.dispose);
      service.initialize();
      await settle();
      service.disconnect();
      await settle();

      expect(service.publish('offline', 'ignored'), isNull);
    });
  });

  group('real TCP broker integration', () {
    /// Starts a minimal broker that answers every MQTT 5 CONNECT with a
    /// CONNACK reason code 0x86 (badUsernameOrPassword) and counts the
    /// CONNECT packets it receives. Returns the broker to connect to and
    /// the running count of accepted connect attempts.
    Future<(BrokerEntryModel, List<bool>)> startRejectingBroker() async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final connectPackets = <bool>[];
      addTearDown(() async {
        // Only the listener is closed, never the accepted sockets: killing
        // the client's live connection makes mqtt5_client (autoReconnect is
        // on) loop reconnect attempts against the closed port, leaking
        // async work out of the test.
        await server.close();
      });
      unawaited(() async {
        await for (final socket in server) {
          connectPackets.add(true);
          // Give the client a moment to send the full CONNECT packet,
          // then reject it.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          socket.add([0x20, 0x03, 0x00, 0x86, 0x00]);
        }
      }());
      return (BrokerEntryModel(id: 'broker-1', name: 'Rejector', host: '127.0.0.1', port: server.port, protocolVersion: MqttProtocolVersionModel.v5, username: 'user', password: 'wrong-password'), connectPackets);
    }

    /// Like [startRejectingBroker] but speaking MQTT 3.1.1: every CONNECT
    /// is answered with CONNACK return code 0x04 (badUsernameOrPassword).
    Future<(BrokerEntryModel, List<bool>)> startRejectingBroker311() async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final connectPackets = <bool>[];
      addTearDown(() async {
        await server.close();
      });
      unawaited(() async {
        await for (final socket in server) {
          connectPackets.add(true);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          socket.add([0x20, 0x02, 0x00, 0x04]);
        }
      }());
      return (BrokerEntryModel(id: 'broker-1', name: 'Rejector', host: '127.0.0.1', port: server.port, protocolVersion: MqttProtocolVersionModel.v311, username: 'user', password: 'wrong-password'), connectPackets);
    }

    /// Waits until the connection status is reported as an error, or the
    /// [timeout] elapses. Returns the status reached.
    Future<ConnectionStatus> waitForError(MqttSessionController session, Duration timeout) async {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        final status = session.connectionStatus;
        if (status == ConnectionStatus.error) return status;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return session.connectionStatus;
    }

    test('MQTT 5 rejected CONNACK surfaces the error immediately with a single attempt', () async {
      final (broker, connectPackets) = await startRejectingBroker();
      await brokers.add(broker);

      // Real (non-faked) MQTT 5 client against a real TCP socket.
      final service = createSession();

      final stopwatch = Stopwatch()..start();
      service.initialize();
      addTearDown(service.dispose);

      final status = await waitForError(service, const Duration(seconds: 8));
      final elapsedMs = stopwatch.elapsedMilliseconds;

      expect(status, ConnectionStatus.error, reason: 'the failure must be surfaced');
      expect(service.connectionError, contains('Bad username or password'), reason: 'the broker reason code is reported as a friendly message');
      expect(service.connectionErrorDetail, contains('badUsernameOrPassword'), reason: 'the raw broker detail is preserved behind the friendly message');
      expect(connectPackets, hasLength(1), reason: 'a rejected CONNACK must not trigger blind retries');
      expect(elapsedMs, lessThan(5000), reason: 'the error is reported promptly, not after ~10s of retries');

      // Dispose while the server is still up: a rejected CONNACK leaves
      // the library's socket open, and letting it die against a closed
      // port later triggers the library's auto-reconnect machinery,
      // which leaks async work out of the test.
      service.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    test('MQTT 5 rejected CONNACK does eventually surface the error (slow retries)', () async {
      final (broker, _) = await startRejectingBroker();
      await brokers.add(broker);

      final service = createSession();
      service.initialize();
      addTearDown(service.dispose);

      final status = await waitForError(service, const Duration(seconds: 20));

      expect(status, ConnectionStatus.error, reason: 'the rejection must eventually be reported');
      expect(service.connectionError, contains('Bad username or password'), reason: 'the broker reason code is reported as a friendly message');
      expect(service.connectionErrorDetail, contains('badUsernameOrPassword'), reason: 'the raw broker detail is preserved behind the friendly message');

      // Dispose while the server is still up (see the fast test).
      service.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('MQTT 3.1.1 rejected CONNACK surfaces a friendly message with the raw return code behind it', () async {
      final (broker, connectPackets) = await startRejectingBroker311();
      await brokers.add(broker);

      final service = createSession();

      final stopwatch = Stopwatch()..start();
      service.initialize();
      addTearDown(service.dispose);

      final status = await waitForError(service, const Duration(seconds: 8));
      final elapsedMs = stopwatch.elapsedMilliseconds;

      expect(status, ConnectionStatus.error, reason: 'the failure must be surfaced');
      expect(service.connectionError, contains('Bad username or password'), reason: 'the 3.1.1 return code is reported as a friendly message');
      expect(service.connectionErrorDetail, contains('MqttConnectReturnCode.badUsernameOrPassword'), reason: 'the broker return code recovered from the late CONNACK is preserved in the details');
      expect(connectPackets, hasLength(1), reason: 'a rejected CONNACK must not trigger blind retries');
      expect(elapsedMs, lessThan(5000), reason: 'the error is reported promptly, not after ~10s of retries');

      service.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  });
}
