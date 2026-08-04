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
typedef CertificateNameTokenProvider = String Function();

/// Copies credentials into app-private storage. Only these paths are persisted
/// in SharedPreferences; private-key bytes are never stored there.
class AppPrivateCertificateStorage {
  AppPrivateCertificateStorage({
    required CertificateFileAccess files,
    required CertificateDirectoryProvider directoryProvider,
    CertificateNameTokenProvider? nameTokenProvider,
  }) : _files = files,
       _directoryProvider = directoryProvider,
       _nameTokenProvider =
           nameTokenProvider ??
           (() => DateTime.now().microsecondsSinceEpoch.toString());

  factory AppPrivateCertificateStorage.standard() {
    return AppPrivateCertificateStorage(
      files: const IoCertificateFileAccess(),
      directoryProvider: () async =>
          (await getApplicationSupportDirectory()).path,
    );
  }

  final CertificateFileAccess _files;
  final CertificateDirectoryProvider _directoryProvider;
  final CertificateNameTokenProvider _nameTokenProvider;

  Future<String> store(
    String brokerId,
    ClientCertificateKind kind,
    Uint8List bytes,
  ) async {
    final root = await _directoryProvider();
    final stem = switch (kind) {
      ClientCertificateKind.rootCa => 'root_ca',
      ClientCertificateKind.privateKey => 'client_private_key',
      ClientCertificateKind.clientCertificate => 'client_certificate',
    };
    final fileName = '${stem}_${_nameTokenProvider()}.pem';
    final destination = path.join(
      root,
      'mqtt_certificates',
      brokerId,
      fileName,
    );
    await _files.write(destination, bytes);
    return destination;
  }
}

/// Validates PEM credentials and builds the TLS context used by both MQTT
/// protocol clients. DER and PFX/PKCS#12 containers are intentionally out of
/// scope; callers receive a clear validation failure instead of a late connect
/// error.
class ClientCertificateService {
  ClientCertificateService({CertificateFileAccess? files})
    : _files = files ?? const IoCertificateFileAccess();

  final CertificateFileAccess _files;

  void validateBytes(ClientCertificateKind kind, Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const CertificateValidationException('The selected file is empty.');
    }
    final text = String.fromCharCodes(bytes);
    if (!text.contains('-----BEGIN ')) {
      throw const CertificateValidationException(
        'Unsupported certificate format. Select a PEM encoded file; DER and PFX are not supported.',
      );
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
      throw CertificateValidationException(
        'The $label is malformed or unreadable: $error',
      );
    }
  }

  Future<void> validateConfiguration(ClientCertificateConfig config) async {
    if (config.isEmpty) return;
    if (!config.isComplete) {
      throw const CertificateValidationException(
        'Root CA, client private key, and client certificate are all required for mTLS.',
      );
    }
    await buildSecurityContext(config);
  }

  Future<SecurityContext> buildSecurityContext(
    ClientCertificateConfig config,
  ) async {
    if (!config.isComplete) {
      throw const CertificateValidationException(
        'Cannot create an mTLS context without all three certificate files.',
      );
    }

    try {
      final rootCa = await _files.read(config.rootCaPath!);
      final privateKey = await _files.read(config.clientPrivateKeyPath!);
      final certificate = await _files.read(config.clientCertificatePath!);

      validateBytes(ClientCertificateKind.rootCa, rootCa);
      validateBytes(ClientCertificateKind.privateKey, privateKey);
      validateBytes(ClientCertificateKind.clientCertificate, certificate);

      final context = SecurityContext(withTrustedRoots: true);
      context.setTrustedCertificatesBytes(rootCa);
      context.useCertificateChainBytes(certificate);
      context.usePrivateKeyBytes(privateKey);
      return context;
    } on CertificateValidationException {
      rethrow;
    } catch (error) {
      throw CertificateValidationException(
        'A configured certificate file is missing or unreadable: $error',
      );
    }
  }
}
