import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/connection_status.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_protocol_adapter.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_protocol_event.dart';
import 'package:mqtt_monitor/core/mqtt/publish_result.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_connection_intent_store.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_session_controller.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/mqtt_protocol_version.dart';
import 'package:mqtt_monitor/models/startup_connection.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';

import '../support/test_dependencies.dart';
import 'traffic_generator.dart';

void main() {
  test('reconnect loops resubscribe once and broker switching rejects stale traffic', () async {
    const reconnectCycles = 250;
    final dependencies = await TestDependencies.create();
    await dependencies.connectionPreferences.setStartupConnection(StartupConnection.alwaysConnect);
    await dependencies.brokers.add(
      const BrokerEntry(
        id: 'one',
        name: 'One',
        host: 'one.invalid',
        subscriptions: [SubscriptionEntry(id: 'one-all', topic: '#')],
      ),
    );
    await dependencies.brokers.add(
      const BrokerEntry(
        id: 'two',
        name: 'Two',
        host: 'two.invalid',
        subscriptions: [SubscriptionEntry(id: 'two-all', topic: '#')],
      ),
      makeActive: false,
    );
    final adapters = <_AcceptanceAdapter>[];
    final controller = MqttSessionController(
      dependencies.connectionPreferences,
      dependencies.brokers,
      MqttConnectionIntentStore(dependencies.preferences),
      logger: dependencies.logger,
      adapterFactory: (broker) {
        final adapter = _AcceptanceAdapter(broker.protocolVersion);
        adapters.add(adapter);
        return adapter;
      },
      periodicTimerFactory: (_, _) => _InactiveTimer(),
    );
    controller.initialize();
    await _settle();
    final first = adapters.single;
    final generator = TrafficGenerator(topicCount: 100);

    final stopwatch = Stopwatch()..start();
    for (var cycle = 0; cycle < reconnectCycles; cycle++) {
      first.emitEvent(const MqttProtocolEvent.reconnecting());
      first.emitEvent(const MqttProtocolEvent.connected());
      first.emitMessage(generator.message(cycle));
    }
    stopwatch.stop();

    expect(controller.connectionStatus, ConnectionStatus.connected);
    expect(controller.messageCount, reconnectCycles);
    expect(first.subscriptions, reconnectCycles + 1, reason: 'Initial connect and each completed reconnect must restore the desired filter exactly once.');
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));

    await dependencies.brokers.select('two');
    await _settle();
    expect(adapters, hasLength(2));
    first.emitMessage(generator.message(reconnectCycles));
    await _settle();
    expect(controller.messageCount, 0, reason: 'The old broker generation must not leak messages into the replacement session.');

    debugPrint('$reconnectCycles reconnect cycles: ${stopwatch.elapsedMicroseconds} us, ${first.subscriptions} total subscribe calls');
    await controller.shutdown();
    controller.dispose();
    for (final adapter in adapters) {
      await adapter.close();
    }
  });
}

Future<void> _settle() async {
  for (var index = 0; index < 4; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _AcceptanceAdapter implements MqttProtocolAdapter {
  _AcceptanceAdapter(this.protocolVersion);

  @override
  final MqttProtocolVersion protocolVersion;
  final StreamController<MqttProtocolEvent> _events = StreamController<MqttProtocolEvent>.broadcast(sync: true);
  final StreamController<MQTTMessage> _messages = StreamController<MQTTMessage>.broadcast(sync: true);
  bool _connected = false;
  int subscriptions = 0;

  @override
  Stream<MqttProtocolEvent> get events => _events.stream;

  @override
  Stream<MQTTMessage> get messages => _messages.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) => _connected ? Future.value(PublishResult.unconfirmed(protocolVersion, qos)) : null;

  @override
  bool subscribe(String topic, {int qos = 0}) {
    if (!_connected) return false;
    subscriptions++;
    return true;
  }

  @override
  bool unsubscribe(String topic) => _connected;

  @override
  Future<void> dispose() async => _connected = false;

  void emitEvent(MqttProtocolEvent event) => _events.add(event);

  void emitMessage(MQTTMessage message) => _messages.add(message);

  Future<void> close() async {
    await _events.close();
    await _messages.close();
  }
}

class _InactiveTimer implements Timer {
  @override
  bool get isActive => false;

  @override
  int get tick => 0;

  @override
  void cancel() {}
}
