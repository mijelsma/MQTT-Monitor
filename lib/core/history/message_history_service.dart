import 'dart:async';
import 'dart:collection';

import '../../models/topic_node_value.dart';
import '../broker/broker_repository.dart';
import '../mqtt/mqtt_message.dart';
import '../mqtt/session/mqtt_session_controller.dart';
import '../state/app_state.dart';
import '../state/keys/settings_keys.dart';
import 'history_policy_resolution.dart';
import 'history_policy_resolver.dart';
import 'history_policy_rules.dart';

/// Owns bounded, broker-scoped, in-memory message history.
class MessageHistoryService {
  MessageHistoryService(
    MqttSessionController mqtt,
    this._state,
    this._brokers, {
    HistoryPolicyResolver resolver = const HistoryPolicyResolver(),
  }) : _messages = mqtt.messageStream,
       _resolver = resolver;

  MessageHistoryService.fromStream(
    Stream<MQTTMessage> messages,
    this._state,
    this._brokers, {
    HistoryPolicyResolver resolver = const HistoryPolicyResolver(),
  }) : _messages = messages,
       _resolver = resolver;

  final Stream<MQTTMessage> _messages;
  final AppStateManager _state;
  final BrokerRepository _brokers;
  final HistoryPolicyResolver _resolver;
  final Map<String, ListQueue<TopicNodeValue>> _history = {};
  final Map<String, int> _seqCounters = {};

  StreamSubscription<MQTTMessage>? _subscription;
  String? _activeBrokerId;

  /// Starts app-level collection once.
  void initialize() {
    if (_subscription != null) return;
    _activeBrokerId = _brokers.activeBrokerId;
    _subscription = _messages.listen(_onMessage);
    _brokers.addListener(_onBrokerChanged);
  }

  /// Returns the effective active-broker policy for a concrete [topic].
  HistoryPolicyResolution resolutionFor(String topic) {
    final broker = _brokers.activeBroker;
    if (broker == null) return const HistoryPolicyResolution.unmatched();
    return _resolver.resolve(
      topic,
      broker.subscriptions,
      maximumRetention: _maximumRetention,
    );
  }

  /// Returns retained values for [topic], ordered oldest to newest.
  List<TopicNodeValue> getHistory(String topic) {
    final values = _history[topic];
    return values == null
        ? const []
        : List<TopicNodeValue>.unmodifiable(values);
  }

  /// Returns the number of allocated topic buffers.
  int get bufferCount => _history.length;

  /// Counts buffers whose current size exceeds [maximum].
  int countBuffersAbove(int maximum) {
    HistoryPolicyRules.validateMaximum(maximum);
    return _history.values.where((values) => values.length > maximum).length;
  }

  /// Applies an explicitly confirmed global maximum to existing buffers.
  void trimToMaximum(int maximum) {
    HistoryPolicyRules.validateMaximum(maximum);
    for (final values in _history.values) {
      _trim(values, maximum);
    }
  }

  /// Clears retained values and sequence ownership for selected topics.
  void clearTopics(Iterable<String> topics) {
    for (final topic in topics) {
      _history.remove(topic);
      _seqCounters.remove(topic);
    }
  }

  /// Clears all history owned by the current broker session.
  void clear() {
    _history.clear();
    _seqCounters.clear();
  }

  int get _maximumRetention {
    final value = _state.read(SettingsKeys.maximumHistoryRetention);
    return HistoryPolicyRules.isValidMaximum(value)
        ? value
        : HistoryPolicyRules.defaultMaximumRetention;
  }

  /// Resolves policy before allocating sequence, value, or buffer objects.
  void _onMessage(MQTTMessage message) {
    final resolution = resolutionFor(message.topic);
    if (!resolution.enabled) return;

    final sequence = (_seqCounters[message.topic] ?? 0) + 1;
    _seqCounters[message.topic] = sequence;
    final values = _history.putIfAbsent(message.topic, ListQueue.new);
    values.addLast(
      TopicNodeValue(
        payload: message.payload,
        seq: sequence,
        receivedAt: message.receivedAt,
        retain: message.retain,
        qos: message.qos,
      ),
    );
    _trim(values, resolution.retention);
  }

  /// Keeps active-broker policy edits local and broker switches isolated.
  void _onBrokerChanged() {
    final brokerId = _brokers.activeBrokerId;
    if (brokerId != _activeBrokerId) {
      _activeBrokerId = brokerId;
      clear();
      return;
    }
    _trimEnabledPolicies();
  }

  /// Trims explicit retention reductions while preserving disabled buffers.
  void _trimEnabledPolicies() {
    for (final entry in _history.entries) {
      final resolution = resolutionFor(entry.key);
      if (resolution.enabled) _trim(entry.value, resolution.retention);
    }
  }

  void _trim(ListQueue<TopicNodeValue> values, int maximum) {
    while (values.length > maximum) {
      values.removeFirst();
    }
  }

  /// Stops message collection and releases broker ownership observation.
  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    _brokers.removeListener(_onBrokerChanged);
    await subscription?.cancel();
  }
}
