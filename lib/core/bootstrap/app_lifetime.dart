import 'dart:async';

import '../../features/settings/settings_navigation_controller.dart';
import '../../navigation/app_navigation.dart';
import '../broker/broker_repository.dart';
import '../dashboard/dashboard_preferences_repository.dart';
import '../dashboard/dashboard_repository.dart';
import '../dashboard/dashboard_series_store.dart';
import '../history/history_preferences_repository.dart';
import '../history/message_history_service.dart';
import '../ingestion/message_ingestion_coordinator.dart';
import '../logging/app_logger.dart';
import '../monitor/topic_projection.dart';
import '../mqtt/connection_preferences_repository.dart';
import '../mqtt/session/mqtt_session_controller.dart';
import '../platform/window_chrome.dart';
import '../publishing/json_payload_validator.dart';
import '../publishing/publish_command_service.dart';
import '../publishing/qos_preferences_repository.dart';
import '../publishing/shortcut_repository.dart';
import '../publishing/template_resolver.dart';
import '../publishing/variable_repository.dart';
import '../ui/ui_preferences_repository.dart';
import '../ui/workspace_layout_repository.dart';
import '../update/app_update_service.dart';
import '../update/update_preferences_repository.dart';

typedef AppShutdownAction = FutureOr<void> Function();

class AppShutdownTask {
  const AppShutdownTask(this.name, this.action);

  final String name;
  final AppShutdownAction action;
}

/// Runs shutdown tasks sequentially and records recoverable cleanup failures.
class AppShutdownCoordinator {
  AppShutdownCoordinator(this._tasks, this._logger);

  final List<AppShutdownTask> _tasks;
  final AppLogger _logger;
  Future<void>? _shutdown;

  Future<void> shutdown() => _shutdown ??= _run();

  Future<void> _run() async {
    for (final task in _tasks) {
      try {
        await task.action();
      } on Object catch (error) {
        _logger.log(AppLogLevel.warning, 'app.shutdown', 'Shutdown task ${task.name} failed.', error: error);
      }
    }
  }
}

/// Owns the complete process-lifetime object graph.
class AppLifetime {
  AppLifetime({
    required this.logger,
    required this.connectionPreferences,
    required this.dashboardPreferences,
    required this.historyPreferences,
    required this.workspaceLayout,
    required this.uiPreferences,
    required this.updatePreferences,
    required this.qosPreferences,
    required this.brokerRepository,
    required this.dashboardRepository,
    required this.shortcutRepository,
    required this.variableRepository,
    required this.mqttSession,
    required this.ingestion,
    required this.topicProjection,
    required this.historyService,
    required this.dashboardSeriesStore,
    required this.publisher,
    required this.templateResolver,
    required this.jsonValidator,
    required this.settingsNavigation,
    required this.navigation,
    required this.updater,
    required this.windowChrome,
  }) : _shutdown = AppShutdownCoordinator([
         AppShutdownTask('updater', updater.dispose),
         AppShutdownTask('mqtt session', () async {
           await mqttSession.shutdown();
           mqttSession.dispose();
         }),
         AppShutdownTask('dashboard series', dashboardSeriesStore.dispose),
         AppShutdownTask('history', historyService.dispose),
         AppShutdownTask('topic projection', () async {
           await topicProjection.shutdown();
           topicProjection.dispose();
         }),
         AppShutdownTask('ingestion', ingestion.dispose),
         AppShutdownTask('dashboard repository', dashboardRepository.dispose),
         AppShutdownTask('shortcuts', shortcutRepository.dispose),
         AppShutdownTask('variables', variableRepository.dispose),
         AppShutdownTask('brokers', brokerRepository.dispose),
         AppShutdownTask('settings navigation', settingsNavigation.dispose),
         AppShutdownTask('connection preferences', connectionPreferences.dispose),
         AppShutdownTask('dashboard preferences', dashboardPreferences.dispose),
         AppShutdownTask('history preferences', historyPreferences.dispose),
         AppShutdownTask('workspace layout', workspaceLayout.dispose),
         AppShutdownTask('UI preferences', uiPreferences.dispose),
         AppShutdownTask('update preferences', updatePreferences.dispose),
         AppShutdownTask('QoS preferences', qosPreferences.dispose),
       ], logger);

  final AppLogger logger;
  final ConnectionPreferencesRepository connectionPreferences;
  final DashboardPreferencesRepository dashboardPreferences;
  final HistoryPreferencesRepository historyPreferences;
  final WorkspaceLayoutRepository workspaceLayout;
  final UiPreferencesRepository uiPreferences;
  final UpdatePreferencesRepository updatePreferences;
  final QosPreferencesRepository qosPreferences;
  final BrokerRepository brokerRepository;
  final DashboardRepository dashboardRepository;
  final ShortcutRepository shortcutRepository;
  final VariableRepository variableRepository;
  final MqttSessionController mqttSession;
  final MessageIngestionCoordinator ingestion;
  final TopicProjection topicProjection;
  final MessageHistoryService historyService;
  final DashboardSeriesStore dashboardSeriesStore;
  final PublishCommandService publisher;
  final TemplateResolver templateResolver;
  final JsonPayloadValidator jsonValidator;
  final SettingsNavigationController settingsNavigation;
  final AppNavigation navigation;
  final AppUpdateService updater;
  final WindowChromeController windowChrome;
  final AppShutdownCoordinator _shutdown;

  Future<void> dispose() => _shutdown.shutdown();
}
