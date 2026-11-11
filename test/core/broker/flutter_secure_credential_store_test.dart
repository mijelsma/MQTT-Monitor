import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mqtt_monitor/core/broker/flutter_secure_credential_store.dart';

void main() {
  late _RecordingSecureStorage storage;
  late FlutterSecureCredentialStore credentials;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    storage = _RecordingSecureStorage();
    credentials = FlutterSecureCredentialStore(storage: storage);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('uses an MQTT Monitor-specific macOS Keychain service', () async {
    await credentials.write('broker-password', 'secret');

    expect(await credentials.read('broker-password'), 'secret');
    expect(storage.services, everyElement(FlutterSecureCredentialStore.keychainServiceName));
    expect(storage.dataProtectionValues, everyElement(isFalse));
  });

  test('deletion also cleans the former generic macOS service', () async {
    await credentials.delete('broker-password');

    expect(storage.services, [FlutterSecureCredentialStore.keychainServiceName, AppleOptions.defaultAccountName]);
  });

  test('legacy cleanup failure does not fail deletion of a current credential', () async {
    await credentials.write('duplicate-password', 'secret');
    storage.failDeleteService = AppleOptions.defaultAccountName;

    await credentials.delete('duplicate-password');

    expect(await credentials.read('duplicate-password'), isNull);
  });

  test('current credential deletion failure is still reported', () async {
    await credentials.write('duplicate-password', 'secret');
    storage.failDeleteService = FlutterSecureCredentialStore.keychainServiceName;

    await expectLater(credentials.delete('duplicate-password'), throwsStateError);
    expect(await credentials.read('duplicate-password'), 'secret');
  });
}

class _RecordingSecureStorage extends FlutterSecureStorage {
  final Map<(String, String), String> _values = {};
  final List<String> services = [];
  final List<bool> dataProtectionValues = [];
  String? failDeleteService;

  String _record(AppleOptions? options) {
    final macOptions = options! as MacOsOptions;
    final service = macOptions.accountName!;
    services.add(service);
    dataProtectionValues.add(macOptions.usesDataProtectionKeychain);
    return service;
  }

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    return _values[(_record(mOptions), key)];
  }

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    final storageKey = (_record(mOptions), key);
    if (value == null) {
      _values.remove(storageKey);
    } else {
      _values[storageKey] = value;
    }
  }

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    final service = _record(mOptions);
    if (failDeleteService == service) {
      failDeleteService = null;
      throw StateError('Injected delete failure for $service');
    }
    _values.remove((service, key));
  }
}
