import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/app_private_certificate_storage.dart';
import 'package:mqtt_monitor/core/mqtt/interfaces/certificate_file_access_interface.dart';
import 'package:mqtt_monitor/core/mqtt/certificate_validation_exception.dart';
import 'package:mqtt_monitor/core/mqtt/client_certificate_kind.dart';
import 'package:mqtt_monitor/core/mqtt/services/client_certificate_service.dart';
import 'package:mqtt_monitor/core/broker/models/client_certificate_config_model.dart';

import '../../../fixtures/certificate_fixtures.dart';

/// Stores certificate bytes in memory for validation and ownership tests.
class _MemoryFiles implements CertificateFileAccessInterface {
  final Map<String, Uint8List> values = {};

  /// Returns the bytes stored at [filePath].
  @override
  Future<Uint8List> read(String filePath) async {
    final bytes = values[filePath];
    if (bytes == null) throw StateError('Missing $filePath');
    return bytes;
  }

  /// Stores a copy of [bytes] at [filePath].
  @override
  Future<void> write(String filePath, Uint8List bytes) async {
    values[filePath] = Uint8List.fromList(bytes);
  }

  /// Deletes [filePath] from memory.
  @override
  Future<void> delete(String filePath) async {
    values.remove(filePath);
  }
}

void main() {
  group('certificate validation', () {
    final service = ClientCertificateService(files: _MemoryFiles());

    test('accepts valid PEM certificate and private key files', () {
      expect(() => service.validateBytes(ClientCertificateKind.rootCa, testCertificatePem), returnsNormally);
      expect(() => service.validateBytes(ClientCertificateKind.clientCertificate, testCertificatePem), returnsNormally);
      expect(() => service.validateBytes(ClientCertificateKind.privateKey, testPrivateKeyPem), returnsNormally);
    });

    test('rejects malformed PEM', () {
      expect(() => service.validateBytes(ClientCertificateKind.clientCertificate, Uint8List.fromList('-----BEGIN CERTIFICATE-----\nbroken'.codeUnits)), throwsA(isA<CertificateValidationException>()));
    });

    test('rejects DER or PFX data with a clear format error', () {
      expect(() => service.validateBytes(ClientCertificateKind.rootCa, Uint8List.fromList([0x30, 0x82, 0x01])), throwsA(isA<CertificateValidationException>().having((error) => error.message, 'message', contains('DER and PFX are not supported'))));
    });

    test('requires client key + cert (Root CA is optional)', () async {
      await expectLater(service.validateConfiguration(const ClientCertificateConfigModel(rootCaPath: '/certs/ca.pem')), throwsA(isA<CertificateValidationException>()));
      await expectLater(service.validateConfiguration(const ClientCertificateConfigModel()), completes);
    });
  });

  test('builds a SecurityContext from mocked stored paths', () async {
    final files = _MemoryFiles()
      ..values['/private/ca.pem'] = testCertificatePem
      ..values['/private/key.pem'] = testPrivateKeyPem
      ..values['/private/cert.pem'] = testCertificatePem;
    final service = ClientCertificateService(files: files);

    final context = await service.buildSecurityContext(const ClientCertificateConfigModel(rootCaPath: '/private/ca.pem', clientPrivateKeyPath: '/private/key.pem', clientCertificatePath: '/private/cert.pem'));

    expect(context, isNotNull);
  });

  test('builds a SecurityContext with only client key + cert (no Root CA)', () async {
    final files = _MemoryFiles()
      ..values['/private/key.pem'] = testPrivateKeyPem
      ..values['/private/cert.pem'] = testCertificatePem;
    final service = ClientCertificateService(files: files);

    final context = await service.buildSecurityContext(const ClientCertificateConfigModel(clientPrivateKeyPath: '/private/key.pem', clientCertificatePath: '/private/cert.pem'));

    expect(context, isNotNull);
  });

  test('copies selected bytes into an app-private broker directory', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(files: files, directoryProvider: () async => '/app-support', importIdProvider: () => 'import-1');

    final storedPath = await storage.store('broker-1', ClientCertificateKind.privateKey, testPrivateKeyPem);

    expect(storedPath, '/app-support/mqtt_certificates/YnJva2VyLTE/private_key/import-1_client_private_key.pem');
    expect(files.values[storedPath], testPrivateKeyPem);
  });

  test('keeps a sanitized display filename after a unique import ID', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(files: files, directoryProvider: () async => '/app-support', importIdProvider: () => 'import-1');

    final storedPath = await storage.store('broker-1', ClientCertificateKind.rootCa, testCertificatePem, originalFileName: 'ca.crt');

    expect(storedPath, '/app-support/mqtt_certificates/YnJva2VyLTE/root_ca/import-1_ca.crt');
    expect(files.values[storedPath], testCertificatePem);
  });

  test('sanitizes unsafe characters in the original filename', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(files: files, directoryProvider: () async => '/app-support', importIdProvider: () => 'import-1');

    final storedPath = await storage.store('broker-1', ClientCertificateKind.clientCertificate, testCertificatePem, originalFileName: 'My Cert (2024)/client.cert');

    expect(storedPath, '/app-support/mqtt_certificates/YnJva2VyLTE/client_certificate/import-1_client.cert');
    expect(files.values[storedPath], testCertificatePem);
  });

  test('each mTLS slot gets its own subfolder, so same-named files do not collide', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(files: files, directoryProvider: () async => '/app-support', importIdProvider: () => 'import-1');

    // Root CA and client cert happen to share the same filename. They must
    // land in separate per-slot subfolders, not overwrite each other.
    final root = await storage.store('broker-1', ClientCertificateKind.rootCa, testCertificatePem, originalFileName: 'ca.crt');
    expect(root, '/app-support/mqtt_certificates/YnJva2VyLTE/root_ca/import-1_ca.crt');

    final cert = await storage.store('broker-1', ClientCertificateKind.clientCertificate, testPrivateKeyPem, originalFileName: 'ca.crt');
    expect(cert, '/app-support/mqtt_certificates/YnJva2VyLTE/client_certificate/import-1_ca.crt');

    expect(files.values[root], testCertificatePem);
    expect(files.values[cert], testPrivateKeyPem);
  });

  test('re-importing a file creates a separately owned replacement', () async {
    final files = _MemoryFiles();
    var import = 0;
    final storage = AppPrivateCertificateStorage(files: files, directoryProvider: () async => '/app-support', importIdProvider: () => 'import-${++import}');

    final first = await storage.store('broker-1', ClientCertificateKind.rootCa, testCertificatePem, originalFileName: 'ca.crt');
    final second = await storage.store('broker-1', ClientCertificateKind.rootCa, testPrivateKeyPem, originalFileName: 'ca.crt');

    expect(second, isNot(first));
    expect(files.values[first], testCertificatePem);
    expect(files.values[second], testPrivateKeyPem);
  });

  test('deletes an owned certificate path', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(files: files, directoryProvider: () async => '/app-support', importIdProvider: () => 'import-1');
    final storedPath = await storage.store('broker-1', ClientCertificateKind.rootCa, testCertificatePem);

    await storage.delete(storedPath);

    expect(files.values, isNot(contains(storedPath)));
  });

  test('refuses to delete a path outside app-owned certificate storage', () async {
    final storage = AppPrivateCertificateStorage(files: _MemoryFiles(), directoryProvider: () async => '/app-support');

    await expectLater(storage.delete('/user/documents/private.key'), throwsStateError);
  });
}
