import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/history/message_history_service.dart';
import 'core/mqtt/mqtt_service.dart';
import 'core/state/app_state.dart';
import 'core/state/keys/settings_keys.dart';
import 'features/monitor/monitor_screen.dart';
import 'generated/l10n.dart';
import 'models/language.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.mqttService, required this.historyService});

  final MqttService mqttService;
  final MessageHistoryService historyService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateManager>.value(value: AppStateManager.instance),
        Provider<MqttService>.value(value: mqttService),
        Provider<MessageHistoryService>.value(value: historyService),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppStateManager, ThemeMode>((s) => s.read(SettingsKeys.themeMode));
    final language = context.select<AppStateManager, AppLanguage>((s) => s.read(SettingsKeys.language));

    return MaterialApp(
      title: 'MQTT Monitor',
      debugShowCheckedModeBanner: false,
      theme: themeLight,
      darkTheme: themeDark,
      themeMode: themeMode,
      locale: Locale(language.name),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: const MonitorScreen(),
    );
  }
}
