import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_controller.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_divider.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_layout.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_section.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';

void main() {
  Widget buildLayout(
    WorkspacePanelController controller, {
    double height = 500,
    bool animationsEnabled = false,
  }) {
    const titles = ['Alpha', 'Beta', 'Gamma', 'Delta'];
    assert(controller.length <= titles.length);
    return MaterialApp(
      theme: themeLight,
      home: Scaffold(
        body: SizedBox(
          width: 500,
          height: height,
          child: WorkspacePanelLayout(
            controller: controller,
            animationsEnabled: animationsEnabled,
            animationDuration: const Duration(milliseconds: 400),
            dividerSemanticLabelBuilder: (first, second) =>
                'Resize ${titles[first]} and ${titles[second]}',
            sections: [
              for (var index = 0; index < controller.length; index++)
                WorkspacePanelSection(
                  title: titles[index],
                  icon: Icons.crop_square,
                  body: _StatefulBody(
                    key: Key('${titles[index].toLowerCase()}-body'),
                  ),
                  toggleKey: Key('${titles[index].toLowerCase()}-toggle'),
                  contentKey: Key('${titles[index].toLowerCase()}-content'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  test('controller supports all-collapsed state and bounded resizing', () {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, false],
    );
    addTearDown(controller.dispose);

    controller.resizePair(0, 1, 100);
    expect(controller.shares[0], closeTo(0.85, 0.0001));
    expect(controller.shares[1], closeTo(0.15, 0.0001));

    controller.toggle(0);
    controller.toggle(1);
    expect(controller.shares, [0, 0]);

    controller.toggle(0);
    expect(controller.shares, [1, 0]);
  });

  testWidgets('header exposes semantics and toggles with the keyboard', (
    tester,
  ) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, false],
    );
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildLayout(controller));

    final alphaSemantics = tester.getSemantics(
      find.byKey(const Key('alpha-toggle')),
    );
    expect(alphaSemantics.label, 'Alpha');
    expect(
      alphaSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(alphaSemantics.getSemanticsData().flagsCollection.isButton, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.isCollapsed(0), isTrue);
    expect(tester.getSize(find.byKey(const Key('alpha-content'))).height, 0);
    semantics.dispose();
  });

  testWidgets('divider resizes by drag and keyboard', (tester) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, false],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildLayout(controller));

    final divider = find.byKey(const Key('workspace-panel-divider-0-1'));
    final initialShare = controller.shares[0];
    await tester.drag(divider, const Offset(0, 50));
    await tester.pump();
    expect(controller.shares[0], greaterThan(initialShare));

    await tester.tap(divider);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(controller.shares[0], lessThan(0.7));
  });

  testWidgets('divider pairs match consecutive expanded panels in all states', (
    tester,
  ) async {
    for (var collapsedMask = 0; collapsedMask < 16; collapsedMask++) {
      final collapsed = [
        for (var index = 0; index < 4; index++)
          collapsedMask & (1 << index) != 0,
      ];
      final controller = WorkspacePanelController(initialCollapsed: collapsed);
      await tester.pumpWidget(buildLayout(controller));

      final expanded = [
        for (var index = 0; index < 4; index++)
          if (!collapsed[index]) index,
      ];
      final expectedPairs = [
        for (var position = 0; position < expanded.length - 1; position++)
          '${expanded[position]}-${expanded[position + 1]}',
      ];
      expect(
        find.byType(WorkspacePanelDivider),
        findsNWidgets(expectedPairs.length),
        reason: 'Unexpected divider count for collapsed state $collapsed.',
      );
      for (final pair in expectedPairs) {
        expect(
          find.byKey(Key('workspace-panel-divider-$pair')),
          findsOneWidget,
          reason: 'Missing divider $pair for collapsed state $collapsed.',
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets('non-adjacent drag changes only its expanded panel pair', (
    tester,
  ) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, true, false, false],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildLayout(controller));

    final pairTotal = controller.ratioAt(0) + controller.ratioAt(2);
    final unaffectedRatio = controller.ratioAt(3);
    await tester.drag(
      find.byKey(const Key('workspace-panel-divider-0-2')),
      const Offset(0, 50),
    );
    await tester.pump();

    expect(controller.ratioAt(0), greaterThan(1));
    expect(controller.ratioAt(2), lessThan(1));
    expect(
      controller.ratioAt(0) + controller.ratioAt(2),
      closeTo(pairTotal, 0.0001),
    );
    expect(controller.ratioAt(3), unaffectedRatio);
    expect(controller.shares[1], 0);
  });

  testWidgets('non-adjacent drag works across two-panel collapse patterns', (
    tester,
  ) async {
    final cases = <({List<bool> collapsed, int first, int second})>[
      (collapsed: [false, true, false, true], first: 0, second: 2),
      (collapsed: [false, true, true, false], first: 0, second: 3),
      (collapsed: [true, false, true, false], first: 1, second: 3),
    ];

    for (final testCase in cases) {
      final controller = WorkspacePanelController(
        initialCollapsed: testCase.collapsed,
      );
      await tester.pumpWidget(buildLayout(controller));
      final beforeFirst = controller.shares[testCase.first];
      final beforeSecond = controller.shares[testCase.second];

      await tester.drag(
        find.byKey(
          Key('workspace-panel-divider-${testCase.first}-${testCase.second}'),
        ),
        const Offset(0, 50),
      );
      await tester.pump();

      expect(controller.shares[testCase.first], greaterThan(beforeFirst));
      expect(controller.shares[testCase.second], lessThan(beforeSecond));
      for (var index = 0; index < testCase.collapsed.length; index++) {
        if (testCase.collapsed[index]) expect(controller.shares[index], 0);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets('non-adjacent divider keyboard and semantics use actual pair', (
    tester,
  ) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, true, false, true],
    );
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildLayout(controller));

    final divider = find.byKey(const Key('workspace-panel-divider-0-2'));
    final dividerSemantics = tester.getSemantics(divider).getSemanticsData();
    expect(dividerSemantics.label, 'Resize Alpha and Gamma');
    expect(dividerSemantics.flagsCollection.isSlider, isTrue);

    await tester.tap(divider);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(controller.shares[0], greaterThan(0.5));
    expect(controller.shares[1], 0);
    expect(controller.shares[3], 0);
    semantics.dispose();
  });

  testWidgets('animated collapse retargets dividers to expanded neighbors', (
    tester,
  ) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, false, false, false],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildLayout(controller, animationsEnabled: true));

    controller.toggle(1);
    await tester.pump();
    expect(
      find.byKey(const Key('workspace-panel-divider-0-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('workspace-panel-divider-2-3')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('workspace-panel-divider-0-1')), findsNothing);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('small height supports a non-adjacent expanded pair', (
    tester,
  ) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, true, false, true],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildLayout(controller, height: 100));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      find.byKey(const Key('workspace-panel-divider-0-2')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed body remains mounted and preserves local state', (
    tester,
  ) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, false],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildLayout(controller));

    await tester.tap(find.byKey(const Key('increment-alpha-body')));
    await tester.pump();
    expect(find.text('alpha-body: 1'), findsOneWidget);

    controller.toggle(0);
    await tester.pump();
    expect(find.byKey(const Key('alpha-body')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('alpha-content'))).height, 0);

    controller.toggle(0);
    await tester.pump();
    expect(find.text('alpha-body: 1'), findsOneWidget);
  });

  testWidgets('all-collapsed and small-height layouts do not overflow', (
    tester,
  ) async {
    final controller = WorkspacePanelController(initialCollapsed: [true, true]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildLayout(controller, height: 50));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid animated changes stay local and within a padded budget', (
    tester,
  ) async {
    final controller = WorkspacePanelController(
      initialCollapsed: [false, false],
    );
    addTearDown(controller.dispose);
    var ownerBuilds = 0;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          ownerBuilds++;
          return buildLayout(controller, animationsEnabled: true);
        },
      ),
    );

    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < 100; iteration++) {
      controller.toggle(0);
      await tester.pump(const Duration(milliseconds: 8));
    }
    stopwatch.stop();
    debugPrint(
      'Workspace panel animation guard: 100 rapid targets in '
      '${stopwatch.elapsedMicroseconds} us (budget 2000000 us)',
    );

    expect(ownerBuilds, 1);
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason: '100 rapid animated targets took ${stopwatch.elapsed}.',
    );
    expect(tester.takeException(), isNull);
  });
}

class _StatefulBody extends StatefulWidget {
  const _StatefulBody({super.key});

  @override
  State<_StatefulBody> createState() => _StatefulBodyState();
}

class _StatefulBodyState extends State<_StatefulBody> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    final label = (widget.key! as ValueKey<String>).value;
    return Align(
      alignment: Alignment.topLeft,
      child: TextButton(
        key: Key('increment-$label'),
        onPressed: () => setState(() => _count++),
        child: Text('$label: $_count'),
      ),
    );
  }
}
