import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/features/settings/controllers/settings_navigation_controller.dart';
import 'package:mqtt_monitor/features/settings/settings_section.dart';
import 'package:mqtt_monitor/navigation/app_navigation.dart';

void main() {
  testWidgets('settings and dashboard use centralized route workflows', (tester) async {
    final settings = SettingsNavigationController();
    final navigation = AppNavigation(
      settings,
      settingsPageBuilder: (_) => const Scaffold(body: Text('Settings route')),
      dashboardPageBuilder: (brokerId, brokerName) => Scaffold(body: Text('Dashboard route: $brokerId / $brokerName')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => navigation.openSettings<void>(context, section: SettingsSection.advanced),
                child: const Text('Open settings'),
              ),
              TextButton(
                onPressed: () => navigation.openDashboard<void>(context, brokerId: 'broker-1', brokerName: 'Workshop'),
                child: const Text('Open dashboard'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings route'), findsOneWidget);
    expect(settings.section, SettingsSection.advanced);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard route: broker-1 / Workshop'), findsOneWidget);
  });
}
