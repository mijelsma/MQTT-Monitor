import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/publishing/repositories/shortcut_repository.dart';
import 'package:mqtt_monitor/core/publishing/json_payload_validator.dart';
import 'package:mqtt_monitor/core/publishing/repositories/variable_repository.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/publishing/models/environment_variable_model.dart';
import 'package:mqtt_monitor/core/publishing/models/publish_shortcut_model.dart';

import '../../../support/test_dependencies.dart';

void main() {
  test('variable rename and delete keep definitions and values consistent', () async {
    final dependencies = await TestDependencies.create();
    final repository = dependencies.variables;
    await repository.add(EnvironmentVariableModel(name: 'OLD'));
    await repository.setValue('OLD', 'value');

    await repository.update('OLD', EnvironmentVariableModel(name: 'NEW'));
    expect(repository.variables.single.name, 'NEW');
    expect(repository.values, {'NEW': 'value'});

    await repository.delete('NEW');
    expect(repository.variables, isEmpty);
    expect(repository.values, isEmpty);
  });

  test('variable definitions and values survive repository recreation', () async {
    final dependencies = await TestDependencies.create();
    await dependencies.variables.add(EnvironmentVariableModel(name: 'SITE'));
    await dependencies.variables.setValue('SITE', 'west');

    final restored = VariableRepository(dependencies.preferences, dependencies.brokers, dependencies.templateResolver);
    await restored.initialize();
    addTearDown(restored.dispose);

    expect(restored.variables.single.name, 'SITE');
    expect(restored.values, {'SITE': 'west'});
  });

  test('broker deletion removes orphaned scoped variables and shortcuts', () async {
    final dependencies = await TestDependencies.create();
    await dependencies.brokers.add(const BrokerEntryModel(id: 'one', name: 'One', host: 'one.invalid'));
    await dependencies.brokers.add(const BrokerEntryModel(id: 'two', name: 'Two', host: 'two.invalid'), makeActive: false);
    await dependencies.variables.add(EnvironmentVariableModel(name: 'DEVICE', brokerIds: const ['one']));
    await dependencies.variables.setValue('DEVICE', 'lamp');
    await dependencies.shortcuts.add(_shortcut('scoped', brokerIds: const ['one']));
    await dependencies.shortcuts.add(_shortcut('shared', brokerIds: const ['one', 'two']));

    await dependencies.brokers.delete('one');
    await Future<void>.delayed(Duration.zero);

    expect(dependencies.variables.variables, isEmpty);
    expect(dependencies.variables.values, isEmpty);
    expect(dependencies.shortcuts.shortcuts.map((shortcut) => shortcut.id), ['shared']);
    expect(dependencies.shortcuts.shortcuts.single.brokerIds, ['two']);
  });

  test('variable values are visible only inside their broker scope', () async {
    final dependencies = await TestDependencies.create();
    await dependencies.brokers.add(const BrokerEntryModel(id: 'one', name: 'One', host: 'one.invalid'));
    await dependencies.brokers.add(const BrokerEntryModel(id: 'two', name: 'Two', host: 'two.invalid'), makeActive: false);
    await dependencies.variables.add(EnvironmentVariableModel(name: 'GLOBAL'));
    await dependencies.variables.add(EnvironmentVariableModel(name: 'PRIVATE', brokerIds: const ['one']));
    await dependencies.variables.setValue('GLOBAL', 'shared');
    await dependencies.variables.setValue('PRIVATE', 'secret');

    expect(dependencies.variables.valuesForBroker('one'), {'GLOBAL': 'shared', 'PRIVATE': 'secret'});
    expect(dependencies.variables.valuesForBroker('two'), {'GLOBAL': 'shared'});
  });

  test('shortcuts use stable IDs for update, reorder, and persistence', () async {
    final dependencies = await TestDependencies.create();
    await dependencies.shortcuts.add(_shortcut('first'));
    await dependencies.shortcuts.add(_shortcut('second'));
    await dependencies.shortcuts.update(_shortcut('first').copyWith(name: 'Updated'));
    await dependencies.shortcuts.reorder(0, 2);

    expect(dependencies.shortcuts.shortcuts.map((shortcut) => shortcut.id), ['second', 'first']);
    expect(dependencies.shortcuts.shortcuts.last.name, 'Updated');

    final restored = ShortcutRepository(dependencies.preferences, dependencies.brokers, dependencies.templateResolver, const JsonPayloadValidator());
    await restored.initialize();
    addTearDown(restored.dispose);
    expect(restored.shortcuts.map((shortcut) => shortcut.id), ['second', 'first']);
  });

  test('shortcut duplication copies every setting with a new persisted ID', () async {
    final dependencies = await TestDependencies.create();
    final original = _shortcut('original', brokerIds: const ['broker']).copyWith(retain: true);
    await dependencies.brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'broker.invalid'));
    await dependencies.shortcuts.add(original);

    await dependencies.shortcuts.duplicate(original.id);

    final shortcuts = dependencies.shortcuts.shortcuts;
    expect(shortcuts, hasLength(2));
    expect(shortcuts.last.id, isNot(original.id));
    expect(shortcuts.last.toJson()..['id'] = original.id, original.toJson());

    final restored = ShortcutRepository(dependencies.preferences, dependencies.brokers, dependencies.templateResolver, const JsonPayloadValidator());
    await restored.initialize();
    addTearDown(restored.dispose);
    expect(restored.shortcuts.map((shortcut) => shortcut.id), shortcuts.map((shortcut) => shortcut.id));
  });
}

PublishShortcutModel _shortcut(String id, {List<String> brokerIds = const []}) {
  return PublishShortcutModel(id: id, name: id, topic: r'devices/${DEVICE}/set', payload: '{"enabled":true}', payloadFormatIsJson: true, qos: 1, colorValue: 0xFF000000, brokerIds: brokerIds);
}
