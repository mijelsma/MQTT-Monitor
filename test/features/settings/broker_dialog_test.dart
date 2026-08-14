import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/repositories/history_preferences_repository.dart';
import 'package:mqtt_monitor/core/logging/app_logger.dart';
import 'package:mqtt_monitor/core/mqtt/repositories/connection_preferences_repository.dart';
import 'package:mqtt_monitor/features/settings/dialogs/broker_dialog.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/mqtt_protocol_version_model.dart';
import 'package:mqtt_monitor/shared/widgets/ui_segment_row.dart';
import 'package:mqtt_monitor/shared/widgets/ui_switch_row.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
  });

  Future<void> pumpDialog(WidgetTester tester, {BrokerEntryModel? broker}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HistoryPreferencesRepository>.value(value: dependencies.historyPreferences),
          ChangeNotifierProvider<ConnectionPreferencesRepository>.value(value: dependencies.connectionPreferences),
          ChangeNotifierProvider.value(value: dependencies.qosPreferences),
          Provider<AppLogger>.value(value: dependencies.logger),
        ],
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: Center(child: BrokerDialog(broker: broker)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('new broker dialog pre-fills a catch-all # subscription named locally', (tester) async {
    await pumpDialog(tester);

    expect(find.text('Every topic'), findsOneWidget, reason: 'the default subscription is added with the localized name');
    expect(find.text('#'), findsOneWidget, reason: 'the default subscription covers every topic');
    expect(find.text('Add Subscription'), findsOneWidget, reason: 'the dialog still allows adding more subscriptions');
  });

  testWidgets('editing an existing broker does not inject a default subscription', (tester) async {
    await pumpDialog(
      tester,
      broker: const BrokerEntryModel(id: 'b1', name: 'Existing', host: 'broker.invalid'),
    );

    expect(find.text('Every topic'), findsNothing);
    expect(find.text('#'), findsNothing);
  });

  testWidgets('new broker dialog renders the default in the configured locale', (tester) async {
    await pumpDialog(tester);

    expect(S.current.brokerDialogDefaultSubscriptionName, 'Every topic');
    expect(find.text(S.current.brokerDialogDefaultSubscriptionName), findsOneWidget);
  });

  testWidgets('new brokers use the configured protocol and safe TLS defaults', (tester) async {
    await dependencies.connectionPreferences.setBrokerProtocol(MqttProtocolVersionModel.v311);
    await pumpDialog(tester);

    final protocol = tester.widget<UiSegmentRow<MqttProtocolVersionModel>>(find.byWidgetPredicate((widget) => widget is UiSegmentRow<MqttProtocolVersionModel> && widget.label == 'Protocol version'));
    expect(protocol.value, MqttProtocolVersionModel.v311);
    expect(find.text('Validate Certificates'), findsNothing);

    final ssl = tester.widget<UiSwitchRow>(find.byWidgetPredicate((widget) => widget is UiSwitchRow && widget.label == S.current.brokerDialogUseSSL));
    ssl.onChanged(true);
    await tester.pump();

    final validation = tester.widget<UiSwitchRow>(find.byWidgetPredicate((widget) => widget is UiSwitchRow && widget.label == S.current.brokerDialogValidateCertificates));
    expect(validation.value, isFalse);
  });
}
