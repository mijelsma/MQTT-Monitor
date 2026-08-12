import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/features/settings/panels/ui_panel.dart';
import 'package:mqtt_monitor/features/settings/settings_viewmodel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
  });

  testWidgets('UI settings control sidebar animation and speed', (tester) async {
    final vm = dependencies.createSettingsViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: const Scaffold(body: SizedBox(width: 900, height: 1000, child: UiPanel())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Right panel animations'), findsOneWidget);
    expect(find.text('Panel animation speed'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    await tester.ensureVisible(find.text('Right panel animations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Right panel animations'));
    await tester.pumpAndSettle();
    expect(dependencies.uiPreferences.sidebarAnimationsEnabled, isFalse);
    expect(find.text('Panel animation speed'), findsNothing);

    await tester.tap(find.text('Right panel animations'));
    await tester.pumpAndSettle();
    await dependencies.uiPreferences.setSidebarAnimationSpeed(80);
    await tester.pump();
    expect(find.text('80%'), findsOneWidget);
  });
}
