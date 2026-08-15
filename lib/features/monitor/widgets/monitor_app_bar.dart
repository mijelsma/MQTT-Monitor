import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/mqtt/connection_status.dart';
import '../../../core/ui/models/search_defaults.dart';
import '../../../generated/l10n.dart';
import '../../../navigation/app_navigation.dart';
import '../../../shared/widgets/app_bar_action_button.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../view_models/monitor_view_model.dart';
import '../controllers/monitor_workspace_controller.dart';
import 'broker_selector.dart';

class MonitorAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MonitorAppBar({super.key, required this.filterController});

  final TextEditingController filterController;

  static const double _toolbarHeight = 68;

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
    final workspace = context.watch<MonitorWorkspaceController>();

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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _SearchBox(controller: widget.filterController, scope: workspace.scope, matchMode: workspace.matchMode, hasText: hasText, onScopeChanged: workspace.setScope, onMatchModeChanged: workspace.setMatchMode),
          ),
          const HSpacer(8),
          _CollapseExpandButton(),
          const HSpacer(4),
          _ClearAllTopicsButton(),
        ],
      ),
      titleSpacing: 14,
      actions: const [BrokerSelector(), HSpacer(8), _ConnectionButton(), HSpacer(4), _DashboardButton(), HSpacer(4), _SettingsButton(), HSpacer(8)],
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({required this.controller, required this.scope, required this.matchMode, required this.hasText, required this.onScopeChanged, required this.onMatchModeChanged});

  final TextEditingController controller;
  final SearchScope scope;
  final SearchMatchMode matchMode;
  final bool hasText;
  final ValueChanged<SearchScope> onScopeChanged;
  final ValueChanged<SearchMatchMode> onMatchModeChanged;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 40,
      decoration: BoxDecoration(
        color: _focused ? tokens.surface : tokens.elevated.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(tokens.controlRadius + 2),
        border: Border.all(color: _focused ? tokens.focusRing.withValues(alpha: 0.65) : tokens.border, width: _focused ? 1.25 : 0.5),
        boxShadow: _focused ? [BoxShadow(color: tokens.focusRing.withValues(alpha: 0.10), blurRadius: 0, spreadRadius: 3)] : const [],
      ),
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: Row(
          children: [
            const SizedBox(width: 11),
            Icon(Icons.search_rounded, size: 17, color: _focused ? tokens.primary : tokens.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
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
            if (widget.hasText) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.controller.clear,
                child: Icon(Icons.cancel_rounded, size: 14, color: tokens.textTertiary),
              ),
            ],
            const SizedBox(width: 6),
            Container(width: 0.5, height: 18, color: tokens.border),
            _MatchModePicker(mode: widget.matchMode, onChanged: widget.onMatchModeChanged),
            Container(width: 0.5, height: 18, color: tokens.border),
            _ScopePicker(scope: widget.scope, onChanged: widget.onScopeChanged),
          ],
        ),
      ),
    );
  }
}

class _MatchModePicker extends StatelessWidget {
  const _MatchModePicker({required this.mode, required this.onChanged});

  final SearchMatchMode mode;
  final ValueChanged<SearchMatchMode> onChanged;

  String _label(BuildContext context, SearchMatchMode value) => switch (value) {
    SearchMatchMode.any => S.of(context).searchModeAny,
    SearchMatchMode.all => S.of(context).searchModeAll,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PopupMenuButton<SearchMatchMode>(
      onSelected: onChanged,
      color: tokens.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border, width: 0.5),
      ),
      offset: const Offset(0, 36),
      itemBuilder: (_) => SearchMatchMode.values
          .map(
            (value) => PopupMenuItem<SearchMatchMode>(
              value: value,
              height: 36,
              child: Text(
                _label(context, value),
                style: TextStyle(fontSize: 13, fontWeight: value == mode ? FontWeight.w600 : FontWeight.w400, color: value == mode ? tokens.primary : tokens.textSecondary),
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
              _label(context, mode),
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
    final vm = context.watch<MonitorWorkspaceController>();
    final tokens = context.tokens;
    final anyExpanded = vm.anyExpanded;

    return IconButton(
      onPressed: anyExpanded ? vm.collapseAll : vm.expandAll,
      icon: Icon(anyExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 18, color: tokens.textSecondary),
      tooltip: anyExpanded ? S.of(context).collapseAll : S.of(context).expandAll,
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
    final vm = context.watch<MonitorWorkspaceController>();
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
      onTap: broker == null ? null : () => context.read<AppNavigation>().openDashboard(context, brokerId: broker.id, brokerName: broker.name),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return AppBarActionButton(icon: Icons.tune_rounded, tooltip: S.of(context).settings, onTap: () => context.read<AppNavigation>().openSettings(context));
  }
}
