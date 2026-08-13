import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/broker/certificate_storage.dart';
import 'package:mqtt_monitor/core/broker/credential_store.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_preferences_repository.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_repository.dart';
import 'package:mqtt_monitor/core/history/history_preferences_repository.dart';
import 'package:mqtt_monitor/core/history/message_history_service.dart';
import 'package:mqtt_monitor/core/logging/app_logger.dart';
import 'package:mqtt_monitor/core/mqtt/connection_preferences_repository.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_connection_intent_store.dart';
import 'package:mqtt_monitor/core/mqtt/session/mqtt_session_controller.dart';
import 'package:mqtt_monitor/core/publishing/publish_command_service.dart';
import 'package:mqtt_monitor/core/publishing/json_payload_validator.dart';
import 'package:mqtt_monitor/core/publishing/qos_preferences_repository.dart';
import 'package:mqtt_monitor/core/publishing/shortcut_repository.dart';
import 'package:mqtt_monitor/core/publishing/template_resolver.dart';
import 'package:mqtt_monitor/core/publishing/variable_repository.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:mqtt_monitor/core/ui/ui_preferences_repository.dart';
import 'package:mqtt_monitor/core/ui/workspace_layout_repository.dart';
import 'package:mqtt_monitor/core/update/update_preferences_repository.dart';
import 'package:mqtt_monitor/features/settings/settings_navigation_controller.dart';
import 'package:mqtt_monitor/features/settings/settings_viewmodel.dart';
import 'package:mqtt_monitor/navigation/app_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds isolated application dependencies for persistence-aware tests.
class TestDependencies {
  /// Creates a test dependency bundle from initialized owners.
  const TestDependencies({
    required this.logger,
    required this.brokers,
    required this.preferences,
    required this.mqttSession,
    required this.publisher,
    required this.shortcuts,
    required this.variables,
    required this.templateResolver,
    required this.qosPreferences,
    required this.uiPreferences,
    required this.updatePreferences,
    required this.connectionPreferences,
    required this.dashboardPreferences,
    required this.historyPreferences,
    required this.workspaceLayout,
    required this.settingsNavigation,
    required this.navigation,
  });

  final LocalAppLogger logger;
  final BrokerRepository brokers;
  final SharedPreferencesStore preferences;
  final MqttSessionController mqttSession;
  final PublishCommandService publisher;
  final ShortcutRepository shortcuts;
  final VariableRepository variables;
  final TemplateResolver templateResolver;
  final QosPreferencesRepository qosPreferences;
  final UiPreferencesRepository uiPreferences;
  final UpdatePreferencesRepository updatePreferences;
  final ConnectionPreferencesRepository connectionPreferences;
  final DashboardPreferencesRepository dashboardPreferences;
  final HistoryPreferencesRepository historyPreferences;
  final WorkspaceLayoutRepository workspaceLayout;
  final SettingsNavigationController settingsNavigation;
  final AppNavigation navigation;

  /// Creates a settings view model wired to this isolated dependency graph.
  SettingsViewModel createSettingsViewModel({DashboardRepository? dashboardRepository, MessageHistoryService? historyService}) => SettingsViewModel(
    navigation: settingsNavigation,
    connectionPreferences: connectionPreferences,
    dashboardPreferences: dashboardPreferences,
    historyPreferences: historyPreferences,
    workspaceLayout: workspaceLayout,
    logger: logger,
    brokerRepository: brokers,
    shortcutRepository: shortcuts,
    variableRepository: variables,
    qosPreferences: qosPreferences,
    uiPreferences: uiPreferences,
    updatePreferences: updatePreferences,
    mqttSession: mqttSession,
    dashboardRepository: dashboardRepository,
    historyService: historyService,
  );

  /// Resets mock preferences and initializes app and broker state.
  static Future<TestDependencies> create() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferencesStore.load();
    final logger = LocalAppLogger();
    final uiPreferences = UiPreferencesRepository(preferences);
    final updatePreferences = UpdatePreferencesRepository(preferences);
    final connectionPreferences = ConnectionPreferencesRepository(preferences);
    final dashboardPreferences = DashboardPreferencesRepository(preferences);
    final historyPreferences = HistoryPreferencesRepository(preferences);
    await uiPreferences.initialize();
    await updatePreferences.initialize();
    await connectionPreferences.initialize();
    await dashboardPreferences.initialize();
    await historyPreferences.initialize();
    final workspaceLayout = WorkspaceLayoutRepository(preferences, persistLayout: uiPreferences.persistLayout);
    await workspaceLayout.initialize();
    final brokers = BrokerRepository(preferences, credentials: _MemoryCredentialStore(), certificates: _MemoryCertificateStorage());
    await brokers.initialize();
    const templateResolver = TemplateResolver();
    final mqttSession = MqttSessionController(connectionPreferences, brokers, MqttConnectionIntentStore(preferences), logger: logger);
    final publisher = PublishCommandService(mqttSession, templateResolver);
    const jsonValidator = JsonPayloadValidator();
    final qosPreferences = QosPreferencesRepository(preferences);
    final variables = VariableRepository(preferences, brokers, templateResolver);
    final shortcuts = ShortcutRepository(preferences, brokers, templateResolver, jsonValidator);
    await qosPreferences.initialize();
    await variables.initialize();
    await shortcuts.initialize();
    final settingsNavigation = SettingsNavigationController();
    return TestDependencies(
      logger: logger,
      brokers: brokers,
      preferences: preferences,
      mqttSession: mqttSession,
      publisher: publisher,
      shortcuts: shortcuts,
      variables: variables,
      templateResolver: templateResolver,
      qosPreferences: qosPreferences,
      uiPreferences: uiPreferences,
      updatePreferences: updatePreferences,
      connectionPreferences: connectionPreferences,
      dashboardPreferences: dashboardPreferences,
      historyPreferences: historyPreferences,
      workspaceLayout: workspaceLayout,
      settingsNavigation: settingsNavigation,
      navigation: AppNavigation(settingsNavigation),
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
  Future<void> write(String reference, String value) async => _values[reference] = value;

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
