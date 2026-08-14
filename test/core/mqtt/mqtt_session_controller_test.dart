import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/repositories/broker_repository.dart';
import 'package:mqtt_monitor/core/mqtt/connection_status.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/core/mqtt/interfaces/mqtt_protocol_adapter_interface.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_protocol_event.dart';
import 'package:mqtt_monitor/core/mqtt/publish_result.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_connection_intent_store.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_session_controller.dart';
import 'package:mqtt_monitor/core/mqtt/repositories/connection_preferences_repository.dart';
import 'package:mqtt_monitor/core/logging/app_logger.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/mqtt_protocol_version_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/startup_connection_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_history_policy_model.dart';

import '../../support/test_dependencies.dart';

/// Provides direct control over protocol events for session lifecycle tests.
class _ControllableAdapter implements MqttProtocolAdapterInterface {
  /// Creates an adapter for [protocolVersion] with an optional connect gate.
  _ControllableAdapter(this.protocolVersion, {this.connectGate});

  @override
  final MqttProtocolVersionModel protocolVersion;

  final Completer<void>? connectGate;
  final StreamController<MqttProtocolEvent> _events = StreamController<MqttProtocolEvent>.broadcast();
  final StreamController<MQTTMessage> _messages = StreamController<MQTTMessage>.broadcast();

  int connectCalls = 0;
  int disposeCalls = 0;
  final List<({String topic, int qos})> subscriptions = [];
  final List<String> unsubscriptions = [];
  bool _connected = false;

  /// Returns controllable lifecycle events.
  @override
  Stream<MqttProtocolEvent> get events => _events.stream;

  /// Returns controllable received messages.
  @override
  Stream<MQTTMessage> get messages => _messages.stream;

  /// Returns whether connect has completed successfully.
  @override
  bool get isConnected => _connected;

  /// Waits for the optional gate and records a successful connection.
  @override
  Future<void> connect() async {
    connectCalls++;
    await connectGate?.future;
    _connected = true;
  }

  /// Returns an unconfirmed result while connected.
  @override
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) {
    if (!_connected) return null;
    return Future<PublishResult>.value(PublishResult.unconfirmed(protocolVersion, qos));
  }

  /// Accepts a subscription only while connected.
  @override
  bool subscribe(String topic, {int qos = 0}) {
    if (!_connected) return false;
    subscriptions.add((topic: topic, qos: qos));
    return true;
  }

  /// Accepts an unsubscription only while connected.
  @override
  bool unsubscribe(String topic) {
    if (!_connected) return false;
    unsubscriptions.add(topic);
    return true;
  }

  /// Records teardown without closing streams so stale emissions can be tested.
  @override
  Future<void> dispose() async {
    disposeCalls++;
    _connected = false;
  }

  /// Emits [event] even after disposal to test generation filtering.
  void emitEvent(MqttProtocolEvent event) => _events.add(event);

  /// Emits [message] even after disposal to test generation filtering.
  void emitMessage(MQTTMessage message) => _messages.add(message);

  /// Closes resources retained for stale-callback tests.
  Future<void> close() async {
    await _events.close();
    await _messages.close();
  }
}

class _ManualTimer implements Timer {
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;
}

void main() {
  late ConnectionPreferencesRepository connectionPreferences;
  late LocalAppLogger logger;
  late BrokerRepository brokers;
  late MqttConnectionIntentStore intent;

  setUp(() async {
    final dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
    connectionPreferences = dependencies.connectionPreferences;
    logger = dependencies.logger;
    intent = MqttConnectionIntentStore(dependencies.preferences);
    await connectionPreferences.setStartupConnection(StartupConnectionModel.alwaysConnect);
  });

  /// Lets unawaited reconciliation work cross its asynchronous boundaries.
  Future<void> settle() async {
    for (var index = 0; index < 4; index++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('last-status startup honors persisted disconnected intent', () async {
    await connectionPreferences.setStartupConnection(StartupConnectionModel.lastStatus);
    await intent.setConnectionRequested(false);
    await brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'one.invalid'));
    final adapters = <_ControllableAdapter>[];
    final controller = MqttSessionController(
      connectionPreferences,
      brokers,
      intent,
      logger: logger,
      adapterFactory: (broker) {
        final adapter = _ControllableAdapter(broker.protocolVersion);
        adapters.add(adapter);
        return adapter;
      },
    );
    addTearDown(controller.dispose);
    addTearDown(() async {
      for (final adapter in adapters) {
        await adapter.close();
      }
    });

    controller.initialize();
    await settle();

    expect(adapters, isEmpty);
    expect(controller.connectionStatus, ConnectionStatus.disconnected);

    controller.reconnect();
    await settle();

    expect(adapters, hasLength(1));
    expect(controller.connectionStatus, ConnectionStatus.connected);
    expect(intent.connectionRequested, isTrue);

    controller.disconnect();
    await settle();

    expect(controller.connectionStatus, ConnectionStatus.disconnected);
    expect(intent.connectionRequested, isFalse);
  });

  test('display-only broker edits do not replace the active session', () async {
    const broker = BrokerEntryModel(id: 'broker', name: 'Before', host: 'one.invalid', colorIndex: 0);
    await brokers.add(broker);
    final adapters = <_ControllableAdapter>[];
    final controller = MqttSessionController(
      connectionPreferences,
      brokers,
      intent,
      logger: logger,
      adapterFactory: (profile) {
        final adapter = _ControllableAdapter(profile.protocolVersion);
        adapters.add(adapter);
        return adapter;
      },
    );
    addTearDown(controller.dispose);
    addTearDown(() async {
      for (final adapter in adapters) {
        await adapter.close();
      }
    });
    controller.initialize();
    await settle();

    await brokers.update(broker.copyWith(name: 'After', colorIndex: 4));
    await settle();

    expect(adapters, hasLength(1));
    expect(adapters.single.disposeCalls, 0);
    expect(controller.connectionStatus, ConnectionStatus.connected);
  });

  test('subscription and policy edits reconcile without replacing session', () async {
    const original = SubscriptionEntryModel(id: 'stable', topic: 'sensors/#', qos: 1);
    const broker = BrokerEntryModel(id: 'broker', name: 'Broker', host: 'one.invalid', subscriptions: [original]);
    await brokers.add(broker);
    final adapters = <_ControllableAdapter>[];
    final controller = MqttSessionController(
      connectionPreferences,
      brokers,
      intent,
      logger: logger,
      adapterFactory: (profile) {
        final adapter = _ControllableAdapter(profile.protocolVersion);
        adapters.add(adapter);
        return adapter;
      },
    );
    addTearDown(controller.dispose);
    addTearDown(() async {
      for (final adapter in adapters) {
        await adapter.close();
      }
    });
    controller.initialize();
    await settle();

    final adapter = adapters.single;
    expect(adapter.subscriptions, [(topic: 'sensors/#', qos: 1)]);

    await brokers.update(
      broker.copyWith(
        subscriptions: [original.copyWith(name: 'Renamed', history: const SubscriptionHistoryPolicyModel(enabled: false, retention: 200))],
      ),
    );
    await settle();

    expect(adapters, hasLength(1));
    expect(adapter.subscriptions, hasLength(1));
    expect(adapter.unsubscriptions, isEmpty);

    await brokers.update(
      broker.copyWith(
        subscriptions: const [SubscriptionEntryModel(id: 'stable', topic: 'devices/#', qos: 2)],
      ),
    );
    await settle();

    expect(adapters, hasLength(1));
    expect(adapter.unsubscriptions, ['sensors/#']);
    expect(adapter.subscriptions.last, (topic: 'devices/#', qos: 2));
  });

  test('stale adapter completions and callbacks cannot overwrite a new session', () async {
    const broker = BrokerEntryModel(id: 'broker', name: 'Broker', host: 'one.invalid');
    await brokers.add(broker);
    final firstConnect = Completer<void>();
    final adapters = <_ControllableAdapter>[];
    final controller = MqttSessionController(
      connectionPreferences,
      brokers,
      intent,
      logger: logger,
      adapterFactory: (profile) {
        final adapter = _ControllableAdapter(profile.protocolVersion, connectGate: adapters.isEmpty ? firstConnect : null);
        adapters.add(adapter);
        return adapter;
      },
    );
    addTearDown(controller.dispose);
    addTearDown(() async {
      for (final adapter in adapters) {
        await adapter.close();
      }
    });
    controller.initialize();
    await settle();

    expect(controller.connectionStatus, ConnectionStatus.connecting);
    await brokers.update(broker.copyWith(host: 'two.invalid'));
    await settle();

    expect(adapters, hasLength(2));
    expect(adapters.first.disposeCalls, 1);
    expect(controller.connectionStatus, ConnectionStatus.connected);

    firstConnect.complete();
    adapters.first.emitEvent(const MqttProtocolEvent.failure(ConnectionStatus.errorRefused, 'stale failure'));
    adapters.first.emitMessage(MQTTMessage(topic: 'stale/topic', payload: 'ignored', receivedAt: DateTime(2026)));
    await settle();

    expect(controller.connectionStatus, ConnectionStatus.connected);
    expect(controller.connectionError, isNull);
    expect(controller.messageCount, 0);
  });

  test('protocol events drive state and disposal releases the adapter', () async {
    await brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'one.invalid'));
    final adapters = <_ControllableAdapter>[];
    final controller = MqttSessionController(
      connectionPreferences,
      brokers,
      intent,
      logger: logger,
      adapterFactory: (broker) {
        final adapter = _ControllableAdapter(broker.protocolVersion);
        adapters.add(adapter);
        return adapter;
      },
    );
    final statuses = <ConnectionStatus>[];
    controller.addListener(() => statuses.add(controller.connectionStatus));
    addTearDown(() async {
      for (final adapter in adapters) {
        await adapter.close();
      }
    });

    controller.initialize();
    await settle();
    final adapter = adapters.single;
    adapter.emitEvent(const MqttProtocolEvent.reconnecting());
    await settle();
    adapter.emitEvent(const MqttProtocolEvent.connected());
    adapter.emitMessage(MQTTMessage(topic: 'live/topic', payload: 'value', receivedAt: DateTime(2026)));
    await settle();

    expect(statuses, containsAllInOrder([ConnectionStatus.connecting, ConnectionStatus.connected, ConnectionStatus.connecting, ConnectionStatus.connected]));
    expect(controller.messageCount, 1);

    controller.dispose();
    await settle();

    expect(adapter.disposeCalls, 1);
  });

  test('message telemetry notifies only when the sampling timer flushes', () async {
    await brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'one.invalid'));
    late void Function(Timer) sample;
    final adapters = <_ControllableAdapter>[];
    final controller = MqttSessionController(
      connectionPreferences,
      brokers,
      intent,
      logger: logger,
      adapterFactory: (broker) {
        final adapter = _ControllableAdapter(broker.protocolVersion);
        adapters.add(adapter);
        return adapter;
      },
      periodicTimerFactory: (_, callback) {
        sample = callback;
        return _ManualTimer();
      },
    );
    addTearDown(controller.dispose);
    addTearDown(() async {
      for (final adapter in adapters) {
        await adapter.close();
      }
    });
    controller.initialize();
    await settle();
    var notifications = 0;
    controller.addListener(() => notifications++);

    adapters.single.emitMessage(MQTTMessage(topic: 'live/topic', payload: 'value', receivedAt: DateTime(2026)));
    await settle();

    expect(controller.messageCount, 1);
    expect(controller.state.messageCount, 0);
    expect(notifications, 0);

    sample(_ManualTimer());
    expect(controller.state.messageCount, 1);
    expect(controller.messageRate, 1);
    expect(notifications, 1);
  });
}
