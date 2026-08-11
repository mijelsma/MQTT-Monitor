/// Deletes app-owned certificate files after profile changes commit.
abstract interface class CertificateStorage {
  /// Deletes the certificate at [filePath] when it exists.
  Future<void> delete(String filePath);
}
