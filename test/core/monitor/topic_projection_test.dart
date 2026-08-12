import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/features/monitor/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/features/monitor/search_scope.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';

import '../../support/test_dependencies.dart';

void main() {
  late StreamController<MQTTMessage> source;
  late MessageIngestionCoordinator ingestion;
  late TopicProjection projection;
  late MessageHistoryService history;
  late MonitorWorkspaceController workspace;
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
    await dependencies.brokers.add(
      const BrokerEntry(
        id: 'first',
        name: 'First',
        host: 'first.invalid',
        subscriptions: [SubscriptionEntry(id: 'all', topic: '#')],
      ),
    );
    source = StreamController<MQTTMessage>.broadcast(sync: true);
    ingestion = MessageIngestionCoordinator.fromStream(
      source.stream,
      dependencies.brokers,
    )..initialize();
    projection = TopicProjection(ingestion, dependencies.brokers)..initialize();
    history = MessageHistoryService(
      ingestion,
      dependencies.state,
      dependencies.brokers,
    )..initialize();
    workspace = MonitorWorkspaceController(
      projection: projection,
      history: history,
      state: dependencies.state,
    );
  });

  tearDown(() async {
    workspace.dispose();
    projection.dispose();
    await history.dispose();
    await ingestion.dispose();
    await source.close();
  });

  test(
    'inserts sorted branch topics with incremental counts and one shared value',
    () {
      source
        ..add(_message('plant', 'online', 1, retain: true, qos: 2))
        ..add(_message('plant/temperature', '21', 2))
        ..add(_message('Alpha/value', '1', 3))
        ..add(_message('beta/value', '2', 4));

      expect(projection.roots.map((node) => node.segment), [
        'Alpha',
        'beta',
        'plant',
      ]);
      final plant = projection.pathFor('plant').single;
      expect(plant.valueNotifier.value?.payload, 'online');
      expect(plant.valueNotifier.value?.retain, isTrue);
      expect(plant.valueNotifier.value?.qos, 2);
      expect(
        plant.valueNotifier.value?.receivedAt,
        DateTime(2026, 1, 1, 0, 0, 1),
      );
      expect(plant.metricsNotifier.value.topicCount, 2);
      expect(plant.metricsNotifier.value.messageCount, 2);
      expect(plant.children.values.single.metricsNotifier.value.topicCount, 1);
      expect(
        identical(
          history.getHistory('plant').single,
          plant.valueNotifier.value,
        ),
        isTrue,
      );
    },
  );

  test(
    'filters by topic and value while keeping topic-filter counts granular',
    () {
      source
        ..add(_message('factory/alpha', 'warm', 1))
        ..add(_message('factory/beta', 'cold', 2));
      workspace.expandAll();
      workspace.setScope(SearchScope.topic);
      workspace.setFilter('alpha');

      expect(workspace.visibleRows.map((row) => row.node.fullPath), [
        'factory',
        'factory/alpha',
      ]);
      final derivations = workspace.visibleRowDerivationCount;
      source.add(_message('factory/alpha', 'warmer', 3));

      expect(workspace.visibleRowDerivationCount, derivations);
      expect(workspace.visibleRows.first.metrics.value.messageCount, 2);

      workspace.setScope(SearchScope.value);
      workspace.setFilter('hot');
      expect(workspace.visibleRows, isEmpty);
      source.add(_message('factory/beta', 'hot', 4));
      expect(workspace.visibleRows.map((row) => row.node.fullPath), [
        'factory',
        'factory/beta',
      ]);
    },
  );

  test(
    'value-only traffic updates narrow signals without rebuilding visible rows',
    () {
      source.add(_message('load/topic', '0', 1));
      final node = projection.pathFor('load/topic').last;
      final derivations = workspace.visibleRowDerivationCount;
      var structuralNotifications = 0;
      var valueNotifications = 0;
      projection.addListener(() => structuralNotifications++);
      node.valueNotifier.addListener(() => valueNotifications++);

      for (var index = 1; index <= 1000; index++) {
        source.add(_message('load/topic', '$index', index % 60));
      }

      expect(valueNotifications, 1000);
      expect(structuralNotifications, 0);
      expect(workspace.visibleRowDerivationCount, derivations);
      expect(node.metricsNotifier.value.messageCount, 1001);
    },
  );

  test(
    'deletion uses topic boundaries, repairs counts, and clears matching history',
    () {
      source
        ..add(_message('foo/bar', 'delete', 1))
        ..add(_message('foo/bar/child', 'delete child', 2))
        ..add(_message('foo/barista', 'keep', 3));
      final root = projection.pathFor('foo').single;
      final deleted = projection.pathFor('foo/bar').last;
      final kept = projection.pathFor('foo/barista').last;
      workspace.selectNode(kept);

      workspace.deleteTopic(deleted);

      expect(projection.pathFor('foo/bar'), isEmpty);
      expect(projection.pathFor('foo/barista').last, same(kept));
      expect(workspace.selectedNode, same(kept));
      expect(root.metricsNotifier.value.topicCount, 1);
      expect(root.metricsNotifier.value.messageCount, 1);
      expect(history.getHistory('foo/bar'), isEmpty);
      expect(history.getHistory('foo/bar/child'), isEmpty);
      expect(history.getHistory('foo/barista').single.payload, 'keep');

      source.add(_message('foo/bar', 'new', 4));
      expect(projection.pathFor('foo/bar').last.valueNotifier.value?.seq, 1);
    },
  );

  test(
    'broker switches clear projections and restart topic sequences',
    () async {
      source.add(_message('same/topic', 'first', 1));
      await dependencies.brokers.add(
        const BrokerEntry(
          id: 'second',
          name: 'Second',
          host: 'second.invalid',
          subscriptions: [SubscriptionEntry(id: 'all', topic: '#')],
        ),
      );

      expect(projection.roots, isEmpty);
      expect(history.getHistory('same/topic'), isEmpty);
      source.add(_message('same/topic', 'second', 2));

      expect(projection.pathFor('same/topic').last.valueNotifier.value?.seq, 1);
      expect(history.getHistory('same/topic').single.payload, 'second');
    },
  );
}

MQTTMessage _message(
  String topic,
  String payload,
  int second, {
  bool retain = false,
  int qos = 0,
}) => MQTTMessage(
  topic: topic,
  payload: payload,
  receivedAt: DateTime(2026, 1, 1, 0, 0, second),
  retain: retain,
  qos: qos,
);
