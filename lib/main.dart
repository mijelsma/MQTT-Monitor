import 'package:flutter/material.dart';

import 'app.dart';
import 'core/broker/broker_repository.dart';
import 'core/broker/flutter_secure_credential_store.dart';
import 'core/history/message_history_service.dart';
import 'core/mqtt/app_private_certificate_storage.dart';
import 'core/mqtt/mqtt_service.dart';
import 'core/state/app_state.dart';
import 'core/storage/app_data_directory.dart';
import 'core/storage/shared_preferences_store.dart';
import 'core/update/app_update_service.dart';

/// Initializes persistence and process-lifetime services, then starts the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDataDirectory.configure();
  final preferences = await SharedPreferencesStore.load();

  // Initialize app state and load persisted values.
  await AppStateManager.instance.initialize(preferences: preferences);

  final brokerRepository = BrokerRepository(
    preferences,
    credentials: const FlutterSecureCredentialStore(),
    certificates: AppPrivateCertificateStorage.standard(),
  );
  await brokerRepository.initialize();

  // Create and initialize the MQTT service.
  final mqttService = MqttService(AppStateManager.instance, brokerRepository);
  mqttService.initialize();

  // Create and initialize the global history service.
  final historyService = MessageHistoryService(
    mqttService,
    AppStateManager.instance,
    brokerRepository,
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
      brokerRepository: brokerRepository,
    ),
  );

  updater.checkForUpdatesOnStartup();
}
