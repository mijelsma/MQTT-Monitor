import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'credential_store.dart';

/// Persists broker secrets in the operating system's protected credential store.
///
/// macOS uses the file-based Keychain so local and Developer ID builds do not
/// require the restricted keychain-sharing entitlement or a provisioning profile.
class FlutterSecureCredentialStore implements CredentialStore {
  /// Creates the production credential adapter.
  const FlutterSecureCredentialStore({FlutterSecureStorage storage = const FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false))}) : _storage = storage;

  final FlutterSecureStorage _storage;

  /// Returns the protected secret stored for [reference].
  @override
  Future<String?> read(String reference) => _storage.read(key: reference);

  /// Writes [value] to protected storage under [reference].
  @override
  Future<void> write(String reference, String value) => _storage.write(key: reference, value: value);

  /// Deletes the protected secret stored under [reference].
  @override
  Future<void> delete(String reference) => _storage.delete(key: reference);
}
