import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/mqtt/mqtt_service.dart';
import '../../core/state/app_state.dart';
import 'monitor_viewmodel.dart';
import 'widgets/monitor_app_bar.dart';
import 'widgets/no_brokers_state.dart';
import 'widgets/no_subscriptions_state.dart';
import 'widgets/status_bar.dart';
import 'widgets/topic_tree.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => MonitorViewModel(mqttService: ctx.read<MqttService>(), state: ctx.read<AppStateManager>()),
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

  @override
  void initState() {
    super.initState();
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

    Widget body;
    if (vm.brokers.isEmpty) {
      body = const NoBrokersState();
    } else if (vm.activeBroker != null && vm.activeBroker!.subscriptions.isEmpty) {
      body = NoSubscriptionsState(broker: vm.activeBroker!);
    } else {
      body = TopicTree(filterController: _filterController);
    }

    Widget? bottomBar;
    if (vm.showStatusBar) {
      bottomBar = StatusBar(status: vm.connectionStatus, brokerUrl: vm.activeBroker?.displayAddress, errorDetail: vm.connectionError, messageCount: vm.messageCount, messageRate: vm.messageRate);
    }

    return Scaffold(
      appBar: MonitorAppBar(filterController: _filterController, scope: vm.scope, onScopeChanged: _onScopeChanged),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}
