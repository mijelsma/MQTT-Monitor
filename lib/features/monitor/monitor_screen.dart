import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/history/message_history_service.dart';
import '../../core/mqtt/mqtt_service.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/layout_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/mqtt_qos_default.dart';
import '../../shared/widgets/resizable_split.dart';
import 'monitor_viewmodel.dart';
import 'publish_draft_controller.dart';
import 'widgets/connection_notice.dart';
import 'widgets/detail_sidebar.dart';
import 'widgets/monitor_app_bar.dart';
import 'widgets/no_brokers_state.dart';
import 'widgets/no_subscriptions_state.dart';
import 'widgets/status_bar.dart';
import 'widgets/topic_tree.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppStateManager>();
    state.load(SettingsKeys.defaultPublishQos);
    state.load(SettingsKeys.lastUsedQos);
    final initialPublishQos = state.read<MqttQosDefault>(SettingsKeys.defaultPublishQos).resolve(state.read(SettingsKeys.lastUsedQos));
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => MonitorViewModel(mqttService: ctx.read<MqttService>(), state: ctx.read<AppStateManager>(), historyService: ctx.read<MessageHistoryService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => PublishDraftController(
            initialQos: initialPublishQos,
            onQosChanged: (qos) {
              // Record the pick so any "last used" default strategy
              // resolves to it next time.
              state.write(SettingsKeys.lastUsedQos, qos);
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

class _MonitorViewState extends State<_MonitorView> {
  final TextEditingController _filterController = TextEditingController();
  late double _splitRatio;

  @override
  void initState() {
    super.initState();
    _splitRatio = context.read<AppStateManager>().read(LayoutKeys.monitorSplitRatio);
    _filterController.addListener(() {
      context.read<MonitorViewModel>().setFilter(_filterController.text);
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _onScopeChanged(SearchScope s) {
    context.read<MonitorViewModel>().setScope(s);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();

    // Determine what the main content area should show.
    final bool showTree;
    Widget? emptyState;
    if (vm.brokers.isEmpty) {
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

    Widget? bottomBar;
    if (vm.showStatusBar) {
      bottomBar = StatusBar(status: vm.connectionStatus, brokerUrl: vm.activeBroker?.displayAddress, messageCount: vm.messageCount, messageRate: vm.messageRate, activeProtocol: vm.activeProtocol);
    }

    return Scaffold(
      appBar: MonitorAppBar(filterController: _filterController, scope: vm.scope, onScopeChanged: _onScopeChanged),
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
}
