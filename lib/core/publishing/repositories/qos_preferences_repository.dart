import 'package:flutter/foundation.dart';

import '../../../core/publishing/models/mqtt_qos_default_model.dart';
import '../../storage/preferences_store.dart';

/// Owns default and last-used QoS preferences for publish workflows.
class QosPreferencesRepository extends ChangeNotifier {
  QosPreferencesRepository(this._store);

  static const String schemaVersionKey = 'qos.schemaVersion';
  static const String defaultPublishKey = 'settings.defaultPublishQos';
  static const String defaultShortcutKey = 'settings.defaultShortcutQos';
  static const String defaultSubscribeKey = 'settings.defaultSubscribeQos';
  static const String lastUsedKey = 'settings.lastUsedQos';
  static const int currentSchemaVersion = 1;
  static const MqttQosDefaultModel defaultPublishValue = MqttQosDefaultModel.qos1;
  static const MqttQosDefaultModel defaultShortcutValue = MqttQosDefaultModel.qos1;
  static const MqttQosDefaultModel defaultSubscribeValue = MqttQosDefaultModel.qos0;
  static const int defaultLastUsedValue = 1;

  final PreferencesStore _store;

  MqttQosDefaultModel _defaultPublish = defaultPublishValue;
  MqttQosDefaultModel _defaultShortcut = defaultShortcutValue;
  MqttQosDefaultModel _defaultSubscribe = defaultSubscribeValue;
  int _lastUsed = defaultLastUsedValue;

  MqttQosDefaultModel get defaultPublish => _defaultPublish;
  MqttQosDefaultModel get defaultShortcut => _defaultShortcut;
  MqttQosDefaultModel get defaultSubscribe => _defaultSubscribe;
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

  Future<void> setDefaultPublish(MqttQosDefaultModel value) => _setDefault(value, defaultPublishKey, (next) => _defaultPublish = next);

  Future<void> setDefaultShortcut(MqttQosDefaultModel value) => _setDefault(value, defaultShortcutKey, (next) => _defaultShortcut = next);

  Future<void> setDefaultSubscribe(MqttQosDefaultModel value) => _setDefault(value, defaultSubscribeKey, (next) => _defaultSubscribe = next);

  Future<void> record(int value) async {
    final next = value.clamp(0, 2);
    if (_lastUsed == next) return;
    _lastUsed = next;
    notifyListeners();
    await _store.setInt(lastUsedKey, next);
  }

  int resolve(MqttQosDefaultModel strategy) => strategy.resolve(_lastUsed);

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

  Future<void> _setDefault(MqttQosDefaultModel value, String key, ValueChanged<MqttQosDefaultModel> assign) async {
    assign(value);
    notifyListeners();
    await _store.setString(key, value.name);
  }

  MqttQosDefaultModel _decode(String key, MqttQosDefaultModel fallback) {
    final raw = _store.get(key);
    if (raw == null) return fallback;
    if (raw is! String) throw FormatException('$key must be a QoS strategy.');
    return MqttQosDefaultModel.values.firstWhere((value) => value.name == raw, orElse: () => throw FormatException('$key has an unknown QoS strategy.'));
  }
}
