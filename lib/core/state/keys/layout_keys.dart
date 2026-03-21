import '../state_key.dart';

/// Defines the keys used in the app state for managing layout-related settings and preferences.
abstract final class LayoutKeys {
  // TODO: Only persist layout-related keys when the user has "persist layout" enabled.
  // static final _whenPersistLayout = Persist.when(SettingsKeys.persistLayout);

  static final List<StateKey> all = [];
}
