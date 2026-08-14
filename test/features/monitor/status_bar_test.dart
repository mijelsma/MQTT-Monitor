import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/connection_status.dart';
import 'package:mqtt_monitor/features/monitor/widgets/status_bar.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';

void main() {
  testWidgets('status presentation uses Dutch localization and semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: themeLight,
        locale: const Locale('nl'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: const Scaffold(bottomNavigationBar: StatusBar(status: ConnectionStatus.connected, messageCount: 12, messageRate: 3, showUpdateAvailable: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verbonden'), findsOneWidget);
    expect(find.text('12 berichten · 3/s'), findsOneWidget);
    expect(find.text('Update beschikbaar'), findsOneWidget);
    expect(find.byTooltip('Update-instellingen openen'), findsOneWidget);
  });
}
