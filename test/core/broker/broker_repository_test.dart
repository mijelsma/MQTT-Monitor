import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/broker/broker_storage_keys.dart';
import 'package:mqtt_monitor/core/storage/preferences_store.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/client_certificate_config.dart';
import 'package:mqtt_monitor/models/mqtt_protocol_version.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';

void main() {
  const first = BrokerEntry(id: 'first', name: 'First', host: 'first.invalid');
  const second = BrokerEntry(id: 'second', name: 'Second', host: 'second.invalid');

  test('schema initialization is idempotent', () async {
    final store = _MemoryPreferencesStore();
    final repository = BrokerRepository(store);

    await repository.initialize();
    await repository.initialize();

    expect(store.schemaVersionWrites, 1);
    expect(repository.failure, isNull);
  });

  test('fresh storage gets defaults without creating a broker payload', () async {
    final store = _MemoryPreferencesStore();
    final repository = BrokerRepository(store);

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
    final repository = BrokerRepository(store);

    await repository.initialize();

    expect(repository.failure?.message, contains('left unchanged'));
    expect(repository.failure?.details, isNotEmpty);
    expect(repository.brokers, isEmpty);
    expect(store.get(BrokerStorageKeys.profiles), corrupt);
    expect(store.get(BrokerStorageKeys.schemaVersion), BrokerStorageKeys.currentSchemaVersion);
    expect(await repository.add(first), isFalse);
    expect(store.get(BrokerStorageKeys.profiles), corrupt);
  });

  test('a future schema is rejected without modifying stored data', () async {
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion + 1, BrokerStorageKeys.profiles: '[]'});
    final repository = BrokerRepository(store);

    await repository.initialize();

    expect(repository.failure?.details, contains('newer than this app supports'));
    expect(store.values, {BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion + 1, BrokerStorageKeys.profiles: '[]'});
  });

  test('invalid active ID falls back to the first profile and persists the repair', () async {
    final store = _MemoryPreferencesStore({BrokerStorageKeys.schemaVersion: BrokerStorageKeys.currentSchemaVersion, BrokerStorageKeys.profiles: '[{"id":"first","name":"First","host":"first.invalid","subscriptions":[]}]', BrokerStorageKeys.activeProfileId: 'missing'});
    final repository = BrokerRepository(store);

    await repository.initialize();

    expect(repository.activeBrokerId, first.id);
    expect(repository.activeBroker?.id, first.id);
    expect(store.get(BrokerStorageKeys.activeProfileId), first.id);
  });

  test('current broker fields round-trip without loss', () async {
    const broker = BrokerEntry(
      id: 'complete',
      name: 'Complete',
      host: 'mqtt.example.com',
      port: 8883,
      protocolVersion: MqttProtocolVersion.v5,
      clientCertificates: ClientCertificateConfig(rootCaPath: '/certs/root.pem', clientPrivateKeyPath: '/certs/client.key', clientCertificatePath: '/certs/client.pem'),
      useSSL: true,
      validateCertificates: false,
      username: 'user',
      password: 'secret',
      clientId: 'client',
      randomClientIdSuffix: false,
      colorIndex: 4,
      subscriptions: [SubscriptionEntry(topic: 'devices/+/state', qos: 2, name: 'State')],
    );
    final store = _MemoryPreferencesStore();
    final repository = BrokerRepository(store);
    await repository.initialize();

    expect(await repository.add(broker), isTrue);

    final reloaded = BrokerRepository(store);
    await reloaded.initialize();
    expect(reloaded.brokers.single.toJson(), broker.toJson());
  });

  test('CRUD, reorder, selection, and active deletion survive reload', () async {
    final store = _MemoryPreferencesStore();
    final repository = BrokerRepository(store);
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

    final reloaded = BrokerRepository(store);
    await reloaded.initialize();

    expect(reloaded.failure, isNull);
    expect(reloaded.brokers.single.name, 'Updated');
    expect(reloaded.activeBrokerId, first.id);
  });

  test('failed schema initialization can be retried', () async {
    final store = _MemoryPreferencesStore()..failNextWriteFor(BrokerStorageKeys.schemaVersion);
    final repository = BrokerRepository(store);

    await repository.initialize();
    expect(repository.failure, isNotNull);
    expect(store.get(BrokerStorageKeys.profiles), isNull);
    expect(store.get(BrokerStorageKeys.schemaVersion), isNull);

    await repository.retry();
    expect(repository.failure, isNull);
    expect(repository.brokers, isEmpty);
    expect(store.get(BrokerStorageKeys.schemaVersion), BrokerStorageKeys.currentSchemaVersion);
  });

  test('failed multi-key save restores the previous persisted snapshot', () async {
    final store = _MemoryPreferencesStore();
    final repository = BrokerRepository(store);
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
}

class _MemoryPreferencesStore implements PreferencesStore {
  _MemoryPreferencesStore([Map<String, Object>? initial]) : values = {...?initial};

  final Map<String, Object> values;
  final Set<String> _failOnce = {};
  int schemaVersionWrites = 0;

  void failNextWriteFor(String key) => _failOnce.add(key);

  @override
  Object? get(String key) => values[key];

  @override
  Set<String> getKeys() => values.keys.toSet();

  @override
  Future<void> setBool(String key, bool value) => _write(key, value);

  @override
  Future<void> setDouble(String key, double value) => _write(key, value);

  @override
  Future<void> setInt(String key, int value) {
    if (key == BrokerStorageKeys.schemaVersion) schemaVersionWrites++;
    return _write(key, value);
  }

  @override
  Future<void> setString(String key, String value) => _write(key, value);

  Future<void> _write(String key, Object value) async {
    if (_failOnce.remove(key)) {
      throw StateError('Injected write failure for $key');
    }
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (_failOnce.remove(key)) {
      throw StateError('Injected remove failure for $key');
    }
    values.remove(key);
  }

  @override
  Future<void> clear() async => values.clear();
}
