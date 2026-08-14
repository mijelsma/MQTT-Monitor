import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../broker/interfaces/certificate_storage_interface.dart';
import 'interfaces/certificate_file_access_interface.dart';
import 'client_certificate_kind.dart';
import 'io_certificate_file_access.dart';

/// Supplies the application-support directory used for owned certificates.
typedef CertificateDirectoryProvider = Future<String> Function();

/// Supplies a unique segment for one certificate import.
typedef CertificateImportIdProvider = String Function();

/// Stores imported certificates in app-private broker and slot directories.
class AppPrivateCertificateStorage implements CertificateStorageInterface {
  /// Creates certificate storage from explicit file and directory adapters.
  AppPrivateCertificateStorage({required CertificateFileAccessInterface files, required CertificateDirectoryProvider directoryProvider, CertificateImportIdProvider? importIdProvider}) : _files = files, _directoryProvider = directoryProvider, _importIdProvider = importIdProvider ?? _defaultImportId;

  /// Creates certificate storage backed by the application-support directory.
  factory AppPrivateCertificateStorage.standard() {
    return AppPrivateCertificateStorage(files: const IoCertificateFileAccess(), directoryProvider: () async => (await getApplicationSupportDirectory()).path);
  }

  final CertificateFileAccessInterface _files;
  final CertificateDirectoryProvider _directoryProvider;
  final CertificateImportIdProvider _importIdProvider;

  /// Copies [bytes] into a uniquely owned file for [brokerId] and [kind].
  Future<String> store(String brokerId, ClientCertificateKind kind, Uint8List bytes, {String? originalFileName}) async {
    final root = await _directoryProvider();
    final baseName = _resolveFileName(kind, originalFileName);
    final brokerDirectory = base64Url.encode(utf8.encode(brokerId)).replaceAll('=', '');
    final importId = _importIdProvider().replaceAll(RegExp(r'[^\w.\-]'), '_');
    final destination = path.join(root, 'mqtt_certificates', brokerDirectory, _kindFolder(kind), '${importId}_$baseName');
    await _files.write(destination, bytes);
    return destination;
  }

  /// Deletes an owned certificate file when it exists.
  @override
  Future<void> delete(String filePath) async {
    final root = await _directoryProvider();
    final ownedRoot = path.normalize(path.join(root, 'mqtt_certificates'));
    final candidate = path.normalize(filePath);
    if (!path.isWithin(ownedRoot, candidate)) {
      throw StateError('The certificate path is outside app-owned storage.');
    }
    await _files.delete(candidate);
  }

  /// Returns the directory name assigned to [kind].
  String _kindFolder(ClientCertificateKind kind) => switch (kind) {
    ClientCertificateKind.rootCa => 'root_ca',
    ClientCertificateKind.privateKey => 'private_key',
    ClientCertificateKind.clientCertificate => 'client_certificate',
  };

  /// Returns a safe display-derived filename for one imported certificate.
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
    if (base.isEmpty) return '$fallbackStem.pem';
    final sanitized = base.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final cleaned = sanitized.isEmpty || sanitized == '.' || sanitized == '..' ? '$fallbackStem.pem' : sanitized;
    return cleaned.contains('.') ? cleaned : '$cleaned.pem';
  }

  /// Produces a process-local import identifier suitable for filenames.
  static String _defaultImportId() => DateTime.now().microsecondsSinceEpoch.toString();
}
