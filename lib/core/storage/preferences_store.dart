/// Defines the typed preference operations used by persistence repositories.
abstract interface class PreferencesStore {
  /// Returns the stored value for [key], or `null` when it is absent.
  Object? get(String key);

  /// Returns every key currently present in the store.
  Set<String> getKeys();

  /// Persists a boolean [value] under [key].
  Future<void> setBool(String key, bool value);

  /// Persists an integer [value] under [key].
  Future<void> setInt(String key, int value);

  /// Persists a decimal [value] under [key].
  Future<void> setDouble(String key, double value);

  /// Persists a string [value] under [key].
  Future<void> setString(String key, String value);

  /// Removes [key] when it exists.
  Future<void> remove(String key);

  /// Removes every stored preference.
  Future<void> clear();
}
