import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/publishing/qos_preferences_repository.dart';
import 'package:mqtt_monitor/models/mqtt_qos_default.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
  });

  group('SettingsViewModel default QoS', () {
    test('defaults subscriptions to QoS 0 and publishing to QoS 1', () {
      final vm = dependencies.createSettingsViewModel();
      expect(vm.defaultPublishQos, MqttQosDefault.qos1);
      expect(vm.defaultShortcutQos, MqttQosDefault.qos1);
      expect(vm.defaultSubscribeQos, MqttQosDefault.qos0);
    });

    test('lastUsedQos defaults to 1 so the "last used" option also starts at QoS 1', () {
      final vm = dependencies.createSettingsViewModel();
      expect(vm.lastUsedQos, 1);
    });

    test('resolveDefaultQos returns the explicit QoS for fixed strategies', () {
      final vm = dependencies.createSettingsViewModel();
      vm.setDefaultPublishQos(MqttQosDefault.qos0);
      vm.recordQos(2);
      // The "fixed" strategy ignores the last-used value.
      expect(vm.resolveDefaultQos(vm.defaultPublishQos), 0);
    });

    test('resolveDefaultQos falls through to lastUsedQos for the lastUsed strategy', () {
      final vm = dependencies.createSettingsViewModel();
      vm.recordQos(2);
      expect(vm.resolveDefaultQos(MqttQosDefault.lastUsed), 2);
      vm.recordQos(0);
      expect(vm.resolveDefaultQos(MqttQosDefault.lastUsed), 0);
    });

    test('recordQos clamps out-of-range picks', () {
      final vm = dependencies.createSettingsViewModel();
      vm.recordQos(-1);
      expect(vm.lastUsedQos, 0);
      vm.recordQos(99);
      expect(vm.lastUsedQos, 2);
    });

    test('recording survives a settings read cycle through shared prefs', () async {
      final vm = dependencies.createSettingsViewModel();
      vm.recordQos(2);
      // Force-flush the persistent state and re-read it to confirm the
      // lastUsedQos value round-trips through SharedPreferences.
      final restored = QosPreferencesRepository(dependencies.preferences);
      await restored.initialize();
      expect(restored.lastUsed, 2);
    });

    test('default strategies survive repository recreation', () async {
      await dependencies.qosPreferences.setDefaultPublish(MqttQosDefault.qos0);
      await dependencies.qosPreferences.setDefaultShortcut(MqttQosDefault.lastUsed);
      await dependencies.qosPreferences.setDefaultSubscribe(MqttQosDefault.qos2);

      final restored = QosPreferencesRepository(dependencies.preferences);
      await restored.initialize();

      expect(restored.defaultPublish, MqttQosDefault.qos0);
      expect(restored.defaultShortcut, MqttQosDefault.lastUsed);
      expect(restored.defaultSubscribe, MqttQosDefault.qos2);
    });

    test('reset restores the distinct publish and subscribe defaults', () async {
      await dependencies.qosPreferences.setDefaultPublish(MqttQosDefault.qos0);
      await dependencies.qosPreferences.setDefaultShortcut(MqttQosDefault.qos2);
      await dependencies.qosPreferences.setDefaultSubscribe(MqttQosDefault.qos2);

      await dependencies.qosPreferences.resetToDefaults();

      expect(dependencies.qosPreferences.defaultPublish, MqttQosDefault.qos1);
      expect(dependencies.qosPreferences.defaultShortcut, MqttQosDefault.qos1);
      expect(dependencies.qosPreferences.defaultSubscribe, MqttQosDefault.qos0);
    });
  });
}
