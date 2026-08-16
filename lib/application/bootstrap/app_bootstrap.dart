import 'dart:async';
import 'dart:io';

import '../../core/broker/repositories/broker_repository.dart';
import '../../core/broker/flutter_secure_credential_store.dart';
import '../../core/dashboard/repositories/dashboard_preferences_repository.dart';
import '../../core/dashboard/repositories/dashboard_repository.dart';
import '../../core/dashboard/dashboard_series_store.dart';
import '../../core/history/repositories/history_preferences_repository.dart';
import '../../core/history/services/message_history_service.dart';
import '../../core/ingestion/message_ingestion_coordinator.dart';
import '../../core/logging/app_logger.dart';
import '../../core/monitor/topic_projection.dart';
import '../../core/mqtt/app_private_certificate_storage.dart';
import '../../core/mqtt/repositories/connection_preferences_repository.dart';
import '../../core/mqtt/session/mqtt_connection_intent_store.dart';
import '../../core/mqtt/session/mqtt_session_controller.dart';
import '../../core/platform/controllers/window_chrome_controller.dart';
import '../../core/publishing/json_payload_validator.dart';
import '../../core/publishing/services/publish_command_service.dart';
import '../../core/publishing/repositories/qos_preferences_repository.dart';
import '../../core/publishing/repositories/shortcut_repository.dart';
import '../../core/publishing/template_resolver.dart';
import '../../core/publishing/repositories/variable_repository.dart';
import '../../core/storage/app_data_directory.dart';
import '../../core/storage/preferences_store.dart';
import '../../core/storage/shared_preferences_store.dart';
import '../../core/storage/services/app_storage_location_service.dart';
import '../../core/ui/repositories/ui_preferences_repository.dart';
import '../../core/ui/repositories/workspace_layout_repository.dart';
import '../../core/update/services/app_update_service.dart';
import '../../core/update/repositories/update_preferences_repository.dart';
import '../../core/../features/settings/controllers/settings_navigation_controller.dart';
import '../../core/../navigation/app_navigation.dart';
import 'app_lifetime.dart';

abstract interface class AppBootstrap {
  Future<AppLifetime> initialize();
}

class AppInitializationFailure implements Exception {
  const AppInitializationFailure(this.stage, this.cause);

  final String stage;
  final Object cause;

  @override
  String toString() => 'Application initialization failed during $stage.';
}

class AppInitializationStage {
  const AppInitializationStage(this.name, this.run);

  final String name;
  final FutureOr<void> Function() run;
}

/// Testable sequential initialization primitive used by production bootstrap.
class StagedInitializer<T> {
  StagedInitializer({required this.stages, required this.assemble, required this.logger, this.onFailure});

  final List<AppInitializationStage> stages;
  final FutureOr<T> Function() assemble;
  final AppLogger logger;
  final FutureOr<void> Function()? onFailure;

  Future<T> initialize() async {
    var stage = 'assembly';
    try {
      for (final next in stages) {
        stage = next.name;
        logger.log(AppLogLevel.debug, 'app.bootstrap', 'Starting $stage.');
        await next.run();
      }
      stage = 'assembly';
      return await assemble();
    } on Object catch (error) {
      logger.log(AppLogLevel.error, 'app.bootstrap', 'Application initialization failed during $stage.', error: error);
      try {
        await onFailure?.call();
      } on Object catch (cleanupError) {
        logger.log(AppLogLevel.warning, 'app.bootstrap', 'Partial application initialization cleanup failed.', error: cleanupError);
      }
      throw AppInitializationFailure(stage, error);
    }
  }
}

/// Builds a fresh application graph for each startup or retry attempt.
class ProductionAppBootstrap implements AppBootstrap {
  factory ProductionAppBootstrap({LocalAppLogger? logger}) {
    final storageLocations = Platform.isIOS ? null : AppStorageLocationService.standard();
    return ProductionAppBootstrap._(logger ?? LocalAppLogger(logFilePath: storageLocations?.diagnosticLogFilePath), updateInstallerDiagnosticsLogPath: storageLocations?.updateInstallerDiagnosticLogFilePath);
  }

  ProductionAppBootstrap._(this.logger, {required this.updateInstallerDiagnosticsLogPath});

  final LocalAppLogger logger;
  final String? updateInstallerDiagnosticsLogPath;

  @override
  Future<AppLifetime> initialize() {
    final builder = _ProductionLifetimeBuilder(logger, updateInstallerDiagnosticsLogPath: updateInstallerDiagnosticsLogPath);
    return StagedInitializer<AppLifetime>(
      logger: logger,
      stages: [
        AppInitializationStage('application data directory', builder.configureDataDirectory),
        AppInitializationStage('preferences', builder.initializePreferences),
        AppInitializationStage('broker and dashboard storage', builder.initializeBrokerDomains),
        AppInitializationStage('publishing repositories', builder.initializePublishingDomains),
        AppInitializationStage('message pipeline', builder.initializeMessagePipeline),
      ],
      assemble: builder.assemble,
      onFailure: builder.disposePartial,
    ).initialize();
  }
}

class _ProductionLifetimeBuilder {
  _ProductionLifetimeBuilder(this.logger, {required this.updateInstallerDiagnosticsLogPath});

  final LocalAppLogger logger;
  final String? updateInstallerDiagnosticsLogPath;

  PreferencesStore? store;
  UiPreferencesRepository? uiPreferences;
  UpdatePreferencesRepository? updatePreferences;
  ConnectionPreferencesRepository? connectionPreferences;
  DashboardPreferencesRepository? dashboardPreferences;
  HistoryPreferencesRepository? historyPreferences;
  WorkspaceLayoutRepository? workspaceLayout;
  QosPreferencesRepository? qosPreferences;
  BrokerRepository? brokers;
  DashboardRepository? dashboards;
  VariableRepository? variables;
  ShortcutRepository? shortcuts;
  MqttSessionController? mqtt;
  MessageIngestionCoordinator? ingestion;
  TopicProjection? projection;
  MessageHistoryService? history;
  DashboardSeriesStore? series;
  PublishCommandService? publisher;
  TemplateResolver? templateResolver;
  JsonPayloadValidator? jsonValidator;
  SettingsNavigationController? settingsNavigation;
  AppNavigation? navigation;
  AppUpdateService? updater;
  WindowChromeController? windowChrome;

  Future<void> configureDataDirectory() => AppDataDirectory.configure();

  Future<void> initializePreferences() async {
    final preferences = await SharedPreferencesStore.load();
    store = preferences;
    final ui = UiPreferencesRepository(preferences);
    final updates = UpdatePreferencesRepository(preferences);
    final connection = ConnectionPreferencesRepository(preferences);
    final dashboard = DashboardPreferencesRepository(preferences);
    final history = HistoryPreferencesRepository(preferences);
    final qos = QosPreferencesRepository(preferences);
    uiPreferences = ui;
    updatePreferences = updates;
    connectionPreferences = connection;
    dashboardPreferences = dashboard;
    historyPreferences = history;
    qosPreferences = qos;
    await ui.initialize();
    await updates.initialize();
    await connection.initialize();
    await dashboard.initialize();
    await history.initialize();
    await qos.initialize();
    final layout = WorkspaceLayoutRepository(preferences, persistLayout: ui.persistLayout);
    workspaceLayout = layout;
    await layout.initialize();
  }

  Future<void> initializeBrokerDomains() async {
    final preferences = store!;
    final brokerRepository = BrokerRepository(preferences, credentials: const FlutterSecureCredentialStore(), certificates: AppPrivateCertificateStorage.standard());
    brokers = brokerRepository;
    await brokerRepository.initialize();
    final dashboardRepository = DashboardRepository(preferences, brokerRepository);
    dashboards = dashboardRepository;
    await dashboardRepository.initialize();
  }

  Future<void> initializePublishingDomains() async {
    const resolver = TemplateResolver();
    const validator = JsonPayloadValidator();
    final variableRepository = VariableRepository(store!, brokers!, resolver);
    final shortcutRepository = ShortcutRepository(store!, brokers!, resolver, validator);
    templateResolver = resolver;
    jsonValidator = validator;
    variables = variableRepository;
    shortcuts = shortcutRepository;
    await variableRepository.initialize();
    await shortcutRepository.initialize();
  }

  void initializeMessagePipeline() {
    final session = MqttSessionController(connectionPreferences!, brokers!, MqttConnectionIntentStore(store!), logger: logger);
    final commandService = PublishCommandService(session, templateResolver!, jsonValidator: jsonValidator!);
    final coordinator = MessageIngestionCoordinator(session, brokers!);
    final topicProjection = TopicProjection(coordinator, brokers!, coalesceStructureUpdates: true);
    final historyService = MessageHistoryService(coordinator, historyPreferences!, brokers!);
    final seriesStore = DashboardSeriesStore(messages: coordinator.messages, repository: dashboards!, variables: variables!, templateResolver: templateResolver!);
    mqtt = session;
    publisher = commandService;
    ingestion = coordinator;
    projection = topicProjection;
    history = historyService;
    series = seriesStore;
    coordinator.initialize();
    topicProjection.initialize();
    historyService.initialize();
    seriesStore.initialize();
    session.initialize();
  }

  AppLifetime assemble() {
    final settings = SettingsNavigationController();
    final appNavigation = AppNavigation(settings);
    final appUpdater = AppUpdateService(preferences: updatePreferences!, diagnosticsLogPath: updateInstallerDiagnosticsLogPath);
    final chrome = PlatformWindowChromeController(logger);
    settingsNavigation = settings;
    navigation = appNavigation;
    updater = appUpdater;
    windowChrome = chrome;
    return AppLifetime(
      logger: logger,
      connectionPreferences: connectionPreferences!,
      dashboardPreferences: dashboardPreferences!,
      historyPreferences: historyPreferences!,
      workspaceLayout: workspaceLayout!,
      uiPreferences: uiPreferences!,
      updatePreferences: updatePreferences!,
      qosPreferences: qosPreferences!,
      brokerRepository: brokers!,
      dashboardRepository: dashboards!,
      shortcutRepository: shortcuts!,
      variableRepository: variables!,
      mqttSession: mqtt!,
      ingestion: ingestion!,
      topicProjection: projection!,
      historyService: history!,
      dashboardSeriesStore: series!,
      publisher: publisher!,
      templateResolver: templateResolver!,
      jsonValidator: jsonValidator!,
      settingsNavigation: settings,
      navigation: appNavigation,
      updater: appUpdater,
      windowChrome: chrome,
    );
  }

  Future<void> disposePartial() async {
    final tasks = <AppShutdownTask>[
      if (updater case final value?) AppShutdownTask('partial updater', value.dispose),
      if (mqtt case final value?)
        AppShutdownTask('partial MQTT session', () async {
          await value.shutdown();
          value.dispose();
        }),
      if (series case final value?) AppShutdownTask('partial dashboard series', value.dispose),
      if (history case final value?) AppShutdownTask('partial history', value.dispose),
      if (projection case final value?)
        AppShutdownTask('partial topic projection', () async {
          await value.shutdown();
          value.dispose();
        }),
      if (ingestion case final value?) AppShutdownTask('partial ingestion', value.dispose),
      if (dashboards case final value?) AppShutdownTask('partial dashboard repository', value.dispose),
      if (shortcuts case final value?) AppShutdownTask('partial shortcuts', value.dispose),
      if (variables case final value?) AppShutdownTask('partial variables', value.dispose),
      if (brokers case final value?) AppShutdownTask('partial brokers', value.dispose),
      if (settingsNavigation case final value?) AppShutdownTask('partial settings navigation', value.dispose),
      if (connectionPreferences case final value?) AppShutdownTask('partial connection preferences', value.dispose),
      if (dashboardPreferences case final value?) AppShutdownTask('partial dashboard preferences', value.dispose),
      if (historyPreferences case final value?) AppShutdownTask('partial history preferences', value.dispose),
      if (workspaceLayout case final value?) AppShutdownTask('partial workspace layout', value.dispose),
      if (uiPreferences case final value?) AppShutdownTask('partial UI preferences', value.dispose),
      if (updatePreferences case final value?) AppShutdownTask('partial update preferences', value.dispose),
      if (qosPreferences case final value?) AppShutdownTask('partial QoS preferences', value.dispose),
      AppShutdownTask('partial diagnostic log', logger.flush),
    ];
    await AppShutdownCoordinator(tasks, logger).shutdown();
  }
}
