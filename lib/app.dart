import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'application/bootstrap/app_lifetime.dart';
import 'core/broker/repositories/broker_repository.dart';
import 'core/dashboard/repositories/dashboard_preferences_repository.dart';
import 'core/dashboard/repositories/dashboard_repository.dart';
import 'core/dashboard/dashboard_series_store.dart';
import 'core/history/repositories/history_preferences_repository.dart';
import 'core/history/services/message_history_service.dart';
import 'core/ingestion/message_ingestion_coordinator.dart';
import 'core/logging/app_logger.dart';
import 'core/monitor/topic_projection.dart';
import 'core/mqtt/repositories/connection_preferences_repository.dart';
import 'core/mqtt/session/mqtt_session_controller.dart';
import 'core/platform/window_chrome_lifecycle.dart';
import 'core/publishing/json_payload_validator.dart';
import 'core/publishing/services/publish_command_service.dart';
import 'core/publishing/repositories/qos_preferences_repository.dart';
import 'core/publishing/repositories/shortcut_repository.dart';
import 'core/publishing/template_resolver.dart';
import 'core/publishing/repositories/variable_repository.dart';
import 'core/ui/repositories/ui_preferences_repository.dart';
import 'core/ui/models/ui_density_model.dart';
import 'core/ui/repositories/workspace_layout_repository.dart';
import 'core/update/services/app_update_service.dart';
import 'core/update/app_update_lifecycle.dart';
import 'core/update/repositories/update_preferences_repository.dart';
import 'features/monitor/monitor_screen.dart';
import 'features/settings/controllers/settings_navigation_controller.dart';
import 'generated/l10n.dart';
import 'navigation/app_navigation.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_builder.dart';

/// Exposes the owned application lifetime and builds the visual shell.
class App extends StatelessWidget {
  const App({super.key, required this.lifetime});

  final AppLifetime lifetime;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppLogger>.value(value: lifetime.logger),
        ChangeNotifierProvider<ConnectionPreferencesRepository>.value(value: lifetime.connectionPreferences),
        ChangeNotifierProvider<DashboardPreferencesRepository>.value(value: lifetime.dashboardPreferences),
        ChangeNotifierProvider<HistoryPreferencesRepository>.value(value: lifetime.historyPreferences),
        ChangeNotifierProvider<WorkspaceLayoutRepository>.value(value: lifetime.workspaceLayout),
        ChangeNotifierProvider<UiPreferencesRepository>.value(value: lifetime.uiPreferences),
        ChangeNotifierProvider<UpdatePreferencesRepository>.value(value: lifetime.updatePreferences),
        ChangeNotifierProvider<QosPreferencesRepository>.value(value: lifetime.qosPreferences),
        ChangeNotifierProvider<BrokerRepository>.value(value: lifetime.brokerRepository),
        ChangeNotifierProvider<DashboardRepository>.value(value: lifetime.dashboardRepository),
        ChangeNotifierProvider<ShortcutRepository>.value(value: lifetime.shortcutRepository),
        ChangeNotifierProvider<VariableRepository>.value(value: lifetime.variableRepository),
        ChangeNotifierProvider<MqttSessionController>.value(value: lifetime.mqttSession),
        ChangeNotifierProvider<TopicProjection>.value(value: lifetime.topicProjection),
        ChangeNotifierProvider<SettingsNavigationController>.value(value: lifetime.settingsNavigation),
        ChangeNotifierProvider<AppUpdateService>.value(value: lifetime.updater),
        Provider<MessageIngestionCoordinator>.value(value: lifetime.ingestion),
        Provider<MessageHistoryService>.value(value: lifetime.historyService),
        Provider<DashboardSeriesStore>.value(value: lifetime.dashboardSeriesStore),
        Provider<PublishCommandService>.value(value: lifetime.publisher),
        Provider<TemplateResolver>.value(value: lifetime.templateResolver),
        Provider<JsonPayloadValidator>.value(value: lifetime.jsonValidator),
        Provider<AppNavigation>.value(value: lifetime.navigation),
      ],
      child: WindowChromeLifecycle(
        preferences: lifetime.uiPreferences,
        controller: lifetime.windowChrome,
        child: AppUpdateLifecycle(service: lifetime.updater, child: const _AppView()),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<UiPreferencesRepository, ThemeMode>((preferences) => preferences.themeMode);
    final language = context.select<UiPreferencesRepository, String>((preferences) => preferences.language.name);
    final accentValue = context.select<UiPreferencesRepository, int>((preferences) => preferences.accentColor);
    final density = context.select<UiPreferencesRepository, UiDensityModel>((preferences) => preferences.density);
    final accent = Color(accentValue);

    return MaterialApp(
      title: 'MQTT Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppThemeBuilder.withAccent(themeLight, accent, Brightness.light, compact: density == UiDensityModel.compact),
      darkTheme: AppThemeBuilder.withAccent(themeDark, accent, Brightness.dark, compact: density == UiDensityModel.compact),
      themeMode: themeMode,
      locale: Locale(language),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: const MonitorScreen(),
    );
  }
}
