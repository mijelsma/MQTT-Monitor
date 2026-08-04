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

    test('requires either all three mTLS files or none', () async {
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

  test('copies selected bytes into an app-private broker directory', () async {
    final files = _MemoryFiles();
    final storage = AppPrivateCertificateStorage(
      files: files,
      directoryProvider: () async => '/app-support',
      nameTokenProvider: () => 'selection-1',
    );

    final storedPath = await storage.store(
      'broker-1',
      ClientCertificateKind.privateKey,
      testPrivateKeyPem,
    );

    expect(
      storedPath,
      '/app-support/mqtt_certificates/broker-1/client_private_key_selection-1.pem',
    );
    expect(files.values[storedPath], testPrivateKeyPem);
  });
}
