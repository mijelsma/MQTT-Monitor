import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/app_bar_bottom/app_bar_bottom.dart';
import 'widgets/app_bar_top/app_bar_top.dart';
import 'widgets/empty_states/no_brokers_state.dart';
import 'widgets/empty_states/no_subscriptions_state.dart';
import 'widgets/topic_tree/topic_tree_controller.dart';
import 'widgets/topic_tree/topic_tree_widget.dart';
import '../../state/app_state.dart';
import '../../state/keys/app_keys.dart';
import '../../state/keys/settings_keys.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _filterController = TextEditingController();
  late final TopicTreeController _treeController;
  SearchScope _scope = SearchScope.all;

  @override
  void initState() {
    super.initState();
    _treeController = TopicTreeController();
    _filterController.addListener(() => _treeController.setFilter(_filterController.text));
  }

  void _onScopeChanged(SearchScope s) {
    setState(() => _scope = s);
    _treeController.setScope(s);
  }

  @override
  void dispose() {
    _filterController.dispose();
    _treeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateManager>();
    final showStatusBar = state.read(SettingsKeys.showStatusBar);
    final brokers = state.read(SettingsKeys.brokers);

    final activeBrokerId = state.read(AppKeys.activeBrokerId);
    final activeBroker = brokers.isEmpty ? null : brokers.firstWhere((b) => b.id == activeBrokerId, orElse: () => brokers.first);

    final connectionStatus = state.read(AppKeys.connectionStatus);
    final connectionError = state.read(AppKeys.connectionError);

    Widget body;
    if (brokers.isEmpty) {
      body = const NoBrokersState();
    } else if (activeBroker != null && activeBroker.subscriptions.isEmpty) {
      body = NoSubscriptionsState(broker: activeBroker);
    } else {
      body = TopicTreeWidget(controller: _treeController, filterController: _filterController, scope: _scope);
    }

    Widget? bottomBar;
    if (showStatusBar) {
      bottomBar = AppBarBottom(status: connectionStatus, brokerUrl: activeBroker?.displayAddress, errorDetail: connectionError, messageCount: state.read(AppKeys.messageCount), messageRate: state.read(AppKeys.messageRate));
    }

    return Scaffold(
      appBar: AppBarTop(filterController: _filterController, scope: _scope, onScopeChanged: _onScopeChanged),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}
