import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_repository.dart';
import 'package:mqtt_monitor/features/settings/panels/dashboard_panel.dart';
import 'package:mqtt_monitor/features/settings/settings_viewmodel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  testWidgets('sample slider exposes 1 then five-sample stops through 1000', (
    tester,
  ) async {
    final dependencies = await TestDependencies.create();
    final dashboard = DashboardRepository(
      dependencies.preferences,
      dependencies.brokers,
    );
    await dashboard.initialize();
    final viewModel = SettingsViewModel(
      state: dependencies.state,
      brokerRepository: dependencies.brokers,
      shortcutRepository: dependencies.shortcuts,
      variableRepository: dependencies.variables,
      qosPreferences: dependencies.qosPreferences,
      dashboardRepository: dashboard,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const Scaffold(body: DashboardPanel()),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider).last);
    expect(slider.min, 0);
    expect(slider.max, 200);
    expect(slider.divisions, 200);
    expect(slider.semanticFormatterCallback!(0), '1');
    expect(slider.semanticFormatterCallback!(1), '5');
    expect(slider.semanticFormatterCallback!(200), '1000');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
    expect(
      find.text(
        'Marker size for data points in new line graphs. Choose 0 to hide markers.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Maximum number of recent values retained by each new graph.'),
      findsOneWidget,
    );

    slider.onChanged!(0);
    await tester.pump();
    expect(viewModel.defaultMaxSamples, 1);
    expect(find.text('1'), findsNWidgets(2));

    tester.widget<Slider>(find.byType(Slider).last).onChanged!(1);
    await tester.pump();
    expect(viewModel.defaultMaxSamples, 5);

    viewModel.dispose();
    dashboard.dispose();
  });
}
