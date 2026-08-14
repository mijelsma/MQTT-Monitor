import 'dart:io';
import 'dart:typed_data';

import '../../../core/broker/models/client_certificate_config_model.dart';
import '../interfaces/certificate_file_access_interface.dart';
import '../certificate_validation_exception.dart';
import '../client_certificate_kind.dart';
import '../io_certificate_file_access.dart';

/// Validates PEM credentials and builds the TLS context used by both MQTT
/// protocol clients. DER and PFX/PKCS#12 containers are intentionally out of
/// scope; callers receive a clear validation failure instead of a late connect
/// error.
class ClientCertificateService {
  /// Creates a TLS certificate validator backed by [files].
  ClientCertificateService({CertificateFileAccessInterface? files}) : _files = files ?? const IoCertificateFileAccess();

  final CertificateFileAccessInterface _files;

  /// Validates that [bytes] contain a usable PEM value for [kind].
  void validateBytes(ClientCertificateKind kind, Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const CertificateValidationException('The selected file is empty.');
    }
    final text = String.fromCharCodes(bytes);
    if (!text.contains('-----BEGIN ')) {
      throw const CertificateValidationException('Unsupported certificate format. Select a PEM encoded file; DER and PFX are not supported.');
    }

    try {
      final context = SecurityContext(withTrustedRoots: false);
      switch (kind) {
        case ClientCertificateKind.rootCa:
          context.setTrustedCertificatesBytes(bytes);
        case ClientCertificateKind.privateKey:
          context.usePrivateKeyBytes(bytes);
        case ClientCertificateKind.clientCertificate:
          context.useCertificateChainBytes(bytes);
      }
    } catch (error) {
      final label = switch (kind) {
        ClientCertificateKind.rootCa => 'root CA certificate',
        ClientCertificateKind.privateKey => 'client private key',
        ClientCertificateKind.clientCertificate => 'client certificate',
      };
      throw CertificateValidationException('The $label is malformed or unreadable: $error');
    }
  }

  /// Validates the completeness and contents of [config].
  Future<void> validateConfiguration(ClientCertificateConfigModel config) async {
    if (config.isEmpty) return;
    if (!config.isComplete) {
      throw const CertificateValidationException('Client private key and client certificate are both required for mTLS. The Root CA is optional; leave it empty to validate against the system trusted roots (e.g. Let\'s Encrypt).');
    }
    await buildSecurityContext(config);
  }

  /// Builds a security context from the app-owned paths in [config].
  Future<SecurityContext> buildSecurityContext(ClientCertificateConfigModel config) async {
    if (!config.isComplete) {
      throw const CertificateValidationException('Cannot create an mTLS context without a client private key and client certificate.');
    }

    try {
      final privateKey = await _files.read(config.clientPrivateKeyPath!);
      final certificate = await _files.read(config.clientCertificatePath!);

      validateBytes(ClientCertificateKind.privateKey, privateKey);
      validateBytes(ClientCertificateKind.clientCertificate, certificate);

      // withTrustedRoots: true loads the OS root store (Let's Encrypt, etc.).
      // A custom Root CA, when provided, is layered on top of those roots.
      final context = SecurityContext(withTrustedRoots: true);
      if (config.rootCaPath != null) {
        final rootCa = await _files.read(config.rootCaPath!);
        validateBytes(ClientCertificateKind.rootCa, rootCa);
        context.setTrustedCertificatesBytes(rootCa);
      }
      context.useCertificateChainBytes(certificate);
      context.usePrivateKeyBytes(privateKey);
      return context;
    } on CertificateValidationException {
      rethrow;
    } catch (error) {
      throw CertificateValidationException('A configured certificate file is missing or unreadable: $error');
    }
  }
}
