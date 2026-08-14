import 'package:flutter/foundation.dart';

import '../../../core/mqtt/models/mqtt_protocol_version_model.dart';
import '../../../core/mqtt/models/startup_connection_model.dart';
import '../../storage/preferences_store.dart';

/// Owns persisted preferences that affect MQTT session startup and telemetry.
class ConnectionPreferencesRepository extends ChangeNotifier {
  ConnectionPreferencesRepository(this._store);

  static const String schemaVersionKey = 'connection.schemaVersion';
  static const int currentSchemaVersion = 1;
  static const String rateIntervalKey = 'settings.rateIntervalMs';
  static const String startupConnectionKey = 'settings.startupConnection';
  static const String defaultBrokerProtocolKey = 'settings.defaultBrokerProtocol';
  static const int defaultRateIntervalMs = 1000;
  static const StartupConnectionModel defaultStartupConnection = StartupConnectionModel.alwaysConnect;
  static const MqttProtocolVersionModel defaultBrokerProtocol = MqttProtocolVersionModel.v5;

  final PreferencesStore _store;

  int _rateIntervalMs = defaultRateIntervalMs;
  StartupConnectionModel _startupConnection = defaultStartupConnection;
  MqttProtocolVersionModel _defaultBrokerProtocol = defaultBrokerProtocol;

  int get rateIntervalMs => _rateIntervalMs;
  StartupConnectionModel get startupConnection => _startupConnection;
  MqttProtocolVersionModel get brokerProtocol => _defaultBrokerProtocol;

  Future<void> initialize() async {
    await _ensureSchema();
    final interval = _store.get(rateIntervalKey);
    _rateIntervalMs = interval is int && interval >= 500 && interval <= 5000 ? interval : defaultRateIntervalMs;
    _startupConnection = _decodeEnum(_store.get(startupConnectionKey), StartupConnectionModel.values, defaultStartupConnection);
    _defaultBrokerProtocol = _decodeEnum(_store.get(defaultBrokerProtocolKey), MqttProtocolVersionModel.values, defaultBrokerProtocol);
    notifyListeners();
  }

  Future<void> setRateIntervalMs(int value) async {
    final next = value.clamp(500, 5000);
    if (_rateIntervalMs == next) return;
    _rateIntervalMs = next;
    notifyListeners();
    await _store.setInt(rateIntervalKey, next);
  }

  Future<void> setStartupConnection(StartupConnectionModel value) async {
    if (_startupConnection == value) return;
    _startupConnection = value;
    notifyListeners();
    await _store.setString(startupConnectionKey, value.name);
  }

  Future<void> setBrokerProtocol(MqttProtocolVersionModel value) async {
    if (_defaultBrokerProtocol == value) return;
    _defaultBrokerProtocol = value;
    notifyListeners();
    await _store.setString(defaultBrokerProtocolKey, value.name);
  }

  Future<void> resetToDefaults() async {
    await _store.remove(rateIntervalKey);
    await _store.remove(startupConnectionKey);
    await _store.remove(defaultBrokerProtocolKey);
    _rateIntervalMs = defaultRateIntervalMs;
    _startupConnection = defaultStartupConnection;
    _defaultBrokerProtocol = defaultBrokerProtocol;
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
