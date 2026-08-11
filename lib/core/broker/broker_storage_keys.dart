/// Defines the broker repository's private preference namespace and schema.
abstract final class BrokerStorageKeys {
  static const profiles = 'broker.profiles';
  static const activeProfileId = 'broker.activeProfileId';
  static const pendingResourceCleanup = 'broker.pendingResourceCleanup';
  static const schemaVersion = 'broker.schemaVersion';
  static const currentSchemaVersion = 1;
}
