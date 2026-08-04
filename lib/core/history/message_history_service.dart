import 'dart:async';

import '../mqtt/mqtt_message.dart';
import '../mqtt/mqtt_service.dart';
import '../state/app_state.dart';
import '../state/keys/app_keys.dart';
import '../state/keys/settings_keys.dart';
import '../../models/topic_node_value.dart';

/// Globally tracks message history for all topics.
///
/// Runs at the app level, independent of which screen is visible,
/// so history is always being collected. Topics can be marked for
/// "increased monitoring" to keep a larger buffer.
class MessageHistoryService {
  MessageHistoryService(MqttService mqtt, this._state) : _messages = mqtt.messageStream;

  MessageHistoryService.fromStream(Stream<MQTTMessage> messages, this._state) : _messages = messages;

  final Stream<MQTTMessage> _messages;
  final AppStateManager _state;
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
    _state.load(AppKeys.activeBrokerId);
    _activeBrokerId = _state.read(AppKeys.activeBrokerId);
    _loadIncreasedTopics();
    _subscription = _messages.listen(_onMessage);
    _state.addListener(_onSettingsChanged);
  }

  void _loadIncreasedTopics() {
    _state.load(SettingsKeys.increasedMonitoringTopics);
    final topics = _state.read(SettingsKeys.increasedMonitoringTopics);
    _increasedTopics
      ..clear()
      ..addAll(topics);
  }

  void _onSettingsChanged() {
    final brokerId = _state.read(AppKeys.activeBrokerId);
    if (brokerId != _activeBrokerId) {
      _activeBrokerId = brokerId;
      clear();
    }
    _loadIncreasedTopics();
    _trimAll();
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

  void dispose() {
    _subscription?.cancel();
    _state.removeListener(_onSettingsChanged);
  }
}
