import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/client_certificate_config.dart';

enum ClientCertificateKind { rootCa, privateKey, clientCertificate }

class CertificateValidationException implements Exception {
  const CertificateValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class CertificateFileAccess {
  Future<Uint8List> read(String filePath);
  Future<void> write(String filePath, Uint8List bytes);
}

class IoCertificateFileAccess implements CertificateFileAccess {
  const IoCertificateFileAccess();

  @override
  Future<Uint8List> read(String filePath) => File(filePath).readAsBytes();

  @override
  Future<void> write(String filePath, Uint8List bytes) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }
}

typedef CertificateDirectoryProvider = Future<String> Function();

/// Copies credentials into app-private storage. Only these paths are persisted
/// in SharedPreferences; private-key bytes are never stored there.
class AppPrivateCertificateStorage {
  AppPrivateCertificateStorage({required CertificateFileAccess files, required CertificateDirectoryProvider directoryProvider}) : _files = files, _directoryProvider = directoryProvider;

  factory AppPrivateCertificateStorage.standard() {
    return AppPrivateCertificateStorage(files: const IoCertificateFileAccess(), directoryProvider: () async => (await getApplicationSupportDirectory()).path);
  }

  final CertificateFileAccess _files;
  final CertificateDirectoryProvider _directoryProvider;

  Future<String> store(String brokerId, ClientCertificateKind kind, Uint8List bytes, {String? originalFileName}) async {
    final root = await _directoryProvider();
    final baseName = _resolveFileName(kind, originalFileName);
    // Each mTLS slot lives in its own subfolder so original filenames can be
    // preserved without fear of one slot silently overwriting another (e.g.
    // a root CA and a client cert both named "ca.crt"). Re-importing a file
    // always overwrites the previous one in that slot.
    final kindFolder = switch (kind) {
      ClientCertificateKind.rootCa => 'root_ca',
      ClientCertificateKind.privateKey => 'private_key',
      ClientCertificateKind.clientCertificate => 'client_certificate',
    };
    final destination = path.join(root, 'mqtt_certificates', brokerId, kindFolder, baseName);
    await _files.write(destination, bytes);
    return destination;
  }

  String _resolveFileName(ClientCertificateKind kind, String? originalFileName) {
    final fallbackStem = switch (kind) {
      ClientCertificateKind.rootCa => 'root_ca',
      ClientCertificateKind.privateKey => 'client_private_key',
      ClientCertificateKind.clientCertificate => 'client_certificate',
    };

    if (originalFileName == null || originalFileName.trim().isEmpty) {
      return '$fallbackStem.pem';
    }

    final base = path.basename(originalFileName.trim());
    if (base.isEmpty) {
      return '$fallbackStem.pem';
    }

    final sanitized = base.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final cleaned = sanitized.isEmpty || sanitized == '.' || sanitized == '..' ? '$fallbackStem.pem' : sanitized;

    if (!cleaned.contains('.')) {
      return '$cleaned.pem';
    }
    return cleaned;
  }
}

/// Validates PEM credentials and builds the TLS context used by both MQTT
/// protocol clients. DER and PFX/PKCS#12 containers are intentionally out of
/// scope; callers receive a clear validation failure instead of a late connect
/// error.
class ClientCertificateService {
  ClientCertificateService({CertificateFileAccess? files}) : _files = files ?? const IoCertificateFileAccess();

  final CertificateFileAccess _files;

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

  Future<void> validateConfiguration(ClientCertificateConfig config) async {
    if (config.isEmpty) return;
    if (!config.isComplete) {
      throw const CertificateValidationException('Client private key and client certificate are both required for mTLS. The Root CA is optional — leave it empty to validate against the system trusted roots (e.g. Let\'s Encrypt).');
    }
    await buildSecurityContext(config);
  }

  Future<SecurityContext> buildSecurityContext(ClientCertificateConfig config) async {
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
