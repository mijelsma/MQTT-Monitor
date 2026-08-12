import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_controller.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_layout.dart';
import 'package:mqtt_monitor/shared/widgets/workspace_panel_section.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';

void main() {
  Widget buildLayout(
    WorkspacePanelController controller, {
    double height = 500,
    bool animationsEnabled = false,
  }) {
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
            sections: const [
              WorkspacePanelSection(
                title: 'Alpha',
                icon: Icons.looks_one,
                body: _StatefulBody(key: Key('alpha-body')),
                toggleKey: Key('alpha-toggle'),
                contentKey: Key('alpha-content'),
                dividerSemanticLabel: 'Resize Alpha and Beta',
              ),
              WorkspacePanelSection(
                title: 'Beta',
                icon: Icons.looks_two,
                body: _StatefulBody(key: Key('beta-body')),
                toggleKey: Key('beta-toggle'),
                contentKey: Key('beta-content'),
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

    final divider = find.byKey(const Key('workspace-panel-divider-0'));
    final initialShare = controller.shares[0];
    await tester.drag(divider, const Offset(0, 50));
    await tester.pump();
    expect(controller.shares[0], greaterThan(initialShare));

    await tester.tap(divider);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(controller.shares[0], lessThan(0.7));
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
