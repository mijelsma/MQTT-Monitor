import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/widgets/ui_inline_segment_row.dart';
import 'package:mqtt_monitor/shared/widgets/ui_segment_row.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';

void main() {
  testWidgets('full-width segments expose selection semantics and keyboard activation', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: themeLight,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: UiSegmentRow<int>(
              label: 'Mode',
              options: const [
                UiSegmentOption(value: 0, label: 'First'),
                UiSegmentOption(value: 1, label: 'Second'),
              ],
              value: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    final first = tester.getSemantics(find.bySemanticsLabel('First'));
    expect(first, matchesSemantics(isButton: true, hasSelectedState: true, isSelected: true, isInMutuallyExclusiveGroup: true));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, 1);
    final second = tester.getSemantics(find.bySemanticsLabel('Second'));
    expect(second, matchesSemantics(isButton: true, hasSelectedState: true, isSelected: true, isInMutuallyExclusiveGroup: true));
  });

  testWidgets('inline segments expose selection semantics and keyboard activation', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: themeLight,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: UiInlineSegmentRow<int>(
              label: 'Mode',
              options: const [
                UiInlineSegmentOption(value: 0, label: 'First'),
                UiInlineSegmentOption(value: 1, label: 'Second'),
              ],
              value: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, 1);
    expect(tester.getSemantics(find.bySemanticsLabel('Second')), matchesSemantics(isButton: true, hasSelectedState: true, isSelected: true, isInMutuallyExclusiveGroup: true));
  });
}
