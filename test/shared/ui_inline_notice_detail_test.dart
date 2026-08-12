import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/widgets/ui_inline_notice.dart';
import 'package:mqtt_monitor/theme/app_tokens/app_tokens.dart';

void main() {
  testWidgets('detail toggle is left aligned with the body text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: const Scaffold(
          body: UiInlineNotice(kind: UiNoticeKind.error, title: 'Connection failed', subtitle: 'Broker Name · mqtts://host:8883', message: 'Bad username or password.\nCheck your username and password in the broker settings.', detail: 'mqtt-client::NoConnectionException: The maximum allowed connection attempts ({1}) were exceeded.'),
        ),
      ),
    );

    final messageDx = tester.getTopLeft(find.textContaining('Bad username')).dx;
    final arrowDx = tester.getTopLeft(find.byIcon(Icons.expand_more_rounded)).dx;
    final labelDx = tester.getTopLeft(find.text('Show details')).dx;

    expect(arrowDx, messageDx, reason: 'the arrow must line up with the message text');
    expect(labelDx, greaterThan(arrowDx), reason: 'the label follows the arrow');

    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hide details'), findsOneWidget);
    expect(find.textContaining('NoConnectionException'), findsOneWidget);
  });

  testWidgets('notice action is keyboard focusable and activatable', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Scaffold(
          body: UiInlineNotice(kind: UiNoticeKind.warning, title: 'Action needed', actionLabel: 'Retry', onAction: () => activations++),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 1);
    expect(tester.getSemantics(find.text('Retry')), matchesSemantics(hasTapAction: true, hasFocusAction: true, hasEnabledState: true, isEnabled: true, isButton: true, isFocusable: true, isFocused: true));
  });
}
