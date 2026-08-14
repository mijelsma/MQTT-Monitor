import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/dashboard/repositories/dashboard_repository.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/dashboard/models/dashboard_layout_model.dart';
import 'package:mqtt_monitor/core/dashboard/models/graph_card_model.dart';

import '../../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
    await dependencies.brokers.add(const BrokerEntryModel(id: 'a', name: 'A', host: 'a.invalid'));
    await dependencies.brokers.add(const BrokerEntryModel(id: 'b', name: 'B', host: 'b.invalid'), makeActive: false);
  });

  test('current dashboard schema round-trips cards, layout CRUD, and active selection', () async {
    final repository = DashboardRepository(dependencies.preferences, dependencies.brokers);
    await repository.initialize();
    expect(dependencies.preferences.get(DashboardRepository.schemaVersionKey), DashboardRepository.currentSchemaVersion);
    final card = _card('pinned');
    final layout = DashboardLayoutModel(id: 'layout', title: 'Layout', brokerIds: const ['a'], cards: [card]);

    await repository.addCard('a', card);
    await repository.setLayouts([layout]);
    await repository.setActiveLayout('a', layout.id);

    final reloaded = DashboardRepository(dependencies.preferences, dependencies.brokers);
    await reloaded.initialize();
    expect(reloaded.cardsForBroker('a').single.toJson(), card.toJson());
    expect(reloaded.layouts.single.toJson(), layout.toJson());
    expect(reloaded.activeLayoutIdForBroker('a'), layout.id);
    repository.dispose();
    reloaded.dispose();
  });

  test('future dashboard schema is rejected without migration or mutation', () async {
    await dependencies.preferences.setInt(DashboardRepository.schemaVersionKey, DashboardRepository.currentSchemaVersion + 1);
    await dependencies.preferences.setString(DashboardRepository.layoutsKey, '[]');
    final repository = DashboardRepository(dependencies.preferences, dependencies.brokers);

    expect(repository.initialize, throwsStateError);
    expect(dependencies.preferences.get(DashboardRepository.schemaVersionKey), DashboardRepository.currentSchemaVersion + 1);
    expect(dependencies.preferences.get(DashboardRepository.layoutsKey), '[]');
    repository.dispose();
  });

  test('rejects the old unlimited representation in the single development schema', () async {
    await dependencies.preferences.setString('${DashboardRepository.cardsKeyPrefix}a', jsonEncode([_card('old').toJson()..['maxDataPoints'] = 0]));
    final repository = DashboardRepository(dependencies.preferences, dependencies.brokers);

    expect(repository.initialize, throwsArgumentError);
    repository.dispose();
  });

  test('broker deletion removes dynamic keys and repairs scoped layouts', () async {
    final repository = DashboardRepository(dependencies.preferences, dependencies.brokers);
    await repository.initialize();
    await repository.setCards('a', [_card('a-card')]);
    await repository.setActiveLayout('a', 'a-only');
    await repository.setLayouts([
      DashboardLayoutModel(id: 'a-only', title: 'A', brokerIds: const ['a'], cards: [_card('a-card')]),
      DashboardLayoutModel(id: 'shared', title: 'Shared', brokerIds: const ['a', 'b']),
      DashboardLayoutModel(id: 'global', title: 'Global'),
    ]);

    await dependencies.brokers.delete('a');
    await repository.synchronizeBrokers();

    expect(dependencies.preferences.get('${DashboardRepository.cardsKeyPrefix}a'), isNull);
    expect(dependencies.preferences.get('${DashboardRepository.activeLayoutKeyPrefix}a'), isNull);
    expect(repository.layouts.map((layout) => layout.id), ['shared', 'global']);
    expect(repository.layouts.first.brokerIds, ['b']);
    repository.dispose();
  });

  test('initialization deletes orphan broker keys without touching valid data', () async {
    await dependencies.preferences.setString('${DashboardRepository.cardsKeyPrefix}orphan', jsonEncode([_card('orphan').toJson()]));
    await dependencies.preferences.setString('${DashboardRepository.activeLayoutKeyPrefix}orphan', 'missing');
    final repository = DashboardRepository(dependencies.preferences, dependencies.brokers);

    await repository.initialize();

    expect(dependencies.preferences.get('${DashboardRepository.cardsKeyPrefix}orphan'), isNull);
    expect(dependencies.preferences.get('${DashboardRepository.activeLayoutKeyPrefix}orphan'), isNull);
    repository.dispose();
  });
}

GraphCardModel _card(String id) => GraphCardModel(id: id, topic: 'sensor/value', displayName: id, colorValue: 0xFF123456, maxDataPoints: 500);
