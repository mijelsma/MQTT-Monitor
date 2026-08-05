import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/client_certificate_service.dart';
import 'package:mqtt_monitor/models/client_certificate_config.dart';

import '../../fixtures/certificate_fixtures.dart';

class _MemoryFiles implements CertificateFileAccess {
  final Map<String, Uint8List> values = {};

  @override
  Future<Uint8List> read(String filePath) async {
    final bytes = values[filePath];
    if (bytes == null) throw StateError('Missing $filePath');
    return bytes;
  }

  @override
  Future<void> write(String filePath, Uint8List bytes) async {
    values[filePath] = Uint8List.fromList(bytes);
  }
}

void main() {
  group('certificate validation', () {
    final service = ClientCertificateService(files: _MemoryFiles());

    test('accepts valid PEM certificate and private key files', () {
      expect(
        () => service.validateBytes(
          ClientCertificateKind.rootCa,
          testCertificatePem,
        ),
        returnsNormally,
      );
      expect(
        () => service.validateBytes(
          ClientCertificateKind.clientCertificate,
          testCertificatePem,
        ),
        returnsNormally,
      );
      expect(
        () => service.validateBytes(
          ClientCertificateKind.privateKey,
          testPrivateKeyPem,
        ),
        returnsNormally,
      );
    });

    test('rejects malformed PEM', () {
      expect(
        () => service.validateBytes(
          ClientCertificateKind.clientCertificate,
          Uint8List.fromList('-----BEGIN CERTIFICATE-----\nbroken'.codeUnits),
        ),
        throwsA(isA<CertificateValidationException>()),
      );
    });

    test('rejects DER or PFX data with a clear format error', () {
      expect(
        () => service.validateBytes(
          ClientCertificateKind.rootCa,
          Uint8List.fromList([0x30, 0x82, 0x01]),
        ),
        throwsA(
          isA<CertificateValidationException>().having(
            (error) => error.message,
            'message',
            contains('DER and PFX are not supported'),
          ),
        ),
      );
    });

    test('requires client key + cert (Root CA is optional)', () async {
      await expectLater(
        service.validateConfiguration(
          const ClientCertificateConfig(rootCaPath: '/certs/ca.pem'),
        ),
        throwsA(isA<CertificateValidationException>()),
      );
      await expectLater(
        service.validateConfiguration(const ClientCertificateConfig()),
        completes,
      );
    });
  });

  test('builds a SecurityContext from mocked stored paths', () async {
    final files = _MemoryFiles()
      ..values['/private/ca.pem'] = testCertificatePem
      ..values['/private/key.pem'] = testPrivateKeyPem
      ..values['/private/cert.pem'] = testCertificatePem;
    final service = ClientCertificateService(files: files);

    final context = await service.buildSecurityContext(
      const ClientCertificateConfig(
        rootCaPath: '/private/ca.pem',
        clientPrivateKeyPath: '/private/key.pem',
        clientCertificatePath: '/private/cert.pem',
      ),
    );

    expect(context, isNotNull);
  });

  test('builds a SecurityContext with only client key + cert (no Root CA)', () async {
    final files = _MemoryFiles()
      ..values['/private/key.pem'] = testPrivateKeyPem
      ..values['/private/cert.pem'] = testCertificatePem;
    final service = ClientCertificateService(files: files);

    final context = await service.buildSecurityContext(
      const ClientCertificateConfig(
        clientPrivateKeyPath: '/private/key.pem',
        clientCertificatePath: '/private/cert.pem',
      ),
    );

    expect(context, isNotNull);
  });

  test('copies selected bytes into an app-private broker directory', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(
      files: files,
      directoryProvider: () async => '/app-support',
    );

    final storedPath = await storage.store(
      'broker-1',
      ClientCertificateKind.privateKey,
      testPrivateKeyPem,
    );

    expect(
      storedPath,
      '/app-support/mqtt_certificates/broker-1/private_key/client_private_key.pem',
    );
    expect(files.values[storedPath], testPrivateKeyPem);
  });

  test('keeps the original filename when one is provided', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(
      files: files,
      directoryProvider: () async => '/app-support',
    );

    final storedPath = await storage.store(
      'broker-1',
      ClientCertificateKind.rootCa,
      testCertificatePem,
      originalFileName: 'ca.crt',
    );

    expect(storedPath, '/app-support/mqtt_certificates/broker-1/root_ca/ca.crt');
    expect(files.values[storedPath], testCertificatePem);
  });

  test('sanitizes unsafe characters in the original filename', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(
      files: files,
      directoryProvider: () async => '/app-support',
    );

    final storedPath = await storage.store(
      'broker-1',
      ClientCertificateKind.clientCertificate,
      testCertificatePem,
      originalFileName: 'My Cert (2024)/client.cert',
    );

    expect(storedPath, '/app-support/mqtt_certificates/broker-1/client_certificate/client.cert');
    expect(files.values[storedPath], testCertificatePem);
  });

  test('each mTLS slot gets its own subfolder, so same-named files do not collide', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(
      files: files,
      directoryProvider: () async => '/app-support',
    );

    // Root CA and client cert happen to share the same filename — they must
    // land in separate per-slot subfolders, not overwrite each other.
    final root = await storage.store(
      'broker-1',
      ClientCertificateKind.rootCa,
      testCertificatePem,
      originalFileName: 'ca.crt',
    );
    expect(root, '/app-support/mqtt_certificates/broker-1/root_ca/ca.crt');

    final cert = await storage.store(
      'broker-1',
      ClientCertificateKind.clientCertificate,
      testPrivateKeyPem,
      originalFileName: 'ca.crt',
    );
    expect(cert, '/app-support/mqtt_certificates/broker-1/client_certificate/ca.crt');

    expect(files.values[root], testCertificatePem);
    expect(files.values[cert], testPrivateKeyPem);
  });

  test('re-importing a file overwrites the previous one in its slot', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(
      files: files,
      directoryProvider: () async => '/app-support',
    );

    final first = await storage.store(
      'broker-1',
      ClientCertificateKind.rootCa,
      testCertificatePem,
      originalFileName: 'ca.crt',
    );
    final second = await storage.store(
      'broker-1',
      ClientCertificateKind.rootCa,
      testPrivateKeyPem,
      originalFileName: 'ca.crt',
    );

    expect(second, first);
    expect(files.values[first], testPrivateKeyPem);
  });
}
