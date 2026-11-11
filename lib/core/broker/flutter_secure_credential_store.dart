import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'interfaces/credential_store_interface.dart';

/// Persists broker secrets in the operating system's protected credential store.
class FlutterSecureCredentialStore implements CredentialStoreInterface {
  /// User-facing Keychain service name for MQTT Monitor credentials.
  static const String keychainServiceName = 'MQTT Monitor';

  static const MacOsOptions _macOsOptions = MacOsOptions(accountName: keychainServiceName, usesDataProtectionKeychain: false);
  static const MacOsOptions _legacyMacOsOptions = MacOsOptions(usesDataProtectionKeychain: false);

  /// Creates the production credential adapter.
  const FlutterSecureCredentialStore({FlutterSecureStorage storage = const FlutterSecureStorage()}) : _storage = storage;

  final FlutterSecureStorage _storage;

  /// Returns the protected secret stored for [reference].
  @override
  Future<String?> read(String reference) {
    return _storage.read(key: reference, mOptions: _macOsOptions);
  }

  /// Writes [value] to protected storage under [reference].
  @override
  Future<void> write(String reference, String value) {
    return _storage.write(key: reference, value: value, mOptions: _macOsOptions);
  }

  /// Deletes the protected secret stored under [reference].
  @override
  Future<void> delete(String reference) async {
    await _storage.delete(key: reference, mOptions: _macOsOptions);
    // Development data is not migrated, but reset/delete should not leave the
    // former plugin-default Keychain item behind. This cleanup is best-effort:
    // current profiles (including duplicates) never own a legacy item.
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        await _storage.delete(key: reference, mOptions: _legacyMacOsOptions);
      } on Object {
        // The current credential has already been removed successfully.
      }
    }
  }
}
