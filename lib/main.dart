import 'package:flutter/material.dart';

import 'app.dart';
import 'core/broker/broker_repository.dart';
import 'core/broker/flutter_secure_credential_store.dart';
import 'core/dashboard/dashboard_repository.dart';
import 'core/dashboard/dashboard_series_store.dart';
import 'core/history/message_history_service.dart';
import 'core/ingestion/message_ingestion_coordinator.dart';
import 'core/monitor/topic_projection.dart';
import 'core/mqtt/app_private_certificate_storage.dart';
import 'core/mqtt/session/mqtt_connection_intent_store.dart';
import 'core/mqtt/session/mqtt_session_controller.dart';
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

  final brokerRepository = BrokerRepository(preferences, credentials: const FlutterSecureCredentialStore(), certificates: AppPrivateCertificateStorage.standard());
  await brokerRepository.initialize();
  final dashboardRepository = DashboardRepository(preferences, brokerRepository);
  await dashboardRepository.initialize();

  // Create process-lifetime ingestion and broker-scoped projections before
  // starting the active session so no decoded message can outrun a consumer.
  final mqttSession = MqttSessionController(AppStateManager.instance, brokerRepository, MqttConnectionIntentStore(preferences));
  final ingestion = MessageIngestionCoordinator(mqttSession, brokerRepository);
  final topicProjection = TopicProjection(ingestion, brokerRepository);
  final historyService = MessageHistoryService(ingestion, AppStateManager.instance, brokerRepository);
  final dashboardSeriesStore = DashboardSeriesStore(messages: ingestion.messages, repository: dashboardRepository, state: AppStateManager.instance);
  ingestion.initialize();
  topicProjection.initialize();
  historyService.initialize();
  dashboardSeriesStore.initialize();
  mqttSession.initialize();

  // The update service is global so update state survives navigation to
  // Settings › About.
  final updater = AppUpdateService(state: AppStateManager.instance);

  // Run the app.
  runApp(App(mqttSession: mqttSession, ingestion: ingestion, topicProjection: topicProjection, historyService: historyService, updater: updater, brokerRepository: brokerRepository, dashboardRepository: dashboardRepository, dashboardSeriesStore: dashboardSeriesStore));

  updater.checkForUpdatesOnStartup();
}
