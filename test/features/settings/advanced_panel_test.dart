import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/features/settings/panels/advanced_panel.dart';
import 'package:mqtt_monitor/features/settings/settings_viewmodel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';
import 'package:mqtt_monitor/models/subscription_history_policy.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  final state = AppStateManager.instance;
  late BrokerRepository brokers;

  setUp(() async {
    final dependencies = await TestDependencies.create();
    brokers = dependencies.brokers;
  });

  Future<SettingsViewModel> pumpPanel(WidgetTester tester) async {
    final viewModel = SettingsViewModel(
      state: state,
      brokerRepository: brokers,
    );
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsViewModel>.value(
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
          home: const Scaffold(
            body: SizedBox(width: 700, height: 900, child: AdvancedPanel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  testWidgets('shows validated defaults for new subscription history', (
    tester,
  ) async {
    await pumpPanel(tester);

    expect(state.read(SettingsKeys.newSubscriptionHistoryEnabled), isTrue);
    expect(state.read(SettingsKeys.newSubscriptionHistoryRetention), 10);
    expect(state.read(SettingsKeys.maximumHistoryRetention), 50);
    expect(find.text('New subscription history'), findsOneWidget);
    expect(find.text('Default retention'), findsOneWidget);
    expect(find.text('Maximum retention'), findsOneWidget);
  });

  testWidgets('history controls expose domain-supported ranges', (
    tester,
  ) async {
    await pumpPanel(tester);

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders, hasLength(2));
    expect(sliders.first.min, 1);
    expect(sliders.first.max, 50);
    expect(sliders.first.value, 10);
    expect(sliders.last.min, 50);
    expect(sliders.last.max, 1000);
    expect(sliders.last.value, 50);
    expect(sliders.last.divisions, 19);
  });

  testWidgets('turning off the new policy disables its retention slider', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final defaultRetention = tester
        .widgetList<Slider>(find.byType(Slider))
        .first;
    expect(defaultRetention.onChanged, isNull);
    expect(state.read(SettingsKeys.newSubscriptionHistoryEnabled), isFalse);
  });

  testWidgets('maximum reduction can be cancelled or explicitly confirmed', (
    tester,
  ) async {
    await state.write(SettingsKeys.maximumHistoryRetention, 500);
    await brokers.add(
      const BrokerEntry(
        id: 'broker',
        name: 'Broker',
        host: 'broker.invalid',
        subscriptions: [
          SubscriptionEntry(
            id: 'subscription',
            topic: '#',
            history: SubscriptionHistoryPolicy(retention: 100),
          ),
        ],
      ),
    );
    await pumpPanel(tester);

    Slider maximumSlider() =>
        tester.widgetList<Slider>(find.byType(Slider)).last;

    maximumSlider().onChanged!(50);
    await tester.pump();
    maximumSlider().onChangeEnd!(50);
    await tester.pumpAndSettle();

    expect(find.text('Reduce history maximum?'), findsOneWidget);
    expect(find.text('Saved subscription policies: 1'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.read(SettingsKeys.maximumHistoryRetention), 500);
    expect(brokers.activeBroker!.subscriptions.single.history.retention, 100);

    maximumSlider().onChanged!(50);
    await tester.pump();
    maximumSlider().onChangeEnd!(50);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(state.read(SettingsKeys.maximumHistoryRetention), 50);
    expect(brokers.activeBroker!.subscriptions.single.history.retention, 50);
  });

  testWidgets('advanced warning retains emphasized themed styling', (
    tester,
  ) async {
    await pumpPanel(tester);

    final warning = tester.widget<Text>(
      find.textContaining('affect performance'),
    );
    expect(warning.style?.fontWeight, FontWeight.w600);
    expect(warning.style?.color, isNotNull);
  });

  testWidgets('reset requires confirmation and restores defaults', (
    tester,
  ) async {
    await state.write(SettingsKeys.showStatusBar, false);
    await brokers.add(
      const BrokerEntry(id: 'broker', name: 'Broker', host: 'broker.invalid'),
    );
    await pumpPanel(tester);
    final resetButton = find.text('Reset everything');
    await tester.ensureVisible(resetButton);

    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    expect(find.text('Reset all settings?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.read(SettingsKeys.showStatusBar), isFalse);
    expect(brokers.brokers, hasLength(1));

    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset everything').last);
    await tester.pumpAndSettle();

    expect(state.read(SettingsKeys.showStatusBar), isTrue);
    expect(brokers.brokers, isEmpty);
    expect(find.text('All settings were reset to defaults.'), findsOneWidget);
  });
}
