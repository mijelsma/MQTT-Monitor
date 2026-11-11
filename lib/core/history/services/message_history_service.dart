import 'dart:async';
import 'dart:collection';

import '../../../core/monitor/models/topic_node_value_model.dart';
import '../../broker/repositories/broker_repository.dart';
import '../../ingestion/ingested_message.dart';
import '../../ingestion/message_ingestion_coordinator.dart';
import '../../mqtt/mqtt_message.dart';
import '../history_policy_resolution.dart';
import '../history_policy_resolver.dart';
import '../history_policy_rules.dart';
import '../repositories/history_preferences_repository.dart';

/// Owns bounded, broker-scoped, in-memory message history.
class MessageHistoryService {
  MessageHistoryService(MessageIngestionCoordinator ingestion, this._preferences, this._brokers, {HistoryPolicyResolver resolver = const HistoryPolicyResolver()}) : _messages = ingestion.messages, _ownedIngestion = null, _resolver = resolver;

  factory MessageHistoryService.fromStream(Stream<MQTTMessage> messages, HistoryPreferencesRepository preferences, BrokerRepository brokers, {HistoryPolicyResolver resolver = const HistoryPolicyResolver()}) {
    final ingestion = MessageIngestionCoordinator.fromStream(messages, brokers);
    return MessageHistoryService._owned(ingestion, preferences, brokers, resolver: resolver);
  }

  MessageHistoryService._owned(MessageIngestionCoordinator ingestion, this._preferences, this._brokers, {required HistoryPolicyResolver resolver}) : _messages = ingestion.messages, _ownedIngestion = ingestion, _resolver = resolver;

  final Stream<IngestedMessage> _messages;
  final MessageIngestionCoordinator? _ownedIngestion;
  final HistoryPreferencesRepository _preferences;
  final BrokerRepository _brokers;
  final HistoryPolicyResolver _resolver;
  final Map<String, ListQueue<TopicNodeValueModel>> _history = {};

  StreamSubscription<IngestedMessage>? _subscription;
  String? _activeBrokerId;

  /// Starts app-level collection once.
  void initialize() {
    if (_subscription != null) return;
    _activeBrokerId = _brokers.activeBrokerId;
    _subscription = _messages.listen(_onMessage);
    _brokers.addListener(_onBrokerChanged);
    _ownedIngestion?.initialize();
  }

  /// Returns the effective active-broker policy for a concrete [topic].
  HistoryPolicyResolution resolutionFor(String topic) {
    final broker = _brokers.activeBroker;
    if (broker == null) return const HistoryPolicyResolution.unmatched();
    return _resolver.resolve(topic, broker.subscriptions, maximumRetention: _maximumRetention);
  }

  /// Returns retained values for [topic], ordered oldest to newest.
  List<TopicNodeValueModel> getHistory(String topic) {
    final values = _history[topic];
    return values == null ? const [] : List<TopicNodeValueModel>.unmodifiable(values);
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
    }
  }

  /// Clears all history owned by the current broker session.
  void clear() {
    _history.clear();
  }

  int get _maximumRetention {
    return _preferences.maximumRetention;
  }

  /// Resolves policy before allocating or looking up a history buffer.
  void _onMessage(IngestedMessage message) {
    if (message.brokerId != _brokers.activeBrokerId) return;
    final resolution = resolutionFor(message.topic);
    if (!resolution.enabled) return;

    final values = _history.putIfAbsent(message.topic, ListQueue.new);
    values.addLast(message.value);
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

  void _trim(ListQueue<TopicNodeValueModel> values, int maximum) {
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
    await _ownedIngestion?.dispose();
  }
}
