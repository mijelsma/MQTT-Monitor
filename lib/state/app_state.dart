import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'keys/layout_keys.dart';
import 'keys/settings_keys.dart';
import 'persist.dart';
import 'state_key.dart';

class AppStateManager extends ChangeNotifier {
  AppStateManager._();

  // Singleton instance
  static final AppStateManager instance = AppStateManager._();

  late SharedPreferences _preferences;
  final Map<String, dynamic> _store = {};

  // On initialization, we load all keys
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    _loadAll();
  }

  // Load all keys from SharedPreferences
  void _loadAll() {
    // Load persistent keys first, so that conditional keys can read their gate values.
    for (final key in _allKeys) {
      if (key.persist == Persist.always) _loadKey(key);
    }

    // Load conditional keys next, which may depend on the values of the always-persisted keys.
    for (final key in _allKeys) {
      if (key.persist.resolve(read)) _loadKey(key);
    }
  }

  // Load a single key from SharedPreferences
  void _loadKey<T>(StateKey<T> key) {
    final raw = _preferences.get(key.key);
    if (raw == null) return;
    try {
      _store[key.key] = key.decode(raw);
    } catch (_) {
      // Corrupt data — fall back to default.
    }
  }

  // Read a value from the in-memory store
  T read<T>(StateKey<T> key) => _store[key.key] as T? ?? key.defaultValue;

  // Write a value to the in-memory store and persist if needed
  Future<void> write<T>(StateKey<T> key, T value) async {
    _store[key.key] = value;
    await _maybePersist(key, value);
    notifyListeners();
  }

  // Reset a key to its default value
  Future<void> reset<T>(StateKey<T> key) async {
    _store.remove(key.key);
    await _preferences.remove(key.key);
    notifyListeners();
  }

  // Reset all keys to their default values
  Future<void> resetAll() async {
    _store.clear();
    await _preferences.clear();
    notifyListeners();
  }

  // Persist a key if needed
  Future<void> _maybePersist<T>(StateKey<T> key, T value) async {
    if (!key.persist.resolve(read)) return;

    final raw = key.encode(value);

    if (raw == null) {
      await _preferences.remove(key.key);
    } else if (raw is bool) {
      await _preferences.setBool(key.key, raw);
    } else if (raw is int) {
      await _preferences.setInt(key.key, raw);
    } else if (raw is double) {
      await _preferences.setDouble(key.key, raw);
    } else if (raw is String) {
      await _preferences.setString(key.key, raw);
    }
  }

  static final List<StateKey> _allKeys = [...SettingsKeys.all, ...LayoutKeys.all];
}
