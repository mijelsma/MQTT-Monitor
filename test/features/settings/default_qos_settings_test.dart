import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/features/settings/settings_viewmodel.dart';
import 'package:mqtt_monitor/models/mqtt_qos_default.dart';

import '../../support/test_dependencies.dart';

void main() {
  final state = AppStateManager.instance;
  late BrokerRepository brokers;

  setUp(() async {
    final dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
  });

  group('SettingsViewModel default QoS', () {
    test('defaults to fixed QoS 1 for all three strategies', () {
      final vm = SettingsViewModel(state: state, brokerRepository: brokers);
      expect(vm.defaultPublishQos, MqttQosDefault.qos1);
      expect(vm.defaultShortcutQos, MqttQosDefault.qos1);
      expect(vm.defaultSubscribeQos, MqttQosDefault.qos1);
    });

    test('lastUsedQos defaults to 1 so the "last used" option also starts at QoS 1', () {
      final vm = SettingsViewModel(state: state, brokerRepository: brokers);
      expect(vm.lastUsedQos, 1);
    });

    test('resolveDefaultQos returns the explicit QoS for fixed strategies', () {
      final vm = SettingsViewModel(state: state, brokerRepository: brokers);
      vm.setDefaultPublishQos(MqttQosDefault.qos0);
      vm.recordQos(2);
      // The "fixed" strategy ignores the last-used value.
      expect(vm.resolveDefaultQos(vm.defaultPublishQos), 0);
    });

    test('resolveDefaultQos falls through to lastUsedQos for the lastUsed strategy', () {
      final vm = SettingsViewModel(state: state, brokerRepository: brokers);
      vm.recordQos(2);
      expect(vm.resolveDefaultQos(MqttQosDefault.lastUsed), 2);
      vm.recordQos(0);
      expect(vm.resolveDefaultQos(MqttQosDefault.lastUsed), 0);
    });

    test('recordQos clamps out-of-range picks', () {
      final vm = SettingsViewModel(state: state, brokerRepository: brokers);
      vm.recordQos(-1);
      expect(vm.lastUsedQos, 0);
      vm.recordQos(99);
      expect(vm.lastUsedQos, 2);
    });

    test('recording survives a settings read cycle through shared prefs', () async {
      final vm = SettingsViewModel(state: state, brokerRepository: brokers);
      vm.recordQos(2);
      // Force-flush the persistent state and re-read it to confirm the
      // lastUsedQos value round-trips through SharedPreferences.
      state.load(SettingsKeys.lastUsedQos);
      expect(state.read(SettingsKeys.lastUsedQos), 2);
    });
  });
}
