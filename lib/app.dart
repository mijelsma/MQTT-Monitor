import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'state/keys/settings_keys.dart';
import 'theme/app_theme.dart';
import 'ui/main/main_screen.dart';

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

    return MaterialApp(title: 'MQTT Monitor', debugShowCheckedModeBanner: false, theme: themeLight, darkTheme: themeDark, themeMode: themeMode, home: const MainScreen());
  }
}
