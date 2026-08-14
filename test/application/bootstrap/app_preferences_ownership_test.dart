import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/dashboard/repositories/dashboard_preferences_repository.dart';
import 'package:mqtt_monitor/core/history/repositories/history_preferences_repository.dart';
import 'package:mqtt_monitor/core/mqtt/repositories/connection_preferences_repository.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:mqtt_monitor/core/ui/repositories/workspace_layout_repository.dart';
import 'package:mqtt_monitor/core/dashboard/models/chart_type_model.dart';
import 'package:mqtt_monitor/core/dashboard/models/interpolation_mode_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/mqtt_protocol_version_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/startup_connection_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fresh connection preferences use production-friendly defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = ConnectionPreferencesRepository(await SharedPreferencesStore.load());

    await repository.initialize();

    expect(repository.startupConnection, StartupConnectionModel.alwaysConnect);
    expect(repository.brokerProtocol, MqttProtocolVersionModel.v5);
  });

  test('typed owners round-trip the remaining version 1 settings', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferencesStore.load();
    final connection = ConnectionPreferencesRepository(store);
    final dashboard = DashboardPreferencesRepository(store);
    final history = HistoryPreferencesRepository(store);
    final layout = WorkspaceLayoutRepository(store, persistLayout: true);
    await Future.wait([connection.initialize(), dashboard.initialize(), history.initialize(), layout.initialize()]);

    await connection.setRateIntervalMs(2500);
    await connection.setStartupConnection(StartupConnectionModel.stayDisconnected);
    await connection.setBrokerProtocol(MqttProtocolVersionModel.v311);
    await dashboard.setDotSize(7.5);
    await dashboard.setCardColor(0xFF123456);
    await dashboard.setChartType(ChartTypeModel.bar);
    await dashboard.setInterpolation(InterpolationModeModel.stepped);
    await dashboard.setMaximumSamples(125);
    await history.setNewSubscriptionEnabled(false);
    await history.setNewSubscriptionRetention(25);
    await history.setMaximumRetention(100);
    await history.setRateSampleSize(20);
    await layout.setMonitorSplitRatio(0.7);
    await layout.setCollapsed(3, false);

    final restoredConnection = ConnectionPreferencesRepository(store);
    final restoredDashboard = DashboardPreferencesRepository(store);
    final restoredHistory = HistoryPreferencesRepository(store);
    final restoredLayout = WorkspaceLayoutRepository(store, persistLayout: true);
    await Future.wait([restoredConnection.initialize(), restoredDashboard.initialize(), restoredHistory.initialize(), restoredLayout.initialize()]);

    expect(restoredConnection.rateIntervalMs, 2500);
    expect(restoredConnection.startupConnection, StartupConnectionModel.stayDisconnected);
    expect(restoredConnection.brokerProtocol, MqttProtocolVersionModel.v311);
    expect(restoredDashboard.dotSize, 7.5);
    expect(restoredDashboard.cardColor, 0xFF123456);
    expect(restoredDashboard.chartType, ChartTypeModel.bar);
    expect(restoredDashboard.interpolation, InterpolationModeModel.stepped);
    expect(restoredDashboard.maximumSamples, 125);
    expect(restoredHistory.newSubscriptionEnabled, isFalse);
    expect(restoredHistory.newSubscriptionRetention, 25);
    expect(restoredHistory.maximumRetention, 100);
    expect(restoredHistory.rateSampleSize, 20);
    expect(restoredLayout.monitorSplitRatio, 0.7);
    expect(restoredLayout.collapsed, [false, true, true, false]);

    expect(store.get(ConnectionPreferencesRepository.schemaVersionKey), ConnectionPreferencesRepository.currentSchemaVersion);
    expect(store.get(DashboardPreferencesRepository.schemaVersionKey), DashboardPreferencesRepository.currentSchemaVersion);
    expect(store.get(HistoryPreferencesRepository.schemaVersionKey), HistoryPreferencesRepository.currentSchemaVersion);
    expect(store.get(WorkspaceLayoutRepository.schemaVersionKey), WorkspaceLayoutRepository.currentSchemaVersion);
  });

  test('unsupported schema fails explicitly instead of guessing', () async {
    SharedPreferences.setMockInitialValues({ConnectionPreferencesRepository.schemaVersionKey: 2});
    final store = await SharedPreferencesStore.load();

    await expectLater(ConnectionPreferencesRepository(store).initialize(), throwsA(isA<StateError>()));
  });
}
