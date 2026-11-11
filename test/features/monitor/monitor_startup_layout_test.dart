import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/history/services/message_history_service.dart';
import 'package:mqtt_monitor/core/ingestion/message_ingestion_coordinator.dart';
import 'package:mqtt_monitor/core/monitor/topic_projection.dart';
import 'package:mqtt_monitor/features/monitor/controllers/monitor_workspace_controller.dart';
import 'package:mqtt_monitor/features/monitor/controllers/publish_draft_controller.dart';
import 'package:mqtt_monitor/features/monitor/view_models/monitor_view_model.dart';
import 'package:mqtt_monitor/features/monitor/widgets/monitor_app_bar.dart';
import 'package:mqtt_monitor/features/monitor/widgets/publish_panel.dart';
import 'package:mqtt_monitor/generated/l10n.dart';
import 'package:mqtt_monitor/navigation/app_navigation.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/test_dependencies.dart';

void main() {
  testWidgets('monitor toolbar fits the initial 800 pixel window', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 632);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final fixture = await _MonitorFixture.create();
    addTearDown(fixture.dispose);

    final filterController = TextEditingController();
    addTearDown(filterController.dispose);

    await tester.pumpWidget(
      fixture.wrap(
        Scaffold(
          appBar: MonitorAppBar(filterController: filterController),
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('publish controls scroll instead of overflowing a short panel', (
    tester,
  ) async {
    final fixture = await _MonitorFixture.create();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      fixture.wrap(
        const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 400, height: 100, child: PublishPanel()),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollView = find.descendant(
      of: find.byType(PublishPanel),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollView, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MonitorFixture {
  _MonitorFixture({
    required this.dependencies,
    required this.ingestion,
    required this.projection,
    required this.history,
    required this.viewModel,
    required this.workspace,
    required this.draft,
  });

  final TestDependencies dependencies;
  final MessageIngestionCoordinator ingestion;
  final TopicProjection projection;
  final MessageHistoryService history;
  final MonitorViewModel viewModel;
  final MonitorWorkspaceController workspace;
  final PublishDraftController draft;

  static Future<_MonitorFixture> create() async {
    final dependencies = await TestDependencies.create();
    await dependencies.brokers.add(
      const BrokerEntryModel(
        id: 'facility',
        name: 'LTT - Facility',
        host: 'broker.invalid',
      ),
    );

    final ingestion = MessageIngestionCoordinator(
      dependencies.mqttSession,
      dependencies.brokers,
    );
    final projection = TopicProjection(ingestion, dependencies.brokers);
    final history = MessageHistoryService(
      ingestion,
      dependencies.historyPreferences,
      dependencies.brokers,
    );
    final viewModel = MonitorViewModel(
      mqttSession: dependencies.mqttSession,
      uiPreferences: dependencies.uiPreferences,
      brokerRepository: dependencies.brokers,
      shortcutRepository: dependencies.shortcuts,
      variableRepository: dependencies.variables,
      publisher: dependencies.publisher,
      templateResolver: dependencies.templateResolver,
    );
    final workspace = MonitorWorkspaceController(
      projection: projection,
      history: history,
      uiPreferences: dependencies.uiPreferences,
    );
    final draft = PublishDraftController();
    return _MonitorFixture(
      dependencies: dependencies,
      ingestion: ingestion,
      projection: projection,
      history: history,
      viewModel: viewModel,
      workspace: workspace,
      draft: draft,
    );
  }

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MonitorViewModel>.value(value: viewModel),
        ChangeNotifierProvider<MonitorWorkspaceController>.value(
          value: workspace,
        ),
        ChangeNotifierProvider<PublishDraftController>.value(value: draft),
        Provider<AppNavigation>.value(value: dependencies.navigation),
      ],
      child: MaterialApp(
        theme: themeDark,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> dispose() async {
    draft.dispose();
    workspace.dispose();
    viewModel.dispose();
    projection.dispose();
    await history.dispose();
    await ingestion.dispose();
    dependencies.mqttSession.dispose();
  }
}
