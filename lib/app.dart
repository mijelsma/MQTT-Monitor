import 'package:flutter/material.dart';
import 'ui/main_screen/main_screen.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'MQTT Monitor', debugShowCheckedModeBanner: false, theme: themeLight, darkTheme: themeDark, themeMode: ThemeMode.system, home: const MainScreen());
  }
}
