import 'package:flutter/material.dart';

import 'app.dart';
import 'core/mqtt/mqtt_service.dart';
import 'core/state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app state and load persisted values.
  await AppStateManager.instance.initialize();

  // Create and initialize the MQTT service.
  final mqttService = MqttService(AppStateManager.instance);
  mqttService.initialize();

  // Run the app.
  runApp(App(mqttService: mqttService));
}
