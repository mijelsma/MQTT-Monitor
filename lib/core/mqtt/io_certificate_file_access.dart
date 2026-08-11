import 'dart:io';
import 'dart:typed_data';

import 'certificate_file_access.dart';

/// Performs certificate file operations against the local file system.
class IoCertificateFileAccess implements CertificateFileAccess {
  /// Creates the production certificate file adapter.
  const IoCertificateFileAccess();

  /// Reads all bytes from [filePath].
  @override
  Future<Uint8List> read(String filePath) => File(filePath).readAsBytes();

  /// Writes [bytes] to [filePath] and flushes them to disk.
  @override
  Future<void> write(String filePath, Uint8List bytes) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Deletes [filePath] when it exists.
  @override
  Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }
}
