import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_message.dart';
import 'package:mqtt_monitor/features/monitor/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';
import 'package:mqtt_monitor/models/subscription_history_policy.dart';

import '../support/test_dependencies.dart';
import 'traffic_generator.dart';

void main() {
  test('20,000 unique topics remain exact while the event loop stays responsive', () async {
    const topicCount = 20000;
    final dependencies = await TestDependencies.create();
    await dependencies.brokers.add(
      const BrokerEntry(
        id: 'broker',
        name: 'Broker',
        host: 'broker.invalid',
        subscriptions: [SubscriptionEntry(id: 'all', topic: '#', history: SubscriptionHistoryPolicy(enabled: false))],
      ),
    );
    final source = StreamController<MQTTMessage>.broadcast(sync: true);
    final ingestion = MessageIngestionCoordinator.fromStream(source.stream, dependencies.brokers, timeSliced: true);
    final projection = TopicProjection(ingestion, dependencies.brokers, coalesceStructureUpdates: true)..initialize();
    final history = MessageHistoryService(ingestion, dependencies.historyPreferences, dependencies.brokers)..initialize();
    final workspace = MonitorWorkspaceController(projection: projection, history: history, uiPreferences: dependencies.uiPreferences);
    var processed = 0;
    final drained = Completer<void>();
    final completionSubscription = ingestion.messages.listen((_) {
      processed++;
      if (processed == topicCount) drained.complete();
    });
    ingestion.initialize();

    var structuralNotifications = 0;
    projection.addListener(() => structuralNotifications++);
    final traffic = TrafficGenerator(topicCount: 1);
    final firstMessage = ingestion.messages.first;
    source.add(traffic.uniqueTopicMessage(0));
    await firstMessage;
    workspace.expandAll();

    var heartbeatCount = 0;
    var maximumHeartbeatGap = Duration.zero;
    var lastHeartbeat = DateTime.now();
    late Timer heartbeat;
    heartbeat = Timer.periodic(Duration.zero, (_) {
      final now = DateTime.now();
      final gap = now.difference(lastHeartbeat);
      if (gap > maximumHeartbeatGap) maximumHeartbeatGap = gap;
      lastHeartbeat = now;
      heartbeatCount++;
    });

    final stopwatch = Stopwatch()..start();
    for (var topic = 1; topic < topicCount; topic++) {
      source.add(traffic.uniqueTopicMessage(topic));
    }
    await drained.future;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    stopwatch.stop();
    heartbeat.cancel();

    final iot = projection.pathFor('iot').single;
    expect(processed, topicCount);
    expect(iot.metricsNotifier.value.topicCount, topicCount);
    expect(iot.metricsNotifier.value.messageCount, topicCount);
    expect(projection.pathFor('iot/device-${topicCount - 1}/value'), hasLength(3));
    expect(workspace.visibleRows, hasLength(topicCount + 2));
    expect(workspace.visibleRows.any((row) => row.node.fullPath == 'iot/device-${topicCount - 1}'), isTrue);
    expect(history.bufferCount, 0);
    expect(heartbeatCount, greaterThan(20), reason: 'The event loop must service unrelated timers while the burst drains.');
    expect(maximumHeartbeatGap, lessThan(const Duration(milliseconds: 100)), reason: 'No ingestion slice may monopolize the main isolate long enough to present as a frozen UI.');
    expect(structuralNotifications, lessThan(30), reason: 'Structural UI publication must be capped near display cadence, not emitted per topic or ingestion slice.');
    expect(workspace.visibleRowDerivationCount, lessThan(35));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));

    debugPrint('$topicCount unique topics: ${stopwatch.elapsedMicroseconds} us, $structuralNotifications structure notifications, ${workspace.visibleRowDerivationCount} row derivations, $heartbeatCount heartbeats, ${maximumHeartbeatGap.inMicroseconds} us maximum gap');

    await completionSubscription.cancel();
    workspace.dispose();
    projection.dispose();
    await history.dispose();
    await ingestion.dispose();
    await source.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
