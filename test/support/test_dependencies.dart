import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/broker/certificate_storage.dart';
import 'package:mqtt_monitor/core/broker/credential_store.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds isolated application dependencies for persistence-aware tests.
class TestDependencies {
  /// Creates a test dependency bundle from initialized owners.
  const TestDependencies({
    required this.state,
    required this.brokers,
    required this.preferences,
  });

  final AppStateManager state;
  final BrokerRepository brokers;
  final SharedPreferencesStore preferences;

  /// Resets mock preferences and initializes app and broker state.
  static Future<TestDependencies> create() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferencesStore.load();
    final state = AppStateManager.instance;
    await state.initialize(preferences: preferences);
    await state.resetAll();
    final brokers = BrokerRepository(
      preferences,
      credentials: _MemoryCredentialStore(),
      certificates: _MemoryCertificateStorage(),
    );
    await brokers.initialize();
    return TestDependencies(
      state: state,
      brokers: brokers,
      preferences: preferences,
    );
  }
}

/// Keeps test secrets in memory without invoking a platform plugin.
class _MemoryCredentialStore implements CredentialStore {
  final Map<String, String> _values = {};

  /// Returns the secret stored for [reference].
  @override
  Future<String?> read(String reference) async => _values[reference];

  /// Stores [value] under [reference].
  @override
  Future<void> write(String reference, String value) async =>
      _values[reference] = value;

  /// Deletes the secret stored under [reference].
  @override
  Future<void> delete(String reference) async => _values.remove(reference);
}

/// Discards certificate cleanup requests made by test repositories.
class _MemoryCertificateStorage implements CertificateStorage {
  /// Accepts deletion because test profiles do not own real files.
  @override
  Future<void> delete(String filePath) async {}
}
