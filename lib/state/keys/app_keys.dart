import '../../services/mqtt/models/connection_status.dart';
import '../../ui/settings/settings_section.dart';
import '../persist.dart';
import '../state_key.dart';

// General runtime-state keys
abstract final class AppKeys {
  static final activeBrokerId = StateKey.nullableString('app.activeBrokerId');
  static final activeSettingsSection = StateKey.forEnum('app.activeSettingsSection', SettingsSection.values, defaultValue: SettingsSection.brokers, persist: Persist.never);
  static final connectionStatus = StateKey.forEnum('app.connectionStatus', ConnectionStatus.values, defaultValue: ConnectionStatus.disconnected, persist: Persist.never);
  static final connectionError = StateKey.nullableString('app.connectionError', persist: Persist.never);
  static final disconnected = StateKey.boolean('app.disconnected', defaultValue: false);

  static final List<StateKey> all = [activeBrokerId, disconnected];
}
