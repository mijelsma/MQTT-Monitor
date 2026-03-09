import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/app_bar_bottom/app_bar_bottom.dart';
import 'widgets/app_bar_top/app_bar_top.dart';
import 'widgets/empty_states/no_brokers_state.dart';
import 'widgets/empty_states/no_messages_state.dart';
import 'widgets/empty_states/no_subscriptions_state.dart';
import '../../state/app_state.dart';
import '../../state/keys/app_keys.dart';
import '../../state/keys/settings_keys.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateManager>();
    final showStatusBar = state.read(SettingsKeys.showStatusBar);
    final brokers = state.read(SettingsKeys.brokers);

    final activeBrokerId = state.read(AppKeys.activeBrokerId);
    final activeBroker = brokers.isEmpty ? null : brokers.firstWhere((b) => b.id == activeBrokerId, orElse: () => brokers.first);

    Widget body;
    if (brokers.isEmpty) {
      body = const NoBrokersState();
    } else if (activeBroker != null && activeBroker.subscriptions.isEmpty) {
      body = NoSubscriptionsState(broker: activeBroker);
    } else {
      body = const NoMessagesState();
    }

    return Scaffold(appBar: const AppBarTop(), backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: body, bottomNavigationBar: showStatusBar ? const AppBarBottom() : null);
  }
}
