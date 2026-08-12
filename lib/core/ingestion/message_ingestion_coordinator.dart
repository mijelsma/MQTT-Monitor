import 'dart:async';

import '../../models/topic_node_value.dart';
import '../broker/broker_repository.dart';
import '../mqtt/mqtt_message.dart';
import '../mqtt/session/mqtt_session_controller.dart';
import 'ingested_message.dart';

/// Converts the session stream into one ordered broker-scoped ingestion stream.
class MessageIngestionCoordinator {
  MessageIngestionCoordinator(MqttSessionController session, this._brokers) : _source = session.messageStream;

  MessageIngestionCoordinator.fromStream(Stream<MQTTMessage> source, this._brokers) : _source = source;

  final Stream<MQTTMessage> _source;
  final BrokerRepository _brokers;
  final StreamController<IngestedMessage> _messages = StreamController<IngestedMessage>.broadcast(sync: true);
  final Map<String, int> _sequences = {};

  StreamSubscription<MQTTMessage>? _subscription;
  String? _activeBrokerId;

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
    _subscription = _source.listen(_onMessage);
  }

  void _onMessage(MQTTMessage message) {
    final brokerId = _brokers.activeBrokerId;
    if (brokerId == null) return;
    final sequence = (_sequences[message.topic] ?? 0) + 1;
    _sequences[message.topic] = sequence;
    _messages.add(
      IngestedMessage(
        brokerId: brokerId,
        topic: message.topic,
        value: TopicNodeValue(payload: message.payload, seq: sequence, receivedAt: message.receivedAt, retain: message.retain, qos: message.qos),
      ),
    );
  }

  void _onBrokerChanged() {
    final brokerId = _brokers.activeBrokerId;
    if (brokerId == _activeBrokerId) return;
    _activeBrokerId = brokerId;
    _sequences.clear();
  }

  /// Stops ingestion and closes the downstream stream.
  Future<void> dispose() async {
    _brokers.removeListener(_onBrokerChanged);
    await _subscription?.cancel();
    _subscription = null;
    await _messages.close();
  }
}
