import 'dart:io';

import '../../../../models/broker_entry.dart';
import '../../connection_status.dart';
import '../../mqtt_connection_failure.dart';

/// Maps transport and TLS failures to stable user-facing diagnostics.
abstract final class MqttConnectionErrorMapper {
  /// Maps [error] to a network-oriented connection failure.
  static MqttConnectionFailure socket(SocketException error, BrokerEntry broker) {
    final status = switch (error.osError?.errorCode) {
      1 => ConnectionStatus.errorNotPermitted,
      8 => ConnectionStatus.errorHostNotFound,
      61 || 111 => ConnectionStatus.errorRefused,
      _ => ConnectionStatus.error,
    };
    final (base, suggestion) = switch (status) {
      ConnectionStatus.errorHostNotFound => ("Could not resolve host '${broker.host}'.", 'Check the hostname for typos and verify your DNS or network settings.'),
      ConnectionStatus.errorNotPermitted => ('The operating system blocked the connection.', 'Check your firewall rules, VPN, or network permissions.'),
      ConnectionStatus.errorRefused => ('The broker refused the connection.', 'Verify the broker is running and listening on port ${broker.port}.'),
      _ => ('Network error reaching the broker.', 'Check your network connection and the broker address.'),
    };
    return MqttConnectionFailure(status, '$base\n$suggestion', detail: error.toString());
  }

  /// Maps a TLS handshake [error] for [broker].
  static MqttConnectionFailure tlsHandshake(Object error, BrokerEntry broker) {
    final hasRootCa = broker.clientCertificates.rootCaPath != null;
    final suggestion = broker.validateCertificates
        ? (hasRootCa
              ? 'The broker certificate chain was checked against your Root CA, and expired certificates are rejected, but hostname mismatches are tolerated. Verify that the Root CA signed the broker certificate and that the client certificate and private key match.'
              : 'Provide a Root CA certificate in the broker settings to validate a self-signed broker, or disable "Validate Certificates".')
        : '';
    final message = suggestion.isEmpty ? 'The TLS handshake could not be completed.' : 'The TLS handshake could not be completed.\n$suggestion';
    return MqttConnectionFailure(ConnectionStatus.errorTlsHandshake, message, detail: error.toString());
  }

  /// Maps a local mTLS credential loading [error].
  static MqttConnectionFailure mtls(Object error) {
    return MqttConnectionFailure(ConnectionStatus.errorTlsHandshake, 'Could not load the mTLS credentials.\nVerify the Root CA, client certificate, and private key are valid PEM files.', detail: error.toString());
  }

  /// Returns the generic message used when a connect call gives no reason.
  static String genericConnect(BrokerEntry broker) {
    return 'The broker did not answer the connection request.\nCheck the broker address, port, credentials, and TLS settings.';
  }

  /// Returns the generic message used for a rejected connection.
  static String brokerRejected(BrokerEntry broker) {
    return 'The broker rejected the connection.\nCheck your username, password, Client ID, and TLS settings.';
  }
}
