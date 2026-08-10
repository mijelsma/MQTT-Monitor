import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/widgets/json_highlighter.dart';
import 'package:mqtt_monitor/theme/app_colors.dart';
import 'package:mqtt_monitor/theme/app_tokens/app_tokens.dart';

void main() {
  test('highlights every string in an array as a value', () {
    const json = '''
{
  "v": [
    "226.5",
    "227.5",
    "227.8"
  ]
}''';

    final spans = JsonHighlighter.highlight(json, false, AppTokens.light);
    final values = spans.where((span) => span.text?.startsWith('"') ?? false).toList();

    expect(values.map((span) => span.text), ['"v"', '"226.5"', '"227.5"', '"227.8"']);
    expect((values.first.style as TextStyle).color, AppTokens.light.primary);
    for (final value in values.skip(1)) {
      expect((value.style as TextStyle).color, AppColors.success700);
    }
  });

  testWidgets('offers numeric strings in arrays as pinnable values', (tester) async {
    final pinnedPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Scaffold(
          body: JsonHighlighter(
            source: '{"voltage": ["226.5", "227.5", "227.8"]}',
            onPin: (keyPath, _) => pinnedPaths.add(keyPath),
          ),
        ),
      ),
    );

    final pins = find.byIcon(Icons.push_pin_rounded);
    expect(pins, findsNWidgets(3));

    await tester.tap(pins.at(1));
    expect(pinnedPaths, ['voltage.[1]']);
  });
}
