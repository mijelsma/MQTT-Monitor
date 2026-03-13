import '../../mqtt/connection_status.dart';
import '../../../features/settings/settings_section.dart';
import '../persist.dart';
import '../state_key.dart';

/// Defines the keys used in the app state for managing MQTT connection and settings.
abstract final class AppKeys {
  // persistent
  static final activeBrokerId = StateKey.nullableString('app.activeBrokerId');
  static final disconnected = StateKey.boolean('app.disconnected', defaultValue: false);

  // Non persistent (runtime-only)
  static final activeSettingsSection = StateKey.forEnum('app.activeSettingsSection', SettingsSection.values, defaultValue: SettingsSection.brokers, persist: Persist.never);
  static final connectionStatus = StateKey.forEnum('app.connectionStatus', ConnectionStatus.values, defaultValue: ConnectionStatus.disconnected, persist: Persist.never);
  static final connectionError = StateKey.nullableString('app.connectionError', persist: Persist.never);
  static final messageCount = StateKey.integer('app.messageCount', defaultValue: 0, persist: Persist.never);
  static final messageRate = StateKey.integer('app.messageRate', defaultValue: 0, persist: Persist.never);

  static final List<StateKey> all = [activeBrokerId, disconnected];
}
