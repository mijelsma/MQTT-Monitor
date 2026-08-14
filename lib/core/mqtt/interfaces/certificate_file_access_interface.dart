import 'dart:typed_data';

/// Provides the file operations needed by certificate storage and validation.
abstract interface class CertificateFileAccessInterface {
  /// Reads all bytes from [filePath].
  Future<Uint8List> read(String filePath);

  /// Writes [bytes] to [filePath], creating parent directories as needed.
  Future<void> write(String filePath, Uint8List bytes);

  /// Deletes [filePath] when it exists.
  Future<void> delete(String filePath);
}
