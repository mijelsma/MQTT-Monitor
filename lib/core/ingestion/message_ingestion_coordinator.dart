import 'dart:async';
import 'dart:collection';

import '../../core/monitor/models/topic_node_value_model.dart';
import '../broker/repositories/broker_repository.dart';
import '../mqtt/mqtt_message.dart';
import '../mqtt/session/mqtt_session_controller.dart';
import 'ingested_message.dart';

/// Converts the session stream into one ordered broker-scoped ingestion stream.
class MessageIngestionCoordinator {
  MessageIngestionCoordinator(MqttSessionController session, this._brokers) : _source = session.messageStream, _timeSliced = true;

  MessageIngestionCoordinator.fromStream(Stream<MQTTMessage> source, this._brokers, {bool timeSliced = false}) : _source = source, _timeSliced = timeSliced;

  final Stream<MQTTMessage> _source;
  final BrokerRepository _brokers;
  final bool _timeSliced;
  final StreamController<IngestedMessage> _messages = StreamController<IngestedMessage>.broadcast(sync: true);
  final Map<String, int> _sequences = {};
  final ListQueue<IngestedMessage> _pending = ListQueue();

  StreamSubscription<MQTTMessage>? _subscription;
  Timer? _drainTimer;
  String? _activeBrokerId;

  static const int _maximumMessagesPerSlice = 250;
  static const Duration _maximumSliceDuration = Duration(milliseconds: 4);

  /// Returns immutable messages shared by all application projections.
  Stream<IngestedMessage> get messages => _messages.stream;

  /// Restarts sequence ownership for concrete topics removed from a projection.
  void resetTopics(String brokerId, Iterable<String> topics) {
    if (brokerId != _activeBrokerId) return;
    for (final topic in topics) {
      _sequences.remove(topic);
    }
  }

  /// Restarts all sequence ownership for the active broker projection.
  void resetActiveBroker() => _sequences.clear();

  /// Starts the sole application-level subscription to the MQTT session.
  void initialize() {
    if (_subscription != null) return;
    _activeBrokerId = _brokers.activeBrokerId;
    _brokers.addListener(_onBrokerChanged);
    _subscription = _source.listen(_onSourceMessage);
  }

  void _onSourceMessage(MQTTMessage message) {
    final brokerId = _brokers.activeBrokerId;
    if (brokerId == null) return;
    final sequence = (_sequences[message.topic] ?? 0) + 1;
    _sequences[message.topic] = sequence;
    final ingested = IngestedMessage(
      brokerId: brokerId,
      topic: message.topic,
      value: TopicNodeValueModel(payload: message.payload, payloadBytes: message.payloadBytes, seq: sequence, receivedAt: message.receivedAt, retain: message.retain, qos: message.qos),
    );
    if (!_timeSliced) {
      _messages.add(ingested);
      return;
    }
    _pending.addLast(ingested);
    _scheduleDrain();
  }

  void _scheduleDrain() {
    _drainTimer ??= Timer(Duration.zero, _drainSlice);
  }

  void _drainSlice() {
    _drainTimer = null;
    final stopwatch = Stopwatch()..start();
    var processed = 0;
    while (_pending.isNotEmpty && processed < _maximumMessagesPerSlice && stopwatch.elapsed < _maximumSliceDuration) {
      _messages.add(_pending.removeFirst());
      processed++;
    }
    if (_pending.isNotEmpty) _scheduleDrain();
  }

  void _onBrokerChanged() {
    final brokerId = _brokers.activeBrokerId;
    if (brokerId == _activeBrokerId) return;
    _activeBrokerId = brokerId;
    _sequences.clear();
    _pending.clear();
  }

  /// Stops ingestion and closes the downstream stream.
  Future<void> dispose() async {
    _brokers.removeListener(_onBrokerChanged);
    await _subscription?.cancel();
    _subscription = null;
    _drainTimer?.cancel();
    _drainTimer = null;
    _pending.clear();
    await _messages.close();
  }
}
