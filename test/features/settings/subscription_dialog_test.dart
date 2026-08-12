import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/features/settings/dialogs/subscription_dialog.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/models/subscription_entry.dart';
import 'package:mqtt_monitor/models/subscription_history_policy.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async => dependencies = await TestDependencies.create());

  Future<SubscriptionEntry?> openDialog(WidgetTester tester, {SubscriptionEntry? entry, bool defaultEnabled = true, int defaultRetention = 10, int maximum = 50, Set<String> existing = const {}}) async {
    SubscriptionEntry? result;
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: dependencies.qosPreferences)],
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showSubscriptionDialog(context, entry: entry, defaultHistoryEnabled: defaultEnabled, defaultHistoryRetention: defaultRetention, maximumHistoryRetention: maximum, existingTopicFilters: existing);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    addTearDown(() {});
    return result;
  }

  testWidgets('new subscriptions use configured history defaults', (tester) async {
    SubscriptionEntry? result;
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: dependencies.qosPreferences)],
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showSubscriptionDialog(context, defaultHistoryEnabled: false, defaultHistoryRetention: 42, maximumHistoryRetention: 100);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final retention = tester.widget<Slider>(find.byType(Slider));
    expect(retention.value, 42);
    expect(retention.max, 100);
    expect(retention.onChanged, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'devices/+/state');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.id, isNotEmpty);
    expect(result!.history, const SubscriptionHistoryPolicy(enabled: false, retention: 42));
  });

  testWidgets('invalid and duplicate topic filters are rejected', (tester) async {
    await openDialog(tester, existing: const {'existing/#'});

    final topic = find.byType(TextFormField).first;
    await tester.enterText(topic, 'bad/#/filter');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Enter a valid MQTT topic filter'), findsOneWidget);

    await tester.enterText(topic, 'existing/#');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('This broker already has that topic filter'), findsOneWidget);
  });

  testWidgets('editing preserves stable identity and updates policy', (tester) async {
    const original = SubscriptionEntry(id: 'stable-id', topic: 'before/#', history: SubscriptionHistoryPolicy(retention: 20));
    SubscriptionEntry? result;
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: dependencies.qosPreferences)],
        child: MaterialApp(
          theme: themeLight,
          localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showSubscriptionDialog(context, entry: original, maximumHistoryRetention: 100);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'after/#');
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(35);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result!.id, 'stable-id');
    expect(result!.topic, 'after/#');
    expect(result!.history.retention, 35);
  });
}
