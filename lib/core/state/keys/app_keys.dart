import '../../../features/settings/settings_section.dart';
import '../persist.dart';
import '../state_key.dart';

/// Defines non-domain application UI state.
abstract final class AppKeys {
  static final activeSettingsSection = StateKey.forEnum('app.activeSettingsSection', SettingsSection.values, defaultValue: SettingsSection.brokers, persist: Persist.never);

  static final List<StateKey> all = [];
}
