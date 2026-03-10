import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'generated/l10n.dart';
import 'state/app_state.dart';
import 'state/keys/settings_keys.dart';
import 'theme/app_theme.dart';
import 'ui/main/main_screen.dart';
import 'ui/settings/models/language.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStateManager>.value(value: AppStateManager.instance, child: const _AppView());
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
      locale: Locale(language.key),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: const MainScreen(),
    );
  }
}
