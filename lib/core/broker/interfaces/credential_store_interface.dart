/// Stores broker secrets outside profile persistence.
abstract interface class CredentialStoreInterface {
  /// Returns the secret stored for [reference], or `null` when it is absent.
  Future<String?> read(String reference);

  /// Stores [value] under [reference].
  Future<void> write(String reference, String value);

  /// Removes the secret stored under [reference].
  Future<void> delete(String reference);
}
