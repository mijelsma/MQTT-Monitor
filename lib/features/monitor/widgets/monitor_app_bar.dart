import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/mqtt/connection_status.dart';
import '../../../generated/l10n.dart';
import '../../../shared/widgets/app_bar_action_button.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../settings/settings_screen.dart';
import '../monitor_viewmodel.dart';
import 'broker_selector.dart';

class MonitorAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MonitorAppBar({super.key, required this.filterController, required this.scope, required this.onScopeChanged});

  final TextEditingController filterController;
  final SearchScope scope;
  final ValueChanged<SearchScope> onScopeChanged;

  static const double _toolbarHeight = 62;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight + 0.5);

  @override
  State<MonitorAppBar> createState() => _MonitorAppBarState();
}

class _MonitorAppBarState extends State<MonitorAppBar> {
  @override
  void initState() {
    super.initState();
    widget.filterController.addListener(_onFilterChanged);
  }

  @override
  void didUpdateWidget(MonitorAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterController != widget.filterController) {
      oldWidget.filterController.removeListener(_onFilterChanged);
      widget.filterController.addListener(_onFilterChanged);
    }
  }

  @override
  void dispose() {
    widget.filterController.removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.filterController.text.isNotEmpty;

    return AppBar(
      toolbarHeight: MonitorAppBar._toolbarHeight,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1.0, color: Theme.of(context).dividerColor),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: _SearchBox(controller: widget.filterController, scope: widget.scope, hasText: hasText, onScopeChanged: widget.onScopeChanged),
          ),
          const HSpacer(8),
          _CollapseExpandButton(),
          const HSpacer(4),
          _ClearAllTopicsButton(),
        ],
      ),
      titleSpacing: 10,
      actions: const [BrokerSelector(), HSpacer(8), _ConnectionButton(), HSpacer(4), _DashboardButton(), HSpacer(4), _SettingsButton(), HSpacer(8)],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.scope, required this.hasText, required this.onScopeChanged});

  final TextEditingController controller;
  final SearchScope scope;
  final bool hasText;
  final ValueChanged<SearchScope> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search_rounded, size: 15, color: tokens.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 13, color: tokens.textPrimary, height: 1.0),
              decoration: InputDecoration(
                hintText: '${S.of(context).searchHint}…',
                hintStyle: TextStyle(fontSize: 13, color: tokens.textTertiary, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: tokens.primary,
              cursorWidth: 1.5,
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: controller.clear,
              child: Icon(Icons.cancel_rounded, size: 14, color: tokens.textTertiary),
            ),
          ],
          const SizedBox(width: 6),
          Container(width: 0.5, height: 18, color: tokens.border),
          _ScopePicker(scope: scope, onChanged: onScopeChanged),
        ],
      ),
    );
  }
}

class _ScopePicker extends StatelessWidget {
  const _ScopePicker({required this.scope, required this.onChanged});

  final SearchScope scope;
  final ValueChanged<SearchScope> onChanged;

  String _label(BuildContext context, SearchScope s) => switch (s) {
    SearchScope.all => S.of(context).searchScopeAll,
    SearchScope.topic => S.of(context).searchScopeTopic,
    SearchScope.value => S.of(context).searchScopeValue,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return PopupMenuButton<SearchScope>(
      onSelected: onChanged,
      color: tokens.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border, width: 0.5),
      ),
      offset: const Offset(0, 36),
      itemBuilder: (_) => SearchScope.values
          .map(
            (s) => PopupMenuItem<SearchScope>(
              value: s,
              height: 36,
              child: Text(
                _label(context, s),
                style: TextStyle(fontSize: 13, fontWeight: s == scope ? FontWeight.w600 : FontWeight.w400, color: s == scope ? tokens.primary : tokens.textSecondary),
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label(context, scope),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textSecondary),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _CollapseExpandButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    final tokens = context.tokens;
    final expanded = vm.allExpanded;

    return IconButton(
      onPressed: expanded ? vm.collapseAll : vm.expandAll,
      icon: Icon(expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 18, color: tokens.textSecondary),
      tooltip: expanded ? S.of(context).collapseAll : S.of(context).expandAll,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ClearAllTopicsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    final tokens = context.tokens;

    return IconButton(
      onPressed: vm.clearAllTopics,
      icon: Icon(Icons.delete_sweep_rounded, size: 18, color: tokens.textSecondary),
      tooltip: S.of(context).clearAllTopics,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    if (vm.brokers.isEmpty) return const SizedBox.shrink();

    final (icon, onTap) = switch (vm.connectionStatus) {
      ConnectionStatus.connected || ConnectionStatus.connecting => (Icons.link_off_rounded, vm.disconnect as VoidCallback?),
      _ => (Icons.link_rounded, vm.reconnect as VoidCallback?),
    };

    final tooltip = switch (vm.connectionStatus) {
      ConnectionStatus.connected || ConnectionStatus.connecting => S.of(context).disconnect,
      _ => S.of(context).reconnect,
    };

    return AppBarActionButton(icon: icon, tooltip: tooltip, onTap: onTap);
  }
}

class _DashboardButton extends StatelessWidget {
  const _DashboardButton();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    final broker = vm.activeBroker;

    return AppBarActionButton(
      icon: Icons.bar_chart_rounded,
      tooltip: S.of(context).sectionDashboard,
      onTap: broker == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GraphDashboardScreen(brokerId: broker.id, brokerName: broker.name),
              ),
            ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return AppBarActionButton(
      icon: Icons.tune_rounded,
      tooltip: S.of(context).settings,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
    );
  }
}
