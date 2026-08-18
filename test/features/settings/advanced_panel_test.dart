import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/repositories/broker_repository.dart';
import 'package:mqtt_monitor/core/dashboard/repositories/dashboard_preferences_repository.dart';
import 'package:mqtt_monitor/core/dashboard/repositories/dashboard_repository.dart';
import 'package:mqtt_monitor/core/storage/services/app_storage_location_service.dart';
import 'package:mqtt_monitor/features/settings/panels/advanced_panel.dart';
import 'package:mqtt_monitor/features/settings/view_models/settings_view_model.dart';
import 'package:mqtt_monitor/features/settings/settings_reset_section.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/dashboard/models/dashboard_layout_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/subscription_history_policy_model.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late BrokerRepository brokers;
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
  });

  Future<SettingsViewModel> pumpPanel(WidgetTester tester, {AppStorageLocationService? storageLocations}) async {
    final viewModel = dependencies.createSettingsViewModel();
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsViewModel>.value(
        value: viewModel,
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 700, height: 900, child: AdvancedPanel(storageLocations: storageLocations)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  testWidgets('shows validated defaults for new subscription history', (tester) async {
    await pumpPanel(tester);

    expect(dependencies.historyPreferences.newSubscriptionEnabled, isTrue);
    expect(dependencies.historyPreferences.newSubscriptionRetention, 10);
    expect(dependencies.historyPreferences.maximumRetention, 50);
    expect(find.text('New subscription history'), findsOneWidget);
    expect(find.text('Default retention'), findsOneWidget);
    expect(find.text('Maximum retention'), findsOneWidget);
    expect(find.text('Rich formatting limit'), findsOneWidget);
    expect(find.text('32 KB'), findsOneWidget);
  });

  testWidgets('history controls expose domain-supported ranges', (tester) async {
    await pumpPanel(tester);

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders, hasLength(3));
    expect(sliders.first.min, 1);
    expect(sliders.first.max, 50);
    expect(sliders.first.value, 10);
    expect(sliders[1].min, 50);
    expect(sliders[1].max, 1000);
    expect(sliders[1].value, 50);
    expect(sliders[1].divisions, 19);
    expect(sliders.last.min, 8);
    expect(sliders.last.max, 256);
    expect(sliders.last.value, 32);
    expect(sliders.last.divisions, 31);
  });

  testWidgets('turning off the new policy disables its retention slider', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final defaultRetention = tester.widgetList<Slider>(find.byType(Slider)).first;
    expect(defaultRetention.onChanged, isNull);
    expect(dependencies.historyPreferences.newSubscriptionEnabled, isFalse);
  });

  testWidgets('maximum reduction can be cancelled or explicitly confirmed', (tester) async {
    await dependencies.historyPreferences.setMaximumRetention(500);
    await brokers.add(
      const BrokerEntryModel(
        id: 'broker',
        name: 'Broker',
        host: 'broker.invalid',
        subscriptions: [SubscriptionEntryModel(id: 'subscription', topic: '#', history: SubscriptionHistoryPolicyModel(retention: 100))],
      ),
    );
    await pumpPanel(tester);

    Slider maximumSlider() => tester.widgetList<Slider>(find.byType(Slider)).elementAt(1);

    maximumSlider().onChanged!(50);
    await tester.pump();
    maximumSlider().onChangeEnd!(50);
    await tester.pumpAndSettle();

    expect(find.text('Reduce history maximum?'), findsOneWidget);
    expect(find.text('Saved subscription policies: 1'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(dependencies.historyPreferences.maximumRetention, 500);
    expect(brokers.activeBroker!.subscriptions.single.history.retention, 100);

    maximumSlider().onChanged!(50);
    await tester.pump();
    maximumSlider().onChangeEnd!(50);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(dependencies.historyPreferences.maximumRetention, 50);
    expect(brokers.activeBroker!.subscriptions.single.history.retention, 50);
  });

  testWidgets('advanced warning retains emphasized themed styling', (tester) async {
    await pumpPanel(tester);

    final warning = tester.widget<Text>(find.textContaining('affect performance'));
    expect(warning.style?.fontWeight, FontWeight.w600);
    expect(warning.style?.color, isNotNull);
  });

  testWidgets('shows the resolved settings and diagnostic log locations', (tester) async {
    final service = AppStorageLocationService(operatingSystem: 'linux', environment: const {'HOME': '/home/tester', 'XDG_DATA_HOME': '/profile/data'}, launcher: (_) async => true);
    await pumpPanel(tester, storageLocations: service);

    expect(find.text('STORAGE AND DIAGNOSTICS'), findsOneWidget);
    expect(find.text('/profile/data/MQTT-Monitor/shared_preferences.json'), findsOneWidget);
    expect(find.text('/profile/data/MQTT-Monitor/logs/mqtt-monitor.log'), findsOneWidget);
    expect(find.text('Open folder'), findsOneWidget);
    expect(find.text('Open log'), findsOneWidget);
  });

  testWidgets('reset checklist keeps unchecked sections and resets selected ones', (tester) async {
    await dependencies.uiPreferences.setShowStatusBar(false);
    await dependencies.updatePreferences.setTracksBetaReleases(true);
    await brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'broker.invalid'));
    await pumpPanel(tester);
    final resetButton = find.text('Select data to reset');
    await tester.ensureVisible(resetButton);

    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    expect(find.text('Choose what to reset'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    expect(find.text('User interface'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(dependencies.uiPreferences.showStatusBar, isFalse);
    expect(dependencies.updatePreferences.tracksBetaReleases, isTrue);
    expect(brokers.brokers, hasLength(1));

    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    final userInterface = find.text('User interface');
    await tester.ensureVisible(userInterface);
    await tester.tap(userInterface);
    await tester.pump();
    await tester.tap(find.text('Reset selected'));
    await tester.pumpAndSettle();

    expect(dependencies.uiPreferences.showStatusBar, isTrue);
    expect(dependencies.updatePreferences.tracksBetaReleases, isTrue);
    expect(brokers.brokers, hasLength(1));
    expect(find.text('The selected data was reset.'), findsOneWidget);
  });

  testWidgets('select all resets every section', (tester) async {
    await dependencies.uiPreferences.setShowStatusBar(false);
    await dependencies.updatePreferences.setTracksBetaReleases(true);
    await brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'broker.invalid'));
    await pumpPanel(tester);

    await tester.ensureVisible(find.text('Select data to reset'));
    await tester.tap(find.text('Select data to reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset selected'));
    await tester.pumpAndSettle();

    expect(dependencies.uiPreferences.showStatusBar, isTrue);
    expect(dependencies.updatePreferences.tracksBetaReleases, isFalse);
    expect(brokers.brokers, isEmpty);
  });

  test('view model resets only requested repository groups', () async {
    await dependencies.uiPreferences.setShowStatusBar(false);
    await dependencies.updatePreferences.setTracksBetaReleases(true);
    await brokers.add(const BrokerEntryModel(id: 'broker', name: 'Broker', host: 'broker.invalid'));
    final viewModel = dependencies.createSettingsViewModel();
    addTearDown(viewModel.dispose);

    final result = await viewModel.resetSettingsToDefaults({SettingsResetSection.updates});

    expect(result.succeeded, isTrue);
    expect(dependencies.updatePreferences.tracksBetaReleases, isFalse);
    expect(dependencies.uiPreferences.showStatusBar, isFalse);
    expect(brokers.brokers, hasLength(1));
  });

  test('section reset removes only its owned preference namespace', () async {
    await dependencies.uiPreferences.setShowStatusBar(false);
    await dependencies.workspaceLayout.setMonitorSplitRatio(0.7);
    await dependencies.updatePreferences.setTracksBetaReleases(true);
    final viewModel = dependencies.createSettingsViewModel();
    addTearDown(viewModel.dispose);

    expect(dependencies.preferences.get('settings.showStatusBar'), isFalse);
    expect(dependencies.preferences.get('settings.trackBetaReleases'), isTrue);

    await viewModel.resetSettingsToDefaults({SettingsResetSection.userInterface});

    expect(dependencies.preferences.get('settings.showStatusBar'), isNull);
    expect(dependencies.workspaceLayout.monitorSplitRatio, 0.5);
    expect(dependencies.preferences.get('settings.trackBetaReleases'), isTrue);
  });

  test('dashboard group resets saved dashboards and dashboard defaults', () async {
    final dashboards = DashboardRepository(dependencies.preferences, dependencies.brokers);
    await dashboards.initialize();
    addTearDown(dashboards.dispose);
    await dashboards.setLayouts([DashboardLayoutModel(id: 'saved', title: 'Saved')]);
    await dependencies.dashboardPreferences.setDotSize(8);
    final viewModel = dependencies.createSettingsViewModel(dashboardRepository: dashboards);
    addTearDown(viewModel.dispose);

    await viewModel.resetSettingsToDefaults({SettingsResetSection.dashboards});

    expect(dashboards.layouts, isEmpty);
    expect(dependencies.dashboardPreferences.dotSize, DashboardPreferencesRepository.defaultDotSize);
  });
}
