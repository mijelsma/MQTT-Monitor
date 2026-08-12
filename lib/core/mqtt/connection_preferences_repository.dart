import 'package:flutter/foundation.dart';

import '../../models/startup_connection.dart';
import '../storage/preferences_store.dart';

/// Owns persisted preferences that affect MQTT session startup and telemetry.
class ConnectionPreferencesRepository extends ChangeNotifier {
  ConnectionPreferencesRepository(this._store);

  static const String schemaVersionKey = 'connection.schemaVersion';
  static const int currentSchemaVersion = 1;
  static const String rateIntervalKey = 'settings.rateIntervalMs';
  static const String startupConnectionKey = 'settings.startupConnection';
  static const int defaultRateIntervalMs = 1000;
  static const StartupConnection defaultStartupConnection = StartupConnection.lastStatus;

  final PreferencesStore _store;

  int _rateIntervalMs = defaultRateIntervalMs;
  StartupConnection _startupConnection = defaultStartupConnection;

  int get rateIntervalMs => _rateIntervalMs;
  StartupConnection get startupConnection => _startupConnection;

  Future<void> initialize() async {
    await _ensureSchema();
    final interval = _store.get(rateIntervalKey);
    _rateIntervalMs = interval is int && interval >= 500 && interval <= 5000 ? interval : defaultRateIntervalMs;
    _startupConnection = _decodeEnum(_store.get(startupConnectionKey), StartupConnection.values, defaultStartupConnection);
    notifyListeners();
  }

  Future<void> setRateIntervalMs(int value) async {
    final next = value.clamp(500, 5000);
    if (_rateIntervalMs == next) return;
    _rateIntervalMs = next;
    notifyListeners();
    await _store.setInt(rateIntervalKey, next);
  }

  Future<void> setStartupConnection(StartupConnection value) async {
    if (_startupConnection == value) return;
    _startupConnection = value;
    notifyListeners();
    await _store.setString(startupConnectionKey, value.name);
  }

  Future<void> resetAfterPreferencesClear() async {
    await _store.remove(schemaVersionKey);
    await _store.remove(rateIntervalKey);
    await _store.remove(startupConnectionKey);
    _rateIntervalMs = defaultRateIntervalMs;
    _startupConnection = defaultStartupConnection;
    notifyListeners();
  }

  Future<void> _ensureSchema() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
    } else if (version != currentSchemaVersion) {
      throw StateError('Unsupported connection schema version: $version');
    }
  }
}

T _decodeEnum<T extends Enum>(Object? raw, List<T> values, T fallback) {
  if (raw is! String) return fallback;
  return values.firstWhere((value) => value.name == raw, orElse: () => fallback);
}
