import '../../mqtt/client_certificate_kind.dart';

/// Deletes app-owned certificate files after profile changes commit.
abstract interface class CertificateStorageInterface {
  /// Copies an app-owned certificate into a new broker-specific file.
  Future<String> duplicate(String filePath, {required String brokerId, required ClientCertificateKind kind});

  /// Deletes the certificate at [filePath] when it exists.
  Future<void> delete(String filePath);
}
