/// Represents the connection status of an MQTT client.
enum ConnectionStatus {
  /// The client is not connected to any broker.
  disconnected,

  /// The client is in the process of connecting to a broker.
  connecting,

  /// The client is successfully connected to a broker and can
  /// send/receive messages.
  connected,

  /// The client encountered an error during connection or while connected.
  /// The specific error can be found in the `connectionError` state key.
  error,

  /// The client could not find the broker's host. This typically indicates
  /// a DNS resolution failure or an incorrect hostname.
  errorHostNotFound,

  /// The client is not permitted to connect to the broker. This can occur
  /// due to network policies, firewall rules, or broker configurations
  /// that block the connection attempt.
  errorNotPermitted,

  /// The broker refused the connection attempt. This can happen if the
  /// broker is configured to reject connections from certain clients, if
  /// the maximum number of connections has been reached, or if there are
  /// authentication issues.
  errorRefused,

  /// TLS handshake failed.
  errorTlsHandshake,
}
