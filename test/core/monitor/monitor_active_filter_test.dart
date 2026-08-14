import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/services/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_node_metrics.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/core/monitor/controllers/topic_pulse_controller.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/features/monitor/controllers/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/features/monitor/search_scope.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';
import 'package:mqtt_monitor/core/monitor/models/topic_tree_node_model.dart';

import '../../support/test_dependencies.dart';

void main() {
  late StreamController<MQTTMessage> source;
  late MessageIngestionCoordinator ingestion;
  late TopicProjection projection;
  late MessageHistoryService history;
  late MonitorWorkspaceController workspace;
  late _RecordingTopicPulseController pulses;

  setUp(() async {
    final dependencies = await TestDependencies.create();
    await dependencies.brokers.add(
      const BrokerEntryModel(
        id: 'first',
        name: 'First',
        host: 'first.invalid',
        subscriptions: [SubscriptionEntryModel(id: 'all', topic: '#')],
      ),
    );
    source = StreamController<MQTTMessage>.broadcast(sync: true);
    ingestion = MessageIngestionCoordinator.fromStream(source.stream, dependencies.brokers)..initialize();
    projection = TopicProjection(ingestion, dependencies.brokers)..initialize();
    history = MessageHistoryService(ingestion, dependencies.historyPreferences, dependencies.brokers)..initialize();
    pulses = _RecordingTopicPulseController();
    workspace = MonitorWorkspaceController(projection: projection, history: history, uiPreferences: dependencies.uiPreferences, pulses: pulses);
  });

  tearDown(() async {
    workspace.dispose();
    projection.dispose();
    await history.dispose();
    await ingestion.dispose();
    await source.close();
  });

  test('updates counts incrementally and only rederives rows for membership changes', () {
    source
      ..add(_message('factory/alpha', 'warm', 1))
      ..add(_message('factory/beta', 'hot', 2));
    workspace.expandAll();
    workspace.setScope(SearchScope.value);
    workspace.setFilter('hot');
    pulses.paths.clear();

    expect(workspace.visibleRows.map((row) => row.node.fullPath), ['factory', 'factory/beta']);
    expect(workspace.visibleRows.first.metrics.value, const TopicNodeMetrics(topicCount: 1, messageCount: 1));
    final initialDerivations = workspace.visibleRowDerivationCount;

    source
      ..add(_message('factory/beta', 'hotter', 3))
      ..add(_message('factory/alpha', 'still warm', 4));

    expect(workspace.visibleRowDerivationCount, initialDerivations);
    expect(workspace.visibleRows.first.metrics.value, const TopicNodeMetrics(topicCount: 1, messageCount: 2));
    expect(pulses.paths, ['factory/beta']);

    source.add(_message('factory/alpha', 'now hot', 5));

    expect(workspace.visibleRowDerivationCount, initialDerivations + 1);
    expect(workspace.visibleRows.map((row) => row.node.fullPath), ['factory', 'factory/alpha', 'factory/beta']);
    expect(workspace.visibleRows.first.metrics.value, const TopicNodeMetrics(topicCount: 2, messageCount: 5));
    expect(pulses.paths, ['factory/beta', 'factory/alpha']);

    source
      ..add(_message('factory/beta', 'cold', 6))
      ..add(_message('factory/beta', 'still cold', 7));

    expect(workspace.visibleRowDerivationCount, initialDerivations + 2);
    expect(workspace.visibleRows.map((row) => row.node.fullPath), ['factory', 'factory/alpha']);
    expect(workspace.visibleRows.first.metrics.value, const TopicNodeMetrics(topicCount: 1, messageCount: 3));
    expect(pulses.paths, ['factory/beta', 'factory/alpha']);
  });

  test('combined filters keep topic matches incremental and add payload matches', () {
    source
      ..add(_message('factory/needle-topic', 'cold', 1))
      ..add(_message('factory/other', 'warm', 2));
    workspace.expandAll();
    workspace.setFilter('needle');
    pulses.paths.clear();
    final initialDerivations = workspace.visibleRowDerivationCount;

    source.add(_message('factory/needle-topic', 'still cold', 3));

    expect(workspace.visibleRowDerivationCount, initialDerivations);
    expect(workspace.visibleRows.first.metrics.value, const TopicNodeMetrics(topicCount: 1, messageCount: 2));
    expect(pulses.paths, ['factory/needle-topic']);

    source.add(_message('factory/other', 'now needle', 4));

    expect(workspace.visibleRowDerivationCount, initialDerivations + 1);
    expect(workspace.visibleRows.map((row) => row.node.fullPath), ['factory', 'factory/needle-topic', 'factory/other']);
    expect(workspace.visibleRows.first.metrics.value, const TopicNodeMetrics(topicCount: 2, messageCount: 4));
    expect(pulses.paths, ['factory/needle-topic', 'factory/other']);
  });
}

MQTTMessage _message(String topic, String payload, int second) => MQTTMessage(topic: topic, payload: payload, receivedAt: DateTime(2026, 1, 1, 0, 0, second));

class _RecordingTopicPulseController extends TopicPulseController {
  final List<String> paths = [];

  @override
  void schedule(List<TopicTreeNodeModel> path, int pulsesPerSecond) {
    paths.add(path.last.fullPath);
  }
}
