import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_store.dart';

/// Adapts [SharedPreferences] to the repository-facing [PreferencesStore].
class SharedPreferencesStore implements PreferencesStore {
  /// Creates an adapter around an initialized [SharedPreferences] instance.
  const SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  /// Loads the platform preference instance and returns its typed adapter.
  static Future<SharedPreferencesStore> load() async {
    return SharedPreferencesStore(await SharedPreferences.getInstance());
  }

  /// Returns the stored value for [key], or `null` when it is absent.
  @override
  Object? get(String key) => _preferences.get(key);

  /// Returns every key currently present in shared preferences.
  @override
  Set<String> getKeys() => _preferences.getKeys();

  /// Persists a boolean and throws when the platform write fails.
  @override
  Future<void> setBool(String key, bool value) async {
    await _requireSuccess(_preferences.setBool(key, value), key);
  }

  /// Persists an integer and throws when the platform write fails.
  @override
  Future<void> setInt(String key, int value) async {
    await _requireSuccess(_preferences.setInt(key, value), key);
  }

  /// Persists a decimal and throws when the platform write fails.
  @override
  Future<void> setDouble(String key, double value) async {
    await _requireSuccess(_preferences.setDouble(key, value), key);
  }

  /// Persists a string and throws when the platform write fails.
  @override
  Future<void> setString(String key, String value) async {
    await _requireSuccess(_preferences.setString(key, value), key);
  }

  /// Removes [key] and throws when the platform write fails.
  @override
  Future<void> remove(String key) async {
    await _requireSuccess(_preferences.remove(key), key);
  }

  /// Clears all preferences and throws when the platform write fails.
  @override
  Future<void> clear() async {
    await _requireSuccess(_preferences.clear(), 'all preferences');
  }

  /// Converts the boolean platform result into a throwing write contract.
  Future<void> _requireSuccess(Future<bool> operation, String key) async {
    if (!await operation) {
      throw StateError('Could not persist $key.');
    }
  }
}
