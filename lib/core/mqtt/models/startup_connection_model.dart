/// Controls MQTT connection behavior when the app starts.
enum StartupConnectionModel {
  /// Always connect to the broker on startup.
  alwaysConnect,

  /// Restore the last known connection state (default, current behavior).
  lastStatus,

  /// Never connect on startup — stay disconnected.
  stayDisconnected,
}
