import 'package:flutter/material.dart';

import 'app.dart';
import 'core/history/message_history_service.dart';
import 'core/mqtt/mqtt_service.dart';
import 'core/state/app_state.dart';
import 'core/storage/app_data_directory.dart';
import 'core/update/app_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDataDirectory.configure();

  // Initialize app state and load persisted values.
  await AppStateManager.instance.initialize();

  // Create and initialize the MQTT service.
  final mqttService = MqttService(AppStateManager.instance);
  mqttService.initialize();

  // Create and initialize the global history service.
  final historyService = MessageHistoryService(
    mqttService,
    AppStateManager.instance,
  );
  historyService.initialize();

  // The update service is global so update state survives navigation to
  // Settings › About.
  final updater = AppUpdateService(state: AppStateManager.instance);

  // Run the app.
  runApp(
    App(
      mqttService: mqttService,
      historyService: historyService,
      updater: updater,
    ),
  );

  updater.checkForUpdatesOnStartup();
}
