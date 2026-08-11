import 'dart:async';

import '../broker/broker_repository.dart';
import '../mqtt/mqtt_message.dart';
import '../mqtt/session/mqtt_session_controller.dart';
import '../state/app_state.dart';
import '../state/keys/settings_keys.dart';
import '../../models/topic_node_value.dart';

/// Globally tracks message history for all topics.
///
/// Runs at the app level, independent of which screen is visible,
/// so history is always being collected. Topics can be marked for
/// "increased monitoring" to keep a larger buffer.
class MessageHistoryService {
  /// Creates app-wide history collection from [mqtt]'s message stream.
  MessageHistoryService(MqttSessionController mqtt, this._state, this._brokers) : _messages = mqtt.messageStream;

  /// Creates history collection from an injected [messages] stream.
  MessageHistoryService.fromStream(Stream<MQTTMessage> messages, this._state, this._brokers) : _messages = messages;

  final Stream<MQTTMessage> _messages;
  final AppStateManager _state;
  final BrokerRepository _brokers;
  StreamSubscription<MQTTMessage>? _subscription;

  /// topic → list of values, newest last.
  final Map<String, List<TopicNodeValue>> _history = {};

  /// Sequence counters per topic (mirrors TopicNodeValue.seq).
  final Map<String, int> _seqCounters = {};

  /// Topics with increased monitoring enabled.
  final Set<String> _increasedTopics = {};

  /// Tracks the active broker so we can clear history on switch.
  String? _activeBrokerId;

  /// Starts listening to the MQTT message stream.
  void initialize() {
    _activeBrokerId = _brokers.activeBrokerId;
    _loadIncreasedTopics();
    _subscription = _messages.listen(_onMessage);
    _state.addListener(_onSettingsChanged);
    _brokers.addListener(_onBrokerChanged);
  }

  void _loadIncreasedTopics() {
    _state.load(SettingsKeys.increasedMonitoringTopics);
    final topics = _state.read(SettingsKeys.increasedMonitoringTopics);
    _increasedTopics
      ..clear()
      ..addAll(topics);
  }

  /// Reloads history-size settings and trims retained topic values.
  void _onSettingsChanged() {
    _loadIncreasedTopics();
    _trimAll();
  }

  /// Clears session history when active broker ownership changes.
  void _onBrokerChanged() {
    final brokerId = _brokers.activeBrokerId;
    if (brokerId != _activeBrokerId) {
      _activeBrokerId = brokerId;
      clear();
    }
  }

  void _onMessage(MQTTMessage msg) {
    final seq = (_seqCounters[msg.topic] ?? 0) + 1;
    _seqCounters[msg.topic] = seq;

    final value = TopicNodeValue(payload: msg.payload, seq: seq, receivedAt: msg.receivedAt, retain: msg.retain, qos: msg.qos);

    final list = _history.putIfAbsent(msg.topic, () => []);
    list.add(value);
    _trim(msg.topic, list);
  }

  /// Returns the history for a topic, newest last.
  List<TopicNodeValue> getHistory(String topic) {
    return List.unmodifiable(_history[topic] ?? const []);
  }

  /// Whether a topic has increased monitoring.
  bool isIncreased(String topic) => _increasedTopics.contains(topic);

  /// Enables increased monitoring for a topic.
  void enableIncreased(String topic) {
    if (_increasedTopics.add(topic)) {
      _persistIncreasedTopics();
    }
  }

  /// Disables increased monitoring for a topic.
  void disableIncreased(String topic) {
    if (_increasedTopics.remove(topic)) {
      _persistIncreasedTopics();
      // Trim down if needed.
      final list = _history[topic];
      if (list != null) _trim(topic, list);
    }
  }

  /// Toggles increased monitoring for a topic.
  bool toggleIncreased(String topic) {
    if (_increasedTopics.contains(topic)) {
      disableIncreased(topic);
      return false;
    } else {
      enableIncreased(topic);
      return true;
    }
  }

  Set<String> get increasedTopics => Set.unmodifiable(_increasedTopics);

  int get defaultHistorySize => _state.read(SettingsKeys.defaultHistorySize);
  int get increasedHistorySize => _state.read(SettingsKeys.increasedHistorySize);

  void _trim(String topic, List<TopicNodeValue> list) {
    final limit = _increasedTopics.contains(topic) ? increasedHistorySize : defaultHistorySize;
    if (limit > 0 && list.length > limit) {
      list.removeRange(0, list.length - limit);
    }
  }

  void _trimAll() {
    for (final entry in _history.entries) {
      _trim(entry.key, entry.value);
    }
  }

  void _persistIncreasedTopics() {
    _state.write(SettingsKeys.increasedMonitoringTopics, _increasedTopics.toList());
  }

  /// Clears history for a specific set of topics.
  void clearTopics(Iterable<String> topics) {
    for (final topic in topics) {
      _history.remove(topic);
      _seqCounters.remove(topic);
    }
  }

  /// Clears all history (e.g. on broker switch).
  void clear() {
    _history.clear();
    _seqCounters.clear();
  }

  /// Stops message collection and releases state and broker listeners.
  void dispose() {
    _subscription?.cancel();
    _state.removeListener(_onSettingsChanged);
    _brokers.removeListener(_onBrokerChanged);
  }
}
