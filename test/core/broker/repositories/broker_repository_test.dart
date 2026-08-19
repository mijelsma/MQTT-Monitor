import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/repositories/broker_repository.dart';
import 'package:mqtt_monitor/core/broker/broker_storage_keys.dart';
import 'package:mqtt_monitor/core/broker/interfaces/certificate_storage_interface.dart';
import 'package:mqtt_monitor/core/broker/interfaces/credential_store_interface.dart';
import 'package:mqtt_monitor/core/storage/preferences_store.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/client_certificate_config_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/mqtt_protocol_version_model.dart';
import 'package:mqtt_monitor/core/mqtt/client_certificate_kind.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';

void main() {
  const first = BrokerEntryModel(id: 'first', name: 'First', host: 'first.invalid');
  const second = BrokerEntryModel(id: 'second', name: 'Second', host: 'second.invalid');

  test('schema initialization is idempotent', () async {
    final store = _MemoryPreferencesStore();
    final repository = _repository(store);
    await repository.initialize();
    await repository.initialize();
    expect(store.schemaVersionWrites, 1);
    expect(repository.failure, isNull);
  });

  test('fresh storage gets defaults without creating a broker payload', () async {
    final store = _MemoryPreferencesStore();
    final repository = _repository(store);
    await repository.initialize();
    expect(repository.brokers, isEmpty);
    expect(repository.activeBrokerId, isNull);
    expect(store.get(BrokerStorageKeys.profiles), isNull);
    expect(store.get(BrokerStorageKeys.activeProfileId), isNull);
    expect(store.get(BrokerStorageKeys.schemaVersion), BrokerStorageKeys.currentSchemaVersion);
  });

  test('corrupt JSON is reported and left byte-for-byte unchanged', () async {
    const corrupt = '[{"id":"broken"';
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion, BrokerStorageKeys.profiles: corrupt});
    final repository = _repository(store);
    await repository.initialize();
    expect(repository.failure?.message, contains('left unchanged'));
    expect(repository.failure?.details, isNotEmpty);
    expect(repository.brokers, isEmpty);
    expect(store.get(BrokerStorageKeys.profiles), corrupt);
    expect(await repository.add(first), isFalse);
    expect(store.get(BrokerStorageKeys.profiles), corrupt);
  });

  test('plaintext password payload is rejected and left unchanged', () async {
    const plaintext = '[{"id":"first","name":"First","host":"first.invalid","password":"secret","subscriptions":[]}]';
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion, BrokerStorageKeys.profiles: plaintext});
    final repository = _repository(store);

    await repository.initialize();

    expect(repository.failure?.details, contains('unsupported plaintext'));
    expect(repository.failure?.details, isNot(contains('secret')));
    expect(store.get(BrokerStorageKeys.profiles), plaintext);
  });

  test('a future schema is rejected without modifying stored data', () async {
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion + 1, BrokerStorageKeys.profiles: '[]'});
    final repository = _repository(store);
    await repository.initialize();
    expect(repository.failure?.details, contains('newer than this app supports'));
    expect(store.values, {BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion + 1, BrokerStorageKeys.profiles: '[]'});
  });

  test('an unsupported development schema is rejected without migration', () async {
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: 0, BrokerStorageKeys.profiles: '[]'});
    final repository = _repository(store);

    await repository.initialize();

    expect(repository.failure?.details, contains('not supported'));
    expect(store.values, {BrokerStorageKeys.schemaVersion: 0, BrokerStorageKeys.profiles: '[]'});
  });

  test('invalid active ID falls back to the first profile and persists the repair', () async {
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion, BrokerStorageKeys.profiles: '[{"id":"first","name":"First","host":"first.invalid","subscriptions":[]}]', BrokerStorageKeys.activeProfileId: 'missing'});
    final repository = _repository(store);
    await repository.initialize();
    expect(repository.activeBrokerId, first.id);
    expect(repository.activeBroker?.id, first.id);
    expect(store.get(BrokerStorageKeys.activeProfileId), first.id);
  });

  test('current broker fields and protected password round-trip without loss', () async {
    const broker = BrokerEntryModel(
      id: 'complete',
      name: 'Complete',
      host: 'mqtt.example.com',
      port: 8883,
      protocolVersion: MqttProtocolVersionModel.v5,
      clientCertificates: ClientCertificateConfigModel(rootCaPath: '/certs/root.pem', clientPrivateKeyPath: '/certs/client.key', clientCertificatePath: '/certs/client.pem'),
      useSSL: true,
      validateCertificates: false,
      username: 'user',
      password: 'secret',
      clientId: 'client',
      randomClientIdSuffix: false,
      colorIndex: 4,
      subscriptions: [SubscriptionEntryModel(id: 'state-subscription', topic: 'devices/+/state', qos: 2, name: 'State')],
    );
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore();
    final repository = _repository(store, credentials: credentials);
    await repository.initialize();
    expect(await repository.add(broker), isTrue);
    final storedJson = store.get(BrokerStorageKeys.profiles)! as String;
    expect(storedJson, isNot(contains('secret')));
    expect(storedJson, isNot(contains('"password"')));
    expect(storedJson, contains('passwordReference'));

    final reloaded = _repository(store, credentials: credentials);
    await reloaded.initialize();
    expect(reloaded.failure, isNull);
    expect(reloaded.brokers.single.password, 'secret');
    expect(reloaded.brokers.single.toJson(), repository.brokers.single.toJson());
  });

  test('duplicates broker settings with independent credentials and certificates', () async {
    const broker = BrokerEntryModel(
      id: 'source',
      name: 'Source',
      host: 'mqtt.example.com',
      port: 8883,
      useSSL: true,
      username: 'user',
      password: 'secret',
      clientId: 'client',
      randomClientIdSuffix: false,
      colorIndex: 3,
      clientCertificates: ClientCertificateConfigModel(rootCaPath: '/owned/root.pem'),
      subscriptions: [SubscriptionEntryModel(id: 'sub', topic: 'devices/#', qos: 1)],
    );
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore();
    final certificates = _MemoryCertificateStorage();
    final repository = _repository(store, credentials: credentials, certificates: certificates);
    await repository.initialize();
    await repository.add(broker);

    expect(await repository.duplicate(broker.id), isTrue);
    expect(repository.failure, isNull);

    expect(repository.brokers, hasLength(2));
    final source = repository.brokers.first;
    final duplicate = repository.brokers.last;
    expect(repository.activeBrokerId, source.id);
    expect(duplicate.id, isNot(source.id));
    expect(duplicate.name, source.name);
    expect(duplicate.host, source.host);
    expect(duplicate.password, source.password);
    expect(duplicate.passwordReference, isNot(source.passwordReference));
    expect(duplicate.subscriptions.map((subscription) => subscription.toJson()), source.subscriptions.map((subscription) => subscription.toJson()));
    expect(duplicate.clientCertificates.rootCaPath, isNot(source.clientCertificates.rootCaPath));
    expect(credentials.values.values, ['secret', 'secret']);
    expect(certificates.duplicated, [duplicate.clientCertificates.rootCaPath]);

    expect(await repository.delete(duplicate.id), isTrue);
    expect(repository.failure, isNull);
    expect(certificates.deleted, [duplicate.clientCertificates.rootCaPath]);
    expect(credentials.values.values, ['secret']);

    final reloaded = _repository(store, credentials: credentials, certificates: certificates);
    await reloaded.initialize();
    expect(reloaded.failure, isNull);
    expect(reloaded.brokers.map((broker) => broker.id), [source.id]);
    expect(reloaded.brokers.single.password, 'secret');
  });

  test('CRUD, reorder, selection, and active deletion survive reload', () async {
    final store = _MemoryPreferencesStore();
    final repository = _repository(store);
    await repository.initialize();
    expect(await repository.add(first), isTrue);
    expect(await repository.add(second, makeActive: false), isTrue);
    expect(repository.activeBrokerId, first.id);
    expect(await repository.update(first.copyWith(name: 'Updated')), isTrue);
    expect(await repository.reorder(1, 0), isTrue);
    expect(repository.brokers.map((broker) => broker.id), [second.id, first.id]);
    expect(await repository.select(second.id), isTrue);
    expect(await repository.delete(second.id), isTrue);
    expect(repository.activeBrokerId, first.id);

    final reloaded = _repository(store);
    await reloaded.initialize();
    expect(reloaded.failure, isNull);
    expect(reloaded.brokers.single.name, 'Updated');
    expect(reloaded.activeBrokerId, first.id);
  });

  test('failed schema initialization can be retried', () async {
    final store = _MemoryPreferencesStore()..failNextWriteFor(BrokerStorageKeys.schemaVersion);
    final repository = _repository(store);
    await repository.initialize();
    expect(repository.failure, isNotNull);
    expect(store.get(BrokerStorageKeys.profiles), isNull);
    expect(store.get(BrokerStorageKeys.schemaVersion), isNull);
    await repository.retry();
    expect(repository.failure, isNull);
    expect(repository.brokers, isEmpty);
  });

  test('failed multi-key save restores the previous persisted snapshot', () async {
    final store = _MemoryPreferencesStore();
    final repository = _repository(store);
    await repository.initialize();
    await repository.add(first);
    final oldProfiles = store.get(BrokerStorageKeys.profiles);
    final oldActiveId = store.get(BrokerStorageKeys.activeProfileId);
    store.failNextWriteFor(BrokerStorageKeys.activeProfileId);
    expect(await repository.add(second), isFalse);
    expect(repository.brokers.map((broker) => broker.id), [first.id]);
    expect(repository.failure?.message, contains('previous stored data was preserved'));
    expect(store.get(BrokerStorageKeys.profiles), oldProfiles);
    expect(store.get(BrokerStorageKeys.activeProfileId), oldActiveId);
  });

  test('failed secure write leaves profile storage unchanged and redacts the secret', () async {
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore()..failNextWrite = true;
    final repository = _repository(store, credentials: credentials);
    await repository.initialize();
    expect(await repository.add(first.copyWith(password: 'do-not-leak')), isFalse);
    expect(store.get(BrokerStorageKeys.profiles), isNull);
    expect(repository.failure?.details, isNot(contains('do-not-leak')));
    expect(credentials.values, isEmpty);
  });

  test('failed profile write restores the previous secure password', () async {
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore();
    final repository = _repository(store, credentials: credentials);
    await repository.initialize();
    await repository.add(first.copyWith(password: 'old-secret'));
    store.failNextWriteFor(BrokerStorageKeys.profiles);
    expect(await repository.update(repository.brokers.single.copyWith(password: 'new-secret')), isFalse);
    expect(credentials.values.values.single, 'old-secret');
    expect(repository.failure?.details, isNot(contains('new-secret')));
  });

  test('clearing a password removes its reference and protected value', () async {
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore();
    final repository = _repository(store, credentials: credentials);
    await repository.initialize();
    await repository.add(first.copyWith(password: 'secret'));

    expect(await repository.update(repository.brokers.single.copyWith(clearPassword: true)), isTrue);

    expect(repository.brokers.single.password, isNull);
    expect(repository.brokers.single.passwordReference, isNull);
    expect(credentials.values, isEmpty);
    expect(store.get(BrokerStorageKeys.profiles), isNot(contains('passwordReference')));
  });

  test('failed secure verification rolls back the written value', () async {
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore()..corruptNextWrite = true;
    final repository = _repository(store, credentials: credentials);
    await repository.initialize();

    expect(await repository.add(first.copyWith(password: 'secret')), isFalse);

    expect(credentials.values, isEmpty);
    expect(store.get(BrokerStorageKeys.profiles), isNull);
    expect(repository.failure?.details, contains('could not verify'));
  });

  test('missing protected password produces a recoverable load failure', () async {
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore();
    final repository = _repository(store, credentials: credentials);
    await repository.initialize();
    await repository.add(first.copyWith(password: 'secret'));
    credentials.values.clear();
    final reloaded = _repository(store, credentials: credentials);
    await reloaded.initialize();
    expect(reloaded.failure?.details, contains('unavailable in protected storage'));
    expect(reloaded.failure?.details, isNot(contains('secret')));
    expect(reloaded.brokers, isEmpty);
  });

  test('reset recovers invalid broker data and cleans owned resources', () async {
    const invalidProfiles =
        '[{"id":"first","name":"First","host":"first.invalid",'
        '"passwordReference":"credential",'
        '"clientCertificates":{"rootCaPath":"/owned/root.pem"},'
        '"subscriptions":[{"topic":"#","qos":1}]}]';
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion, BrokerStorageKeys.profiles: invalidProfiles});
    final credentials = _MemoryCredentialStore()..values['credential'] = 'secret';
    final certificates = _MemoryCertificateStorage();
    final repository = _repository(store, credentials: credentials, certificates: certificates);
    await repository.initialize();
    expect(repository.failure?.details, contains('invalid or duplicate ID'));

    final result = await repository.resetToDefaults();

    expect(result, (succeeded: true, cleanupFailures: 0));
    expect(store.values, {BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion});
    expect(repository.failure, isNull);
    expect(repository.brokers, isEmpty);
    expect(credentials.values, isEmpty);
    expect(certificates.deleted, ['/owned/root.pem']);
  });

  test('failed reset keeps preferences and broker resources intact', () async {
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore();
    final repository = _repository(store, credentials: credentials);
    await repository.initialize();
    await repository.add(first.copyWith(password: 'secret'));
    final persisted = Map<String, Object>.from(store.values);
    store.failNextWriteFor(BrokerStorageKeys.profiles);

    final result = await repository.resetToDefaults();

    expect(result.succeeded, isFalse);
    expect(store.values, persisted);
    expect(credentials.values.values, ['secret']);
  });

  test('certificate replacement and broker deletion clean owned resources', () async {
    final store = _MemoryPreferencesStore();
    final credentials = _MemoryCredentialStore();
    final certificates = _MemoryCertificateStorage();
    final repository = _repository(store, credentials: credentials, certificates: certificates);
    await repository.initialize();
    const original = BrokerEntryModel(
      id: 'certs',
      name: 'Certs',
      host: 'host',
      password: 'secret',
      clientCertificates: ClientCertificateConfigModel(rootCaPath: '/owned/root-old.pem', clientPrivateKeyPath: '/owned/key.pem'),
    );
    await repository.add(original);
    final replacement = repository.brokers.single.copyWith(
      clientCertificates: const ClientCertificateConfigModel(rootCaPath: '/owned/root-new.pem', clientPrivateKeyPath: '/owned/key.pem'),
    );
    expect(await repository.update(replacement), isTrue);
    expect(certificates.deleted, ['/owned/root-old.pem']);
    expect(await repository.delete('certs'), isTrue);
    expect(certificates.deleted, containsAll(['/owned/root-new.pem', '/owned/key.pem']));
    expect(credentials.values, isEmpty);
  });

  test('failed cleanup remains queued and retry completes it', () async {
    final store = _MemoryPreferencesStore();
    final certificates = _MemoryCertificateStorage()..failNextDelete = true;
    final repository = _repository(store, certificates: certificates);
    await repository.initialize();
    await repository.add(
      const BrokerEntryModel(
        id: 'certs',
        name: 'Certs',
        host: 'host',
        clientCertificates: ClientCertificateConfigModel(rootCaPath: '/owned/root.pem'),
      ),
    );
    expect(await repository.delete('certs'), isTrue);
    expect(repository.failure?.message, contains('change was saved'));
    expect(store.get(BrokerStorageKeys.pendingResourceCleanup), isNotNull);
    await repository.retry();
    expect(repository.failure, isNull);
    expect(certificates.deleted, ['/owned/root.pem']);
    expect(store.get(BrokerStorageKeys.pendingResourceCleanup), isNull);
  });
}

/// Creates a repository with controllable in-memory resource adapters.
BrokerRepository _repository(_MemoryPreferencesStore store, {_MemoryCredentialStore? credentials, _MemoryCertificateStorage? certificates}) {
  return BrokerRepository(store, credentials: credentials ?? _MemoryCredentialStore(), certificates: certificates ?? _MemoryCertificateStorage());
}

/// Implements preference storage with deterministic failure injection.
class _MemoryPreferencesStore implements PreferencesStore {
  /// Creates a memory store from optional [initial] values.
  _MemoryPreferencesStore([Map<String, Object>? initial]) : values = {...?initial};

  final Map<String, Object> values;
  final Set<String> _failOnce = {};
  int schemaVersionWrites = 0;

  /// Makes the next write or removal for [key] fail.
  void failNextWriteFor(String key) => _failOnce.add(key);

  /// Returns the value stored for [key].
  @override
  Object? get(String key) => values[key];

  /// Returns all stored keys.
  @override
  Set<String> getKeys() => values.keys.toSet();

  /// Stores a boolean value.
  @override
  Future<void> setBool(String key, bool value) => _write(key, value);

  /// Stores a decimal value.
  @override
  Future<void> setDouble(String key, double value) => _write(key, value);

  /// Stores an integer value and tracks schema initialization.
  @override
  Future<void> setInt(String key, int value) {
    if (key == BrokerStorageKeys.schemaVersion) schemaVersionWrites++;
    return _write(key, value);
  }

  /// Stores a string value.
  @override
  Future<void> setString(String key, String value) => _write(key, value);

  /// Applies one write unless failure was requested for [key].
  Future<void> _write(String key, Object value) async {
    if (_failOnce.remove(key)) {
      throw StateError('Injected write failure for $key');
    }
    values[key] = value;
  }

  /// Removes [key] unless failure was requested.
  @override
  Future<void> remove(String key) async {
    if (_failOnce.remove(key)) {
      throw StateError('Injected remove failure for $key');
    }
    values.remove(key);
  }

  /// Removes all values.
  @override
  Future<void> clear() async {
    values.clear();
  }
}

/// Stores secrets in memory and can inject one write failure.
class _MemoryCredentialStore implements CredentialStoreInterface {
  final Map<String, String> values = {};
  bool failNextWrite = false;
  bool corruptNextWrite = false;

  /// Returns a stored secret.
  @override
  Future<String?> read(String reference) async => values[reference];

  /// Stores a secret unless the next write is configured to fail.
  @override
  Future<void> write(String reference, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Injected secure write failure containing $value');
    }
    values[reference] = corruptNextWrite ? 'corrupted' : value;
    corruptNextWrite = false;
  }

  /// Deletes a stored secret.
  @override
  Future<void> delete(String reference) async {
    values.remove(reference);
  }
}

/// Records certificate deletion and can inject one failure.
class _MemoryCertificateStorage implements CertificateStorageInterface {
  final List<String> deleted = [];
  final List<String> duplicated = [];
  bool failNextDelete = false;

  @override
  Future<String> duplicate(String filePath, {required String brokerId, required ClientCertificateKind kind}) async {
    final copied = '$filePath.$brokerId.${kind.name}';
    duplicated.add(copied);
    return copied;
  }

  /// Deletes [filePath] unless the next deletion is configured to fail.
  @override
  Future<void> delete(String filePath) async {
    if (failNextDelete) {
      failNextDelete = false;
      throw StateError('Injected certificate delete failure');
    }
    deleted.add(filePath);
  }
}
