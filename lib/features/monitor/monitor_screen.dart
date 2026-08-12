import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/broker/broker_repository.dart';
import '../../core/history/message_history_service.dart';
import '../../core/monitor/topic_projection.dart';
import '../../core/mqtt/session/mqtt_session_controller.dart';
import '../../core/publishing/publish_command_service.dart';
import '../../core/publishing/json_payload_validator.dart';
import '../../core/publishing/qos_preferences_repository.dart';
import '../../core/publishing/shortcut_repository.dart';
import '../../core/publishing/template_resolver.dart';
import '../../core/publishing/variable_repository.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../core/state/keys/layout_keys.dart';
import '../../core/update/app_update_service.dart';
import '../../core/ui/ui_preferences_repository.dart';
import '../../shared/widgets/resizable_split.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_section.dart';
import 'monitor_viewmodel.dart';
import 'detail_sidebar_controller.dart';
import 'monitor_workspace_controller.dart';
import 'publish_draft_controller.dart';
import 'widgets/broker_load_failure_state.dart';
import 'widgets/connection_notice.dart';
import 'widgets/detail_sidebar.dart';
import 'widgets/monitor_app_bar.dart';
import 'widgets/no_brokers_state.dart';
import 'widgets/no_subscriptions_state.dart';
import 'widgets/status_bar.dart';
import 'widgets/topic_tree.dart';

/// Creates the monitor workspace and its broker-aware feature controllers.
class MonitorScreen extends StatelessWidget {
  /// Creates the monitor screen.
  const MonitorScreen({super.key});

  /// Builds the providers and monitor workspace.
  @override
  Widget build(BuildContext context) {
    final qosPreferences = context.read<QosPreferencesRepository>();
    final initialPublishQos = qosPreferences.resolve(qosPreferences.defaultPublish);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => MonitorViewModel(
            mqttSession: ctx.read<MqttSessionController>(),
            uiPreferences: ctx.read<UiPreferencesRepository>(),
            brokerRepository: ctx.read<BrokerRepository>(),
            shortcutRepository: ctx.read<ShortcutRepository>(),
            variableRepository: ctx.read<VariableRepository>(),
            publisher: ctx.read<PublishCommandService>(),
            templateResolver: ctx.read<TemplateResolver>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => MonitorWorkspaceController(projection: ctx.read<TopicProjection>(), history: ctx.read<MessageHistoryService>(), uiPreferences: ctx.read<UiPreferencesRepository>()),
        ),
        ChangeNotifierProvider(create: (ctx) => DetailSidebarController(ctx.read<AppStateManager>(), ctx.read<UiPreferencesRepository>())),
        ChangeNotifierProvider(
          create: (ctx) => PublishDraftController(
            initialQos: initialPublishQos,
            jsonValidator: ctx.read<JsonPayloadValidator>(),
            onQosChanged: (qos) {
              // Record the pick so any "last used" default strategy
              // resolves to it next time.
              qosPreferences.record(qos);
            },
          ),
        ),
      ],
      child: const _MonitorView(),
    );
  }
}

class _MonitorView extends StatefulWidget {
  const _MonitorView();

  @override
  State<_MonitorView> createState() => _MonitorViewState();
}

/// Renders monitor content and persistence failure states.
class _MonitorViewState extends State<_MonitorView> {
  final TextEditingController _filterController = TextEditingController();
  late double _splitRatio;

  @override
  void initState() {
    super.initState();
    _splitRatio = context.read<AppStateManager>().read(LayoutKeys.monitorSplitRatio);
    _filterController.addListener(() {
      context.read<MonitorWorkspaceController>().setFilter(_filterController.text);
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  /// Builds the topic workspace or the applicable recoverable empty state.
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();

    // Determine what the main content area should show.
    final bool showTree;
    Widget? emptyState;
    if (vm.brokerFailure != null) {
      showTree = false;
      emptyState = BrokerLoadFailureState(failure: vm.brokerFailure!, onRetry: vm.retryBrokerLoad);
    } else if (vm.brokers.isEmpty) {
      showTree = false;
      emptyState = const NoBrokersState();
    } else if (vm.activeBroker != null && vm.activeBroker!.subscriptions.isEmpty) {
      showTree = false;
      emptyState = NoSubscriptionsState(broker: vm.activeBroker!);
    } else {
      showTree = true;
    }

    Widget mainContent;
    if (!showTree) {
      mainContent = emptyState!;
    } else {
      mainContent = ResizableSplit(
        initialRatio: _splitRatio,
        minRatio: 0.25,
        maxRatio: 0.75,
        minSecondSize: 350,
        onRatioUpdate: (ratio) => setState(() => _splitRatio = ratio),
        onRatioChanged: (ratio) => context.read<AppStateManager>().write(LayoutKeys.monitorSplitRatio, ratio),
        first: TopicTree(filterController: _filterController),
        second: const DetailSidebar(),
      );
    }

    final updateAvailable = context.select<AppUpdateService, bool>((updater) => updater.state is UpdateAvailable);

    Widget? bottomBar;
    if (vm.showStatusBar) {
      bottomBar = StatusBar(status: vm.connectionStatus, brokerUrl: vm.activeBroker?.displayAddress, messageCount: vm.messageCount, messageRate: vm.messageRate, activeProtocol: vm.activeProtocol, showUpdateAvailable: updateAvailable, onUpdateAvailable: () => _openSettings(context, SettingsSection.about));
    }

    return Scaffold(
      appBar: MonitorAppBar(filterController: _filterController),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Match the left panel width: (total - divider hit area) * ratio.
          const dividerHitArea = 14.0;
          final noticeWidth = showTree ? (constraints.maxWidth - dividerHitArea) * _splitRatio : constraints.maxWidth;
          return Stack(
            children: [
              Positioned.fill(child: mainContent),
              Positioned(top: 0, left: 0, width: noticeWidth.clamp(0, constraints.maxWidth), child: const ConnectionNotice()),
            ],
          );
        },
      ),
      bottomNavigationBar: bottomBar,
    );
  }

  void _openSettings(BuildContext context, SettingsSection section) {
    context.read<AppStateManager>().write(AppKeys.activeSettingsSection, section);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}
