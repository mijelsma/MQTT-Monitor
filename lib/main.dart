import 'package:flutter/material.dart';
import 'package:desktop_updater/desktop_updater.dart';

import 'app.dart';
import 'core/history/message_history_service.dart';
import 'core/mqtt/mqtt_service.dart';
import 'core/state/app_state.dart';
import 'core/update/app_update_configuration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Checks are initiated only from Settings › About. Keeping the controller
  // global preserves its download/install state if the settings route closes.
  final updater = DesktopUpdaterController(
    appArchiveUrl: AppUpdateConfiguration.appArchiveUrl,
    channel: AppUpdateConfiguration.channel,
    allowUnsignedMacOSUpdates: AppUpdateConfiguration.allowUnsignedMacOSUpdates,
    skipInitialVersionCheck: true,
  );

  // Run the app.
  runApp(
    App(
      mqttService: mqttService,
      historyService: historyService,
      updater: updater,
    ),
  );
}
