import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/broker/broker_repository.dart';
import 'core/dashboard/dashboard_repository.dart';
import 'core/dashboard/dashboard_series_store.dart';
import 'core/history/message_history_service.dart';
import 'core/ingestion/message_ingestion_coordinator.dart';
import 'core/monitor/topic_projection.dart';
import 'core/mqtt/session/mqtt_session_controller.dart';
import 'core/publishing/publish_command_service.dart';
import 'core/publishing/json_payload_validator.dart';
import 'core/publishing/qos_preferences_repository.dart';
import 'core/publishing/shortcut_repository.dart';
import 'core/publishing/template_resolver.dart';
import 'core/publishing/variable_repository.dart';
import 'core/platform/window_chrome.dart';
import 'core/state/app_state.dart';
import 'core/update/app_update_service.dart';
import 'core/update/app_update_lifecycle.dart';
import 'core/update/update_preferences_repository.dart';
import 'core/ui/ui_preferences_repository.dart';
import 'features/monitor/monitor_screen.dart';
import 'generated/l10n.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_builder.dart';

/// Provides application-wide services and builds the themed MQTT Monitor app.
class App extends StatelessWidget {
  /// Creates the application root with its process-lifetime dependencies.
  const App({
    super.key,
    required this.mqttSession,
    required this.ingestion,
    required this.topicProjection,
    required this.historyService,
    required this.updatePreferences,
    required this.createUpdater,
    required this.brokerRepository,
    required this.dashboardRepository,
    required this.dashboardSeriesStore,
    required this.publisher,
    required this.shortcutRepository,
    required this.variableRepository,
    required this.templateResolver,
    required this.jsonValidator,
    required this.qosPreferences,
    required this.uiPreferences,
  });

  final MqttSessionController mqttSession;
  final MessageIngestionCoordinator ingestion;
  final TopicProjection topicProjection;
  final MessageHistoryService historyService;
  final UpdatePreferencesRepository updatePreferences;
  final AppUpdateService Function() createUpdater;
  final BrokerRepository brokerRepository;
  final DashboardRepository dashboardRepository;
  final DashboardSeriesStore dashboardSeriesStore;
  final PublishCommandService publisher;
  final ShortcutRepository shortcutRepository;
  final VariableRepository variableRepository;
  final TemplateResolver templateResolver;
  final JsonPayloadValidator jsonValidator;
  final QosPreferencesRepository qosPreferences;
  final UiPreferencesRepository uiPreferences;

  /// Exposes root dependencies before building the visual application shell.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateManager>.value(value: AppStateManager.instance),
        ChangeNotifierProvider<BrokerRepository>.value(value: brokerRepository),
        ChangeNotifierProvider<DashboardRepository>.value(value: dashboardRepository),
        Provider<DashboardSeriesStore>.value(value: dashboardSeriesStore),
        Provider<PublishCommandService>.value(value: publisher),
        ChangeNotifierProvider<ShortcutRepository>.value(value: shortcutRepository),
        ChangeNotifierProvider<VariableRepository>.value(value: variableRepository),
        Provider<TemplateResolver>.value(value: templateResolver),
        Provider<JsonPayloadValidator>.value(value: jsonValidator),
        ChangeNotifierProvider<QosPreferencesRepository>.value(value: qosPreferences),
        ChangeNotifierProvider<UiPreferencesRepository>.value(value: uiPreferences),
        ChangeNotifierProvider<UpdatePreferencesRepository>.value(value: updatePreferences),
        ChangeNotifierProvider<MqttSessionController>.value(value: mqttSession),
        Provider<MessageIngestionCoordinator>.value(value: ingestion),
        ChangeNotifierProvider<TopicProjection>.value(value: topicProjection),
        Provider<MessageHistoryService>.value(value: historyService),
      ],
      child: AppUpdateLifecycle(create: createUpdater, child: const _AppView()),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final UiPreferencesRepository _preferences;
  Brightness? _lastAppearance;

  Brightness get _effectiveBrightness {
    final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return switch (_preferences.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
  }

  @override
  void initState() {
    super.initState();
    _preferences = context.read<UiPreferencesRepository>();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = _syncAppearance;
    _syncAppearance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  void _syncAppearance() {
    final brightness = _effectiveBrightness;
    if (brightness == _lastAppearance) return;
    _lastAppearance = brightness;
    WindowChrome.setAppearance(brightness);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<UiPreferencesRepository, ThemeMode>((preferences) => preferences.themeMode);
    final language = context.select<UiPreferencesRepository, String>((preferences) => preferences.language.name);
    final accentValue = context.select<UiPreferencesRepository, int>((preferences) => preferences.accentColor);
    final accent = Color(accentValue);

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAppearance());

    return MaterialApp(
      title: 'MQTT Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppThemeBuilder.withAccent(themeLight, accent, Brightness.light),
      darkTheme: AppThemeBuilder.withAccent(themeDark, accent, Brightness.dark),
      themeMode: themeMode,
      locale: Locale(language),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: const MonitorScreen(),
    );
  }
}
