import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/features/settings/settings_viewmodel.dart';
import 'package:mqtt_monitor/models/mqtt_qos_default.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final state = AppStateManager.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await state.initialize();
    await state.resetAll();
  });

  group('SettingsViewModel default QoS', () {
    test('defaults to fixed QoS 1 for all three strategies', () {
      final vm = SettingsViewModel(state: state);
      expect(vm.defaultPublishQos, MqttQosDefault.qos1);
      expect(vm.defaultShortcutQos, MqttQosDefault.qos1);
      expect(vm.defaultSubscribeQos, MqttQosDefault.qos1);
    });

    test('lastUsedQos defaults to 1 so the "last used" option also starts at QoS 1', () {
      final vm = SettingsViewModel(state: state);
      expect(vm.lastUsedQos, 1);
    });

    test('resolveDefaultQos returns the explicit QoS for fixed strategies', () {
      final vm = SettingsViewModel(state: state);
      vm.setDefaultPublishQos(MqttQosDefault.qos0);
      vm.recordQos(2);
      // The "fixed" strategy ignores the last-used value.
      expect(vm.resolveDefaultQos(vm.defaultPublishQos), 0);
    });

    test('resolveDefaultQos falls through to lastUsedQos for the lastUsed strategy', () {
      final vm = SettingsViewModel(state: state);
      vm.recordQos(2);
      expect(vm.resolveDefaultQos(MqttQosDefault.lastUsed), 2);
      vm.recordQos(0);
      expect(vm.resolveDefaultQos(MqttQosDefault.lastUsed), 0);
    });

    test('recordQos clamps out-of-range picks', () {
      final vm = SettingsViewModel(state: state);
      vm.recordQos(-1);
      expect(vm.lastUsedQos, 0);
      vm.recordQos(99);
      expect(vm.lastUsedQos, 2);
    });

    test('recording survives a settings read cycle through shared prefs', () async {
      final vm = SettingsViewModel(state: state);
      vm.recordQos(2);
      // Force-flush the persistent state and re-read it to confirm the
      // lastUsedQos value round-trips through SharedPreferences.
      state.load(SettingsKeys.lastUsedQos);
      expect(state.read(SettingsKeys.lastUsedQos), 2);
    });
  });
}
