import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt3_server;
import 'package:mqtt_monitor/core/mqtt/connection_status.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_reason.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_service.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/app_keys.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMqtt3Client extends mqtt3_server.MqttServerClient {
  _FakeMqtt3Client() : super('unused', 'test-client');

  final status = mqtt3.MqttClientConnectionStatus();
  final updatesController =
      StreamController<
        List<mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>>
      >.broadcast();
  final subscriptions = <({String topic, mqtt3.MqttQos qos})>[];
  final unsubscriptions = <String>[];
  final publications =
      <({String topic, mqtt3.MqttQos qos, String payload, bool retain})>[];
  int connectCalls = 0;
  int disconnectCalls = 0;
  String? connectedUsername;
  String? connectedPassword;

  @override
  mqtt3.MqttClientConnectionStatus get connectionStatus => status;

  @override
  Stream<List<mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>>> get updates =>
      updatesController.stream;

  @override
  Future<mqtt3.MqttClientConnectionStatus?> connect([
    String? username,
    String? password,
  ]) async {
    connectCalls++;
    connectedUsername = username;
    connectedPassword = password;
    status.state = mqtt3.MqttConnectionState.connected;
    onConnected?.call();
    return status;
  }

  @override
  mqtt3.Subscription? subscribe(String topic, mqtt3.MqttQos qosLevel) {
    subscriptions.add((topic: topic, qos: qosLevel));
    return null;
  }

  @override
  void unsubscribe(String topic, {expectAcknowledge = false}) {
    unsubscriptions.add(topic);
  }

  @override
  int publishMessage(
    String topic,
    mqtt3.MqttQos qualityOfService,
    dynamic data, {
    bool retain = false,
  }) {
    publications.add((
      topic: topic,
      qos: qualityOfService,
      payload: utf8.decode(List<int>.from(data)),
      retain: retain,
    ));
    return publications.length;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    status.state = mqtt3.MqttConnectionState.disconnected;
  }

  void brokerDisconnect() {
    status.state = mqtt3.MqttConnectionState.disconnected;
    onDisconnected?.call();
  }

  void addMalformedUpdate() {
    updatesController.add([
      mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>(
        'invalid',
        mqtt3.MqttConnectMessage(),
      ),
    ]);
  }

  void addPublish(
    String topic,
    List<int> bytes, {
    int qos = 0,
    bool retain = false,
  }) {
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
    updatesController.add([
      mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>(topic, message),
    ]);
  }

  Future<void> close() => updatesController.close();
}

void main() {
  final state = AppStateManager.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await state.initialize();
    await state.resetAll();
  });

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'connects, subscribes, publishes each QoS, and unsubscribes with a fake client',
    () async {
      const broker = BrokerEntry(
        id: 'broker-1',
        name: 'Test',
        host: 'broker.invalid',
        username: 'user',
        password: 'secret',
        subscriptions: [
          SubscriptionEntry(topic: 'sensors/+', qos: 1),
          SubscriptionEntry(topic: 'alerts/#', qos: 2),
        ],
      );
      final fake = _FakeMqtt3Client();
      await state.write(SettingsKeys.brokers, [broker]);
      await state.write(AppKeys.activeBrokerId, broker.id);
      await state.write(AppKeys.disconnected, false);
      final service = MqttService(state, mqtt3ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);

      service.initialize();
      await settle();

      expect(fake.connectCalls, 1);
      expect(fake.connectedUsername, 'user');
      expect(fake.connectedPassword, 'secret');
      expect(fake.subscriptions, [
        (topic: 'sensors/+', qos: mqtt3.MqttQos.atLeastOnce),
        (topic: 'alerts/#', qos: mqtt3.MqttQos.exactlyOnce),
      ]);
      expect(state.read(AppKeys.connectionStatus), ConnectionStatus.connected);

      expect(service.publish('out/0', 'zero', qos: 0), isTrue);
      expect(service.publish('out/1', 'one', qos: 1, retain: true), isTrue);
      expect(service.publish('out/2', 'two', qos: 2), isTrue);
      expect(fake.publications.map((value) => value.qos), [
        mqtt3.MqttQos.atMostOnce,
        mqtt3.MqttQos.atLeastOnce,
        mqtt3.MqttQos.exactlyOnce,
      ]);
      expect(fake.publications[1].retain, isTrue);

      expect(service.subscribe('dynamic/topic', qos: 2), isTrue);
      expect(service.unsubscribe('dynamic/topic'), isTrue);
      expect(fake.subscriptions.last, (
        topic: 'dynamic/topic',
        qos: mqtt3.MqttQos.exactlyOnce,
      ));
      expect(fake.unsubscriptions, ['dynamic/topic']);
    },
  );

  test('disconnect and reconnect replace the active session', () async {
    const broker = BrokerEntry(
      id: 'broker-1',
      name: 'Test',
      host: 'broker.invalid',
    );
    final clients = <_FakeMqtt3Client>[];
    await state.write(SettingsKeys.brokers, [broker]);
    await state.write(AppKeys.activeBrokerId, broker.id);
    await state.write(AppKeys.disconnected, false);
    final service = MqttService(
      state,
      mqtt3ClientFactory: (_) {
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
    expect(state.read(AppKeys.connectionStatus), ConnectionStatus.disconnected);
    expect(service.publish('offline', 'ignored'), isFalse);

    service.reconnect();
    await settle();

    expect(clients, hasLength(2));
    expect(clients.last.connectCalls, 1);
    expect(state.read(AppKeys.connectionStatus), ConnectionStatus.connected);
  });

  test(
    'editing a profile reconnects and applies its new subscriptions',
    () async {
      const broker = BrokerEntry(
        id: 'same-id',
        name: 'Test',
        host: 'first.invalid',
      );
      final clients = <_FakeMqtt3Client>[];
      await state.write(SettingsKeys.brokers, [broker]);
      await state.write(AppKeys.activeBrokerId, broker.id);
      final service = MqttService(
        state,
        mqtt3ClientFactory: (_) {
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

      await state.write(SettingsKeys.brokers, [
        broker.copyWith(
          host: 'second.invalid',
          subscriptions: const [SubscriptionEntry(topic: 'new/#', qos: 1)],
        ),
      ]);
      await settle();

      expect(clients, hasLength(2));
      expect(clients.first.disconnectCalls, 1);
      expect(clients.last.subscriptions, [
        (topic: 'new/#', qos: mqtt3.MqttQos.atLeastOnce),
      ]);
    },
  );

  test('broker disconnect explains MQTT 3.1.1 limitation', () async {
    const broker = BrokerEntry(
      id: 'broker-1',
      name: 'Test',
      host: 'broker.invalid',
    );
    final fake = _FakeMqtt3Client();
    await state.write(SettingsKeys.brokers, [broker]);
    await state.write(AppKeys.activeBrokerId, broker.id);
    final service = MqttService(state, mqtt3ClientFactory: (_) => fake);
    addTearDown(service.dispose);
    addTearDown(fake.close);
    service.initialize();
    await settle();

    fake.brokerDisconnect();
    await settle();

    expect(state.read(AppKeys.connectionStatus), ConnectionStatus.disconnected);
    expect(state.read(AppKeys.connectionError), mqtt311BrokerDisconnectMessage);
  });

  test(
    'malformed updates are reported and invalid UTF-8 is decoded safely',
    () async {
      const broker = BrokerEntry(
        id: 'broker-1',
        name: 'Test',
        host: 'broker.invalid',
      );
      final fake = _FakeMqtt3Client();
      await state.write(SettingsKeys.brokers, [broker]);
      await state.write(AppKeys.activeBrokerId, broker.id);
      final service = MqttService(state, mqtt3ClientFactory: (_) => fake);
      addTearDown(service.dispose);
      addTearDown(fake.close);
      service.initialize();
      await settle();

      fake.addMalformedUpdate();
      await settle();
      expect(
        state.read(AppKeys.connectionError),
        contains('Malformed MQTT packet'),
      );

      final nextMessage = service.messageStream.first;
      fake.addPublish('binary/value', [0xff, 0x61], qos: 1, retain: true);
      final message = await nextMessage;

      expect(message.topic, 'binary/value');
      expect(message.payload, '\uFFFDa');
      expect(message.qos, 1);
      expect(message.retain, isTrue);
    },
  );
}
