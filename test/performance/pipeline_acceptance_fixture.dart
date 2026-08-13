import 'dart:async';

import 'package:mqtt_monitor/core/dashboard/dashboard_repository.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_series_store.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/graph_card_model.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';
import 'package:mqtt_monitor/models/subscription_history_policy.dart';

import '../support/test_dependencies.dart';

/// Raw measurements returned by one asynchronous traffic replay.
typedef TrafficRun = ({int messages, int peakBacklog, Duration enqueueElapsed, Duration totalElapsed, double messagesPerSecond});

/// Wires the production ingestion projections to a controlled asynchronous source.
class PipelineAcceptanceFixture {
  PipelineAcceptanceFixture._({required this.dependencies, required this.source, required this.ingestion, required this.projection, required this.history, required this.dashboardRepository, required this.dashboard});

  static const brokerId = 'performance-broker';

  final TestDependencies dependencies;
  final StreamController<MQTTMessage> source;
  final MessageIngestionCoordinator ingestion;
  final TopicProjection projection;
  final MessageHistoryService history;
  final DashboardRepository dashboardRepository;
  final DashboardSeriesStore dashboard;

  StreamSubscription<Object?>? _completionSubscription;
  int _emitted = 0;
  int _processed = 0;
  int _peakBacklog = 0;
  int? _completionTarget;
  Completer<void>? _completion;

  int get processed => _processed;

  static Future<PipelineAcceptanceFixture> create({int historyRetention = 10, bool historyEnabled = true, int maximumRetention = 1000, List<GraphCardModel> cards = const []}) async {
    final dependencies = await TestDependencies.create();
    await dependencies.historyPreferences.setMaximumRetention(maximumRetention);
    await dependencies.brokers.add(
      BrokerEntry(
        id: brokerId,
        name: 'Performance broker',
        host: 'performance.invalid',
        subscriptions: [
          SubscriptionEntry(
            id: 'all-topics',
            topic: '#',
            history: SubscriptionHistoryPolicy(enabled: historyEnabled, retention: historyRetention),
          ),
        ],
      ),
    );
    final dashboardRepository = DashboardRepository(dependencies.preferences, dependencies.brokers);
    await dashboardRepository.initialize();
    await dashboardRepository.setCards(brokerId, cards);

    final source = StreamController<MQTTMessage>.broadcast();
    final ingestion = MessageIngestionCoordinator.fromStream(source.stream, dependencies.brokers, timeSliced: true);
    final projection = TopicProjection(ingestion, dependencies.brokers, coalesceStructureUpdates: true)..initialize();
    final history = MessageHistoryService(ingestion, dependencies.historyPreferences, dependencies.brokers)..initialize();
    final dashboard = DashboardSeriesStore(messages: ingestion.messages, repository: dashboardRepository, variables: dependencies.variables, templateResolver: dependencies.templateResolver)..initialize();
    final fixture = PipelineAcceptanceFixture._(dependencies: dependencies, source: source, ingestion: ingestion, projection: projection, history: history, dashboardRepository: dashboardRepository, dashboard: dashboard);
    fixture._completionSubscription = ingestion.messages.listen(fixture._onProcessed);
    ingestion.initialize();
    return fixture;
  }

  /// Enqueues [messages], then waits until every downstream synchronous projection ran.
  Future<TrafficRun> replay(Iterable<MQTTMessage> messages) async {
    if (_completion != null) {
      throw StateError('Traffic replays must not overlap.');
    }
    final batch = messages.toList(growable: false);
    _peakBacklog = 0;
    final target = _processed + batch.length;
    final completion = Completer<void>();
    _completionTarget = target;
    _completion = completion;
    final total = Stopwatch()..start();
    final enqueue = Stopwatch()..start();
    for (final message in batch) {
      source.add(message);
      _emitted++;
      _observeBacklog();
    }
    enqueue.stop();
    if (batch.isEmpty) completion.complete();
    await completion.future;
    total.stop();
    _completion = null;
    _completionTarget = null;
    final seconds = total.elapsedMicroseconds / Duration.microsecondsPerSecond;
    return (messages: batch.length, peakBacklog: _peakBacklog, enqueueElapsed: enqueue.elapsed, totalElapsed: total.elapsed, messagesPerSecond: seconds == 0 ? double.infinity : batch.length / seconds);
  }

  void _onProcessed(Object? _) {
    _processed++;
    _observeBacklog();
    if (_processed == _completionTarget && !(_completion?.isCompleted ?? true)) {
      _completion!.complete();
    }
  }

  void _observeBacklog() {
    final backlog = _emitted - _processed;
    if (backlog > _peakBacklog) _peakBacklog = backlog;
  }

  Future<void> dispose() async {
    await _completionSubscription?.cancel();
    await dashboard.dispose();
    await history.dispose();
    await projection.shutdown();
    projection.dispose();
    await ingestion.dispose();
    await source.close();
    dashboardRepository.dispose();
  }
}
