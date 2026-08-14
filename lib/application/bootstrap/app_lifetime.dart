import 'dart:async';

import '../../core/../features/settings/controllers/settings_navigation_controller.dart';
import '../../core/../navigation/app_navigation.dart';
import '../../core/broker/repositories/broker_repository.dart';
import '../../core/dashboard/repositories/dashboard_preferences_repository.dart';
import '../../core/dashboard/repositories/dashboard_repository.dart';
import '../../core/dashboard/dashboard_series_store.dart';
import '../../core/history/repositories/history_preferences_repository.dart';
import '../../core/history/services/message_history_service.dart';
import '../../core/ingestion/message_ingestion_coordinator.dart';
import '../../core/logging/app_logger.dart';
import '../../core/monitor/topic_projection.dart';
import '../../core/mqtt/repositories/connection_preferences_repository.dart';
import '../../core/mqtt/session/mqtt_session_controller.dart';
import '../../core/platform/controllers/window_chrome_controller.dart';
import '../../core/publishing/json_payload_validator.dart';
import '../../core/publishing/services/publish_command_service.dart';
import '../../core/publishing/repositories/qos_preferences_repository.dart';
import '../../core/publishing/repositories/shortcut_repository.dart';
import '../../core/publishing/template_resolver.dart';
import '../../core/publishing/repositories/variable_repository.dart';
import '../../core/ui/repositories/ui_preferences_repository.dart';
import '../../core/ui/repositories/workspace_layout_repository.dart';
import '../../core/update/services/app_update_service.dart';
import '../../core/update/repositories/update_preferences_repository.dart';

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
         AppShutdownTask('diagnostic log', logger.flush),
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
