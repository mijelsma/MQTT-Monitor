import 'package:flutter/foundation.dart';

import '../storage/preferences_store.dart';
import '../storage/shared_preferences_store.dart';
import 'keys/app_keys.dart';
import 'keys/layout_keys.dart';
import 'keys/settings_keys.dart';
import 'persist.dart';
import 'state_key.dart';

/// Owns remaining generic application state and persists registered keys.
///
/// Persisted operations use [PreferencesStore], while runtime values remain
/// in memory and changes notify interested widgets.
class AppStateManager extends ChangeNotifier {
  AppStateManager._();

  static final AppStateManager instance = AppStateManager._();

  static final _allKeys = [...AppKeys.all, ...SettingsKeys.all, ...LayoutKeys.all];

  late PreferencesStore _preferences;
  final Map<String, dynamic> _store = {};

  /// Loads persisted values, resolving unconditional keys before gated keys.
  Future<void> initialize({PreferencesStore? preferences}) async {
    _preferences = preferences ?? await SharedPreferencesStore.load();
    for (final key in _allKeys) {
      if (key.persist == Persist.always) _load(key);
    }
    for (final key in _allKeys) {
      if (key.persist.resolve(read)) _load(key);
    }
  }

  /// Loads a single dynamic key from SharedPreferences into the in-memory
  /// store. Use this for keys that aren't in [_allKeys] (e.g. per-broker
  /// dashboard cards).
  void load<T>(StateKey<T> key) => _load(key);

  /// Returns the current value for [key], or its default if unset.
  T read<T>(StateKey<T> key) => _store[key.key] as T? ?? key.defaultValue;

  /// Updates [key] to [value], persists if needed, and notifies listeners.
  Future<void> write<T>(StateKey<T> key, T value) async {
    _store[key.key] = value;
    await _save(key, value);
    notifyListeners();
  }

  /// Removes [key] from both the in-memory store and disk.
  Future<void> reset<T>(StateKey<T> key) async {
    _store.remove(key.key);
    await _preferences.remove(key.key);
    notifyListeners();
  }

  /// Wipes everything — in-memory and on disk.
  Future<void> resetAll() async {
    _store.clear();
    await _preferences.clear();
    notifyListeners();
  }

  /// Reads a single key from SharedPreferences into the store.
  void _load<T>(StateKey<T> key) {
    final raw = _preferences.get(key.key);
    if (raw == null) return;
    try {
      _store[key.key] = key.decode(raw);
    } catch (_) {}
  }

  /// Writes [value] to SharedPreferences if the key is persistent.
  /// SharedPreferences needs typed setters, so we match on the
  /// encoded type.
  Future<void> _save<T>(StateKey<T> key, T value) async {
    if (!key.persist.resolve(read)) return;
    final raw = key.encode(value);
    switch (raw) {
      case null:
        await _preferences.remove(key.key);
      case final bool v:
        await _preferences.setBool(key.key, v);
      case final int v:
        await _preferences.setInt(key.key, v);
      case final double v:
        await _preferences.setDouble(key.key, v);
      case final String v:
        await _preferences.setString(key.key, v);
    }
  }
}
