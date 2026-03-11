import 'package:flutter/material.dart';
import 'app.dart';
import 'services/mqtt/mqtt_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app state and load persisted values.
  await AppStateManager.instance.initialize();

  // Initialize MQTT service
  MqttService.instance.initialize();

  // Run the app.
  runApp(const App());
}
