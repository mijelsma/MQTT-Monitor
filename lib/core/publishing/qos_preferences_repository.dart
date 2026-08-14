import 'package:flutter/foundation.dart';

import '../../models/mqtt_qos_default.dart';
import '../storage/preferences_store.dart';

/// Owns default and last-used QoS preferences for publish workflows.
class QosPreferencesRepository extends ChangeNotifier {
  QosPreferencesRepository(this._store);

  static const String schemaVersionKey = 'qos.schemaVersion';
  static const String defaultPublishKey = 'settings.defaultPublishQos';
  static const String defaultShortcutKey = 'settings.defaultShortcutQos';
  static const String defaultSubscribeKey = 'settings.defaultSubscribeQos';
  static const String lastUsedKey = 'settings.lastUsedQos';
  static const int currentSchemaVersion = 1;
  static const MqttQosDefault defaultPublishValue = MqttQosDefault.qos1;
  static const MqttQosDefault defaultShortcutValue = MqttQosDefault.qos1;
  static const MqttQosDefault defaultSubscribeValue = MqttQosDefault.qos0;
  static const int defaultLastUsedValue = 1;

  final PreferencesStore _store;

  MqttQosDefault _defaultPublish = defaultPublishValue;
  MqttQosDefault _defaultShortcut = defaultShortcutValue;
  MqttQosDefault _defaultSubscribe = defaultSubscribeValue;
  int _lastUsed = defaultLastUsedValue;

  MqttQosDefault get defaultPublish => _defaultPublish;
  MqttQosDefault get defaultShortcut => _defaultShortcut;
  MqttQosDefault get defaultSubscribe => _defaultSubscribe;
  int get lastUsed => _lastUsed;

  Future<void> initialize() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
    } else if (version != currentSchemaVersion) {
      throw StateError('Unsupported QoS schema version: $version');
    }
    _defaultPublish = _decode(defaultPublishKey, defaultPublishValue);
    _defaultShortcut = _decode(defaultShortcutKey, defaultShortcutValue);
    _defaultSubscribe = _decode(defaultSubscribeKey, defaultSubscribeValue);
    final storedLastUsed = _store.get(lastUsedKey);
    if (storedLastUsed != null && (storedLastUsed is! int || storedLastUsed < 0 || storedLastUsed > 2)) {
      throw const FormatException('Last-used QoS must be 0, 1, or 2.');
    }
    _lastUsed = storedLastUsed as int? ?? defaultLastUsedValue;
    notifyListeners();
  }

  Future<void> setDefaultPublish(MqttQosDefault value) => _setDefault(value, defaultPublishKey, (next) => _defaultPublish = next);

  Future<void> setDefaultShortcut(MqttQosDefault value) => _setDefault(value, defaultShortcutKey, (next) => _defaultShortcut = next);

  Future<void> setDefaultSubscribe(MqttQosDefault value) => _setDefault(value, defaultSubscribeKey, (next) => _defaultSubscribe = next);

  Future<void> record(int value) async {
    final next = value.clamp(0, 2);
    if (_lastUsed == next) return;
    _lastUsed = next;
    notifyListeners();
    await _store.setInt(lastUsedKey, next);
  }

  int resolve(MqttQosDefault strategy) => strategy.resolve(_lastUsed);

  Future<void> resetToDefaults() async {
    await _store.remove(defaultPublishKey);
    await _store.remove(defaultShortcutKey);
    await _store.remove(defaultSubscribeKey);
    await _store.remove(lastUsedKey);
    _defaultPublish = defaultPublishValue;
    _defaultShortcut = defaultShortcutValue;
    _defaultSubscribe = defaultSubscribeValue;
    _lastUsed = defaultLastUsedValue;
    notifyListeners();
  }

  Future<void> _setDefault(MqttQosDefault value, String key, ValueChanged<MqttQosDefault> assign) async {
    assign(value);
    notifyListeners();
    await _store.setString(key, value.name);
  }

  MqttQosDefault _decode(String key, MqttQosDefault fallback) {
    final raw = _store.get(key);
    if (raw == null) return fallback;
    if (raw is! String) throw FormatException('$key must be a QoS strategy.');
    return MqttQosDefault.values.firstWhere((value) => value.name == raw, orElse: () => throw FormatException('$key has an unknown QoS strategy.'));
  }
}
