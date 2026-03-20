import 'package:flutter/material.dart';

import '../../../models/dashboard_layout.dart';
import '../../../shared/widgets/app_bar_action_button.dart';
import '../../../shared/widgets/spacers.dart';
import '../../settings/settings_screen.dart';
import 'dashboard_selector.dart';

/// App bar shown on the dashboard screen.
///
/// Contains a back button, the [DashboardSelector] dropdown,
/// and a settings shortcut.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key, this.onSaveLayout, this.onUpdateLayout, this.onNewEmpty, this.onEditLayout, this.onManageDashboards, this.onManageVariables});

  final VoidCallback? onSaveLayout;
  final VoidCallback? onUpdateLayout;
  final VoidCallback? onNewEmpty;
  final void Function(DashboardLayout layout)? onEditLayout;
  final VoidCallback? onManageDashboards;
  final VoidCallback? onManageVariables;

  static const _toolbarHeight = 62.0;

  // Extra 0.5 accounts for the bottom divider line.
  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight + 0.5);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _toolbarHeight,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Theme.of(context).dividerColor),
      ),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(context).pop()),
      actions: [
        DashboardSelector(onSaveLayout: onSaveLayout, onUpdateLayout: onUpdateLayout, onNewEmpty: onNewEmpty, onEditLayout: onEditLayout, onManageDashboards: onManageDashboards, onManageVariables: onManageVariables),
        const HSpacer(8),
        const _SettingsButton(),
        const HSpacer(8),
      ],
    );
  }
}

/// Opens the [SettingsScreen] when tapped.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return AppBarActionButton(
      icon: Icons.tune_rounded,
      tooltip: 'Settings',
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
    );
  }
}
