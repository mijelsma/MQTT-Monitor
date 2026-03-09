import '../../ui/settings/settings_section.dart';
import '../persist.dart';
import '../state_key.dart';

// General runtime-state keys
abstract final class AppKeys {
  static final activeBrokerId = StateKey.nullableString('app.activeBrokerId');
  static final activeSettingsSection = StateKey.forEnum('app.activeSettingsSection', SettingsSection.values, defaultValue: SettingsSection.brokers, persist: Persist.never);

  static final List<StateKey> all = [activeBrokerId];
}
