import 'package:flutter/material.dart';
import 'app.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStateManager.instance.initialize();
  runApp(const App());
}
