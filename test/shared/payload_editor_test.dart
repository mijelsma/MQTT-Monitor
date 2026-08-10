import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/shared/widgets/payload_editor.dart';
import 'package:mqtt_monitor/theme/app_tokens/app_tokens.dart';

void main() {
  testWidgets('validation errors do not overflow the JSON line-number gutter', (
    tester,
  ) async {
    final controller = HighlightingController(
      text: '''{
  "event": "sample.update",
  "device": "demo-sensor-01",
  "request_id": "example-request-123",
  "result": "ok",
  "detail": "Demonstration payload for editor layout testing"
}''',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 180,
            child: PayloadEditor(
              controller: controller,
              format: PayloadFormat.json,
              onFormatChanged: (_) {},
              validationError: 'Ln 7, col 1: Unexpected character.',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });
}
