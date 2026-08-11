import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/broker_repository_failure.dart';
import 'package:mqtt_monitor/features/monitor/widgets/broker_load_failure_state.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';

void main() {
  testWidgets('shows a recoverable broker storage error', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: themeLight,
        home: BrokerLoadFailureState(
          failure: const BrokerRepositoryFailure(message: 'Stored profiles were left unchanged.', details: 'FormatException'),
          onRetry: () async {
            retries++;
          },
        ),
      ),
    );

    expect(find.text('Broker profiles unavailable'), findsOneWidget);
    expect(find.text('Stored profiles were left unchanged.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 1);
  });
}
