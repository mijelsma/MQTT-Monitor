import '../persist.dart';
import '../state_key.dart';
import 'settings_keys.dart';

abstract final class LayoutKeys {
  // Only persist layout-related keys when the user has "persist layout" enabled.
  static final _whenPersistLayout = Persist.when(SettingsKeys.persistLayout);

  // In the future MQTT topic panels we can manage the state of each panel (open/closed, position etc) here.

  static final List<StateKey> all = [];
}
