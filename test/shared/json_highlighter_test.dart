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
          body: JsonHighlighter(source: '{"voltage": ["226.5", "227.5", "227.8"]}', onPin: (keyPath, _) => pinnedPaths.add(keyPath)),
        ),
      ),
    );

    final pins = find.byIcon(Icons.push_pin_rounded);
    expect(pins, findsNWidgets(3));

    await tester.tap(pins.at(1));
    expect(pinnedPaths, ['voltage.[1]']);
  });

  testWidgets('expands a compact numeric array before offering its pin targets', (tester) async {
    final pinnedPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Scaffold(
          body: JsonHighlighter(source: '{"samples":[1,2,3]}', maxInlineArrayItems: 3, onPin: (keyPath, _) => pinnedPaths.add(keyPath)),
        ),
      ),
    );

    expect(find.byIcon(Icons.unfold_more_rounded), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.unfold_more_rounded));
    await tester.pump();

    final pins = find.byIcon(Icons.push_pin_rounded);
    expect(pins, findsNWidgets(3));
    await tester.tap(pins.first);
    expect(pinnedPaths, ['samples.[0]']);
  });

  testWidgets('keeps an expanded array open when a new payload arrives', (tester) async {
    Widget build(String payload) => MaterialApp(
      theme: ThemeData(extensions: const [AppTokens.light]),
      home: Scaffold(
        body: JsonHighlighter(key: const ValueKey('payload'), source: payload, maxInlineArrayItems: 3, onPin: (_, _) {}),
      ),
    );

    await tester.pumpWidget(build('{"samples":[1,2,3]}'));
    await tester.tap(find.byIcon(Icons.unfold_more_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.push_pin_rounded), findsNWidgets(3));

    await tester.pumpWidget(build('{"samples":[4,5,6]}'));
    expect(find.byIcon(Icons.push_pin_rounded), findsNWidgets(3));
  });

  testWidgets('uses zero-based paths for values in nested arrays', (tester) async {
    final pinnedPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Scaffold(
          body: JsonHighlighter(source: '{"my_array":[[110,32.69,-22.52]]}', onPin: (keyPath, _) => pinnedPaths.add(keyPath)),
        ),
      ),
    );

    final pins = find.byIcon(Icons.push_pin_rounded);
    expect(pins, findsNWidgets(3));
    for (var index = 0; index < 3; index++) {
      await tester.tap(pins.at(index));
    }

    expect(pinnedPaths, ['my_array.[0].[0]', 'my_array.[0].[1]', 'my_array.[0].[2]']);
  });

  testWidgets('increments each nested parent array index independently', (tester) async {
    final pinnedPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Scaffold(
          body: JsonHighlighter(source: '{"matrix":[[1,2],[3,4]]}', onPin: (keyPath, _) => pinnedPaths.add(keyPath)),
        ),
      ),
    );

    final pins = find.byIcon(Icons.push_pin_rounded);
    expect(pins, findsNWidgets(4));
    for (var index = 0; index < 4; index++) {
      await tester.tap(pins.at(index));
    }

    expect(pinnedPaths, ['matrix.[0].[0]', 'matrix.[0].[1]', 'matrix.[1].[0]', 'matrix.[1].[1]']);
  });
}
