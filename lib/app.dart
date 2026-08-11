import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/broker/broker_repository.dart';
import 'core/history/message_history_service.dart';
import 'core/mqtt/mqtt_service.dart';
import 'core/platform/window_chrome.dart';
import 'core/state/app_state.dart';
import 'core/state/keys/settings_keys.dart';
import 'core/update/app_update_service.dart';
import 'features/monitor/monitor_screen.dart';
import 'generated/l10n.dart';
import 'models/language.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens/app_tokens.dart';

/// Provides application-wide services and builds the themed MQTT Monitor app.
class App extends StatelessWidget {
  /// Creates the application root with its process-lifetime dependencies.
  const App({super.key, required this.mqttService, required this.historyService, required this.updater, required this.brokerRepository});

  final MqttService mqttService;
  final MessageHistoryService historyService;
  final AppUpdateService updater;
  final BrokerRepository brokerRepository;

  /// Exposes root dependencies before building the visual application shell.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateManager>.value(value: AppStateManager.instance),
        ChangeNotifierProvider<BrokerRepository>.value(value: brokerRepository),
        Provider<MqttService>.value(value: mqttService),
        Provider<MessageHistoryService>.value(value: historyService),
        ChangeNotifierProvider<AppUpdateService>.value(value: updater),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final AppStateManager _state;
  Brightness? _lastAppearance;

  Brightness get _effectiveBrightness {
    final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return switch (_state.read(SettingsKeys.themeMode)) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
  }

  @override
  void initState() {
    super.initState();
    _state = AppStateManager.instance;
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
    final themeMode = context.select<AppStateManager, ThemeMode>((s) => s.read(SettingsKeys.themeMode));
    final language = context.select<AppStateManager, AppLanguage>((s) => s.read(SettingsKeys.language));
    final accentValue = context.select<AppStateManager, int>((s) => s.read(SettingsKeys.accentColor));
    final accent = Color(accentValue);

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAppearance());

    return MaterialApp(
      title: 'MQTT Monitor',
      debugShowCheckedModeBanner: false,
      theme: _applyAccent(themeLight, accent, Brightness.light),
      darkTheme: _applyAccent(themeDark, accent, Brightness.dark),
      themeMode: themeMode,
      locale: Locale(language.name),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: const MonitorScreen(),
    );
  }
}

ThemeData _applyAccent(ThemeData base, Color accent, Brightness brightness) {
  final baseTokens = base.extension<AppTokens>()!;
  final isLight = brightness == Brightness.light;
  final tokens = baseTokens.copyWith(primary: accent, selectedBg: isLight ? accent.withValues(alpha: 0.08) : baseTokens.selectedBg);
  final scheme = base.colorScheme.copyWith(primary: accent, primaryContainer: Color.lerp(accent, Colors.white, isLight ? 0.85 : 0.0)!, inversePrimary: Color.lerp(accent, Colors.white, 0.25)!);
  return base.copyWith(colorScheme: scheme, extensions: <ThemeExtension<dynamic>>[tokens]);
}
