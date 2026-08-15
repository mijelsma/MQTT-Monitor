import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/widgets/ui_surface.dart';
import 'package:mqtt_monitor/theme/app_tokens/app_tokens.dart';

void main() {
  testWidgets('uses semantic theme surface values by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: const Scaffold(body: UiSurface(child: Text('Grouped content'))),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;

    expect(decoration.color, AppTokens.light.surface);
    expect(border.top.color, AppTokens.light.border);
    expect(decoration.borderRadius, BorderRadius.circular(AppTokens.light.panelRadius));
    expect(find.text('Grouped content'), findsOneWidget);
  });

  testWidgets('allows a component to override its semantic surface values', (tester) async {
    const background = Color(0xFF123456);
    const border = Color(0xFF654321);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: const Scaffold(
          body: UiSurface(backgroundColor: background, borderColor: border, radius: 8, child: SizedBox()),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;
    final resolvedBorder = decoration.border! as Border;

    expect(decoration.color, background);
    expect(resolvedBorder.top.color, border);
    expect(decoration.borderRadius, BorderRadius.circular(8));
  });
}
