import '../storage/preferences_store.dart';
import 'broker_storage_keys.dart';

/// Initializes broker schema metadata and gates future schema migrations.
class BrokerStorageMigrator {
  /// Creates a schema runner backed by [store].
  const BrokerStorageMigrator(PreferencesStore store) : _store = store;

  final PreferencesStore _store;

  /// Initializes fresh storage or validates that its schema is supported.
  Future<void> migrate() async {
    final rawVersion = _store.get(BrokerStorageKeys.schemaVersion);
    if (rawVersion != null && rawVersion is! int) {
      throw const FormatException('The storage schema version is invalid.');
    }

    if (rawVersion == null) {
      await _store.setInt(BrokerStorageKeys.schemaVersion, BrokerStorageKeys.currentSchemaVersion);
      return;
    }

    final version = rawVersion as int;
    if (version > BrokerStorageKeys.currentSchemaVersion) {
      throw FormatException('Storage schema version $version is newer than this app supports.');
    }

    if (version == BrokerStorageKeys.currentSchemaVersion) return;
    throw FormatException('Storage schema version $version has no migration path.');
  }
}
