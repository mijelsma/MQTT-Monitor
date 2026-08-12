import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_protocol_adapter.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_protocol_event.dart';
import 'package:mqtt_monitor/core/mqtt/publish_result.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_subscription_reconciler.dart';
import 'package:mqtt_monitor/models/mqtt_protocol_version.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';
import 'package:mqtt_monitor/models/subscription_history_policy.dart';

class _RecordingAdapter implements MqttProtocolAdapter {
  final StreamController<MqttProtocolEvent> _events = StreamController<MqttProtocolEvent>.broadcast();
  final StreamController<MQTTMessage> _messages = StreamController<MQTTMessage>.broadcast();
  final List<({String topic, int qos})> subscriptions = [];
  final List<String> unsubscriptions = [];

  bool connected = true;
  bool failNextUnsubscribe = false;

  @override
  MqttProtocolVersion get protocolVersion => MqttProtocolVersion.v311;

  @override
  Stream<MqttProtocolEvent> get events => _events.stream;

  @override
  Stream<MQTTMessage> get messages => _messages.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async => connected = true;

  @override
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) => null;

  @override
  bool subscribe(String topic, {int qos = 0}) {
    subscriptions.add((topic: topic, qos: qos));
    return true;
  }

  @override
  bool unsubscribe(String topic) {
    unsubscriptions.add(topic);
    if (failNextUnsubscribe) {
      failNextUnsubscribe = false;
      return false;
    }
    return true;
  }

  @override
  Future<void> dispose() async {
    await _events.close();
    await _messages.close();
  }
}

void main() {
  const original = SubscriptionEntry(id: 'stable', topic: 'sensors/#', qos: 1);

  test('adds, changes, and removes protocol subscriptions by stable ID', () {
    final adapter = _RecordingAdapter();
    final reconciler = MqttSubscriptionReconciler()
      ..attach(adapter, const [original])
      ..onConnected();

    expect(adapter.subscriptions, [(topic: 'sensors/#', qos: 1)]);

    reconciler.update(const [SubscriptionEntry(id: 'stable', topic: 'devices/#', qos: 2)]);
    expect(adapter.unsubscriptions, ['sensors/#']);
    expect(adapter.subscriptions.last, (topic: 'devices/#', qos: 2));

    reconciler.update(const []);
    expect(adapter.unsubscriptions.last, 'devices/#');
  });

  test('display and history-only edits issue no protocol operations', () {
    final adapter = _RecordingAdapter();
    final reconciler = MqttSubscriptionReconciler()
      ..attach(adapter, const [original])
      ..onConnected();
    adapter.subscriptions.clear();

    reconciler.update([original.copyWith(name: 'Renamed', history: const SubscriptionHistoryPolicy(enabled: false, retention: 250))]);

    expect(adapter.subscriptions, isEmpty);
    expect(adapter.unsubscriptions, isEmpty);
  });

  test('failed removal is retained and retried before replacement', () {
    final adapter = _RecordingAdapter()..failNextUnsubscribe = true;
    final reconciler = MqttSubscriptionReconciler()
      ..attach(adapter, const [original])
      ..onConnected();
    adapter.subscriptions.clear();

    const replacement = SubscriptionEntry(id: 'stable', topic: 'devices/#', qos: 2);
    reconciler.update(const [replacement]);

    expect(adapter.unsubscriptions, ['sensors/#']);
    expect(adapter.subscriptions, isEmpty);

    reconciler.update(const [replacement]);
    expect(adapter.unsubscriptions, ['sensors/#', 'sensors/#']);
    expect(adapter.subscriptions, [(topic: 'devices/#', qos: 2)]);
  });

  test('automatic reconnect restores desired subscriptions once', () {
    final adapter = _RecordingAdapter();
    final reconciler = MqttSubscriptionReconciler()
      ..attach(adapter, const [original])
      ..onConnected();

    reconciler
      ..onDisconnected()
      ..onConnected()
      ..onConnected();

    expect(adapter.subscriptions, [(topic: 'sensors/#', qos: 1), (topic: 'sensors/#', qos: 1)]);
  });
}
