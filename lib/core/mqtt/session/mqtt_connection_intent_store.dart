import '../../storage/preferences_store.dart';

/// Persists whether the user wants an active MQTT connection.
class MqttConnectionIntentStore {
  /// Creates an intent store backed by [preferences].
  const MqttConnectionIntentStore(PreferencesStore preferences) : _preferences = preferences;

  static const _key = 'mqtt.connectionRequested';
  final PreferencesStore _preferences;

  /// Returns the last requested connection state, defaulting to connected.
  bool get connectionRequested {
    final raw = _preferences.get(_key);
    return raw is bool ? raw : true;
  }

  /// Persists whether a connection is requested.
  Future<void> setConnectionRequested(bool value) => _preferences.setBool(_key, value);
}
