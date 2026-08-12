import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/publishing/shortcut_repository.dart';
import 'package:mqtt_monitor/core/publishing/json_payload_validator.dart';
import 'package:mqtt_monitor/core/publishing/variable_repository.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/environment_variable.dart';
import 'package:mqtt_monitor/models/publish_shortcut.dart';

import '../../support/test_dependencies.dart';

void main() {
  test(
    'variable rename and delete keep definitions and values consistent',
    () async {
      final dependencies = await TestDependencies.create();
      final repository = dependencies.variables;
      await repository.add(EnvironmentVariable(name: 'OLD'));
      await repository.setValue('OLD', 'value');

      await repository.update('OLD', EnvironmentVariable(name: 'NEW'));
      expect(repository.variables.single.name, 'NEW');
      expect(repository.values, {'NEW': 'value'});

      await repository.delete('NEW');
      expect(repository.variables, isEmpty);
      expect(repository.values, isEmpty);
    },
  );

  test(
    'variable definitions and values survive repository recreation',
    () async {
      final dependencies = await TestDependencies.create();
      await dependencies.variables.add(EnvironmentVariable(name: 'SITE'));
      await dependencies.variables.setValue('SITE', 'west');

      final restored = VariableRepository(
        dependencies.preferences,
        dependencies.brokers,
        dependencies.templateResolver,
      );
      await restored.initialize();
      addTearDown(restored.dispose);

      expect(restored.variables.single.name, 'SITE');
      expect(restored.values, {'SITE': 'west'});
    },
  );

  test(
    'broker deletion removes orphaned scoped variables and shortcuts',
    () async {
      final dependencies = await TestDependencies.create();
      await dependencies.brokers.add(
        const BrokerEntry(id: 'one', name: 'One', host: 'one.invalid'),
      );
      await dependencies.brokers.add(
        const BrokerEntry(id: 'two', name: 'Two', host: 'two.invalid'),
        makeActive: false,
      );
      await dependencies.variables.add(
        EnvironmentVariable(name: 'DEVICE', brokerIds: const ['one']),
      );
      await dependencies.variables.setValue('DEVICE', 'lamp');
      await dependencies.shortcuts.add(
        _shortcut('scoped', brokerIds: const ['one']),
      );
      await dependencies.shortcuts.add(
        _shortcut('shared', brokerIds: const ['one', 'two']),
      );

      await dependencies.brokers.delete('one');
      await Future<void>.delayed(Duration.zero);

      expect(dependencies.variables.variables, isEmpty);
      expect(dependencies.variables.values, isEmpty);
      expect(dependencies.shortcuts.shortcuts.map((shortcut) => shortcut.id), [
        'shared',
      ]);
      expect(dependencies.shortcuts.shortcuts.single.brokerIds, ['two']);
    },
  );

  test('variable values are visible only inside their broker scope', () async {
    final dependencies = await TestDependencies.create();
    await dependencies.brokers.add(
      const BrokerEntry(id: 'one', name: 'One', host: 'one.invalid'),
    );
    await dependencies.brokers.add(
      const BrokerEntry(id: 'two', name: 'Two', host: 'two.invalid'),
      makeActive: false,
    );
    await dependencies.variables.add(EnvironmentVariable(name: 'GLOBAL'));
    await dependencies.variables.add(
      EnvironmentVariable(name: 'PRIVATE', brokerIds: const ['one']),
    );
    await dependencies.variables.setValue('GLOBAL', 'shared');
    await dependencies.variables.setValue('PRIVATE', 'secret');

    expect(dependencies.variables.valuesForBroker('one'), {
      'GLOBAL': 'shared',
      'PRIVATE': 'secret',
    });
    expect(dependencies.variables.valuesForBroker('two'), {'GLOBAL': 'shared'});
  });

  test(
    'shortcuts use stable IDs for update, reorder, and persistence',
    () async {
      final dependencies = await TestDependencies.create();
      await dependencies.shortcuts.add(_shortcut('first'));
      await dependencies.shortcuts.add(_shortcut('second'));
      await dependencies.shortcuts.update(
        _shortcut('first').copyWith(name: 'Updated'),
      );
      await dependencies.shortcuts.reorder(0, 2);

      expect(dependencies.shortcuts.shortcuts.map((shortcut) => shortcut.id), [
        'second',
        'first',
      ]);
      expect(dependencies.shortcuts.shortcuts.last.name, 'Updated');

      final restored = ShortcutRepository(
        dependencies.preferences,
        dependencies.brokers,
        dependencies.templateResolver,
        const JsonPayloadValidator(),
      );
      await restored.initialize();
      addTearDown(restored.dispose);
      expect(restored.shortcuts.map((shortcut) => shortcut.id), [
        'second',
        'first',
      ]);
    },
  );
}

PublishShortcut _shortcut(String id, {List<String> brokerIds = const []}) {
  return PublishShortcut(
    id: id,
    name: id,
    topic: r'devices/${DEVICE}/set',
    payload: '{"enabled":true}',
    payloadFormatIsJson: true,
    qos: 1,
    colorValue: 0xFF000000,
    brokerIds: brokerIds,
  );
}
