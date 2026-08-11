import 'dart:io';

import '../../../../models/broker_entry.dart';
import '../../client_certificate_service.dart';

/// Applies app-owned mTLS credentials and certificate policy to MQTT clients.
class MqttTlsConfigurator {
  /// Creates a configurator backed by [certificates].
  MqttTlsConfigurator({ClientCertificateService? certificates}) : _certificates = certificates ?? ClientCertificateService();

  final ClientCertificateService _certificates;

  /// Configures [client] when [broker] has an app-owned certificate bundle.
  Future<void> configure(dynamic client, BrokerEntry broker) async {
    final config = broker.clientCertificates;
    if (config.isEmpty) return;
    client.securityContext = await _certificates.buildSecurityContext(config);
    if (!broker.validateCertificates) {
      client.onBadCertificate = (dynamic _) => true;
      return;
    }
    if (config.rootCaPath != null) {
      client.onBadCertificate = (dynamic certificate) {
        if (certificate is! X509Certificate) return false;
        final now = DateTime.now();
        return !now.isBefore(certificate.startValidity) && !now.isAfter(certificate.endValidity);
      };
    }
  }
}
