import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/broker/certificate_storage.dart';
import 'package:mqtt_monitor/core/broker/credential_store.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_connection_intent_store.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_session_controller.dart';
import 'package:mqtt_monitor/core/publishing/publish_command_service.dart';
import 'package:mqtt_monitor/core/publishing/json_payload_validator.dart';
import 'package:mqtt_monitor/core/publishing/qos_preferences_repository.dart';
import 'package:mqtt_monitor/core/publishing/shortcut_repository.dart';
import 'package:mqtt_monitor/core/publishing/template_resolver.dart';
import 'package:mqtt_monitor/core/publishing/variable_repository.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds isolated application dependencies for persistence-aware tests.
class TestDependencies {
  /// Creates a test dependency bundle from initialized owners.
  const TestDependencies({
    required this.state,
    required this.brokers,
    required this.preferences,
    required this.mqttSession,
    required this.publisher,
    required this.shortcuts,
    required this.variables,
    required this.templateResolver,
    required this.qosPreferences,
  });

  final AppStateManager state;
  final BrokerRepository brokers;
  final SharedPreferencesStore preferences;
  final MqttSessionController mqttSession;
  final PublishCommandService publisher;
  final ShortcutRepository shortcuts;
  final VariableRepository variables;
  final TemplateResolver templateResolver;
  final QosPreferencesRepository qosPreferences;

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
    const templateResolver = TemplateResolver();
    final mqttSession = MqttSessionController(
      state,
      brokers,
      MqttConnectionIntentStore(preferences),
    );
    final publisher = PublishCommandService(mqttSession, templateResolver);
    const jsonValidator = JsonPayloadValidator();
    final qosPreferences = QosPreferencesRepository(preferences);
    final variables = VariableRepository(
      preferences,
      brokers,
      templateResolver,
    );
    final shortcuts = ShortcutRepository(
      preferences,
      brokers,
      templateResolver,
      jsonValidator,
    );
    await qosPreferences.initialize();
    await variables.initialize();
    await shortcuts.initialize();
    return TestDependencies(
      state: state,
      brokers: brokers,
      preferences: preferences,
      mqttSession: mqttSession,
      publisher: publisher,
      shortcuts: shortcuts,
      variables: variables,
      templateResolver: templateResolver,
      qosPreferences: qosPreferences,
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
