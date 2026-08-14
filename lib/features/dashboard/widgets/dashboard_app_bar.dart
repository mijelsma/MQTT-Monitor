import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../core/dashboard/models/dashboard_layout_model.dart';
import '../../../shared/widgets/app_bar_action_button.dart';
import '../../../shared/widgets/spacers.dart';
import 'dashboard_selector.dart';

/// App bar shown on the dashboard screen.
///
/// Contains a back button, the [DashboardSelector] dropdown,
/// and a settings shortcut.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key, this.onSaveLayout, this.onUpdateLayout, this.onDiscardChanges, this.onNewEmpty, this.onEditLayout, this.onManageDashboards, this.onManageVariables, this.onEraseHistory, this.onOpenSettings});

  final VoidCallback? onSaveLayout;
  final VoidCallback? onUpdateLayout;
  final VoidCallback? onDiscardChanges;
  final VoidCallback? onNewEmpty;
  final void Function(DashboardLayoutModel layout)? onEditLayout;
  final VoidCallback? onManageDashboards;
  final VoidCallback? onManageVariables;
  final VoidCallback? onEraseHistory;
  final VoidCallback? onOpenSettings;

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
        DashboardSelector(onSaveLayout: onSaveLayout, onUpdateLayout: onUpdateLayout, onDiscardChanges: onDiscardChanges, onNewEmpty: onNewEmpty, onEditLayout: onEditLayout, onManageDashboards: onManageDashboards, onManageVariables: onManageVariables),
        const HSpacer(8),
        AppBarActionButton(icon: Icons.delete_sweep_rounded, tooltip: S.of(context).dashboardEraseHistory, onTap: onEraseHistory),
        const HSpacer(8),
        AppBarActionButton(icon: Icons.tune_rounded, tooltip: S.of(context).settings, onTap: onOpenSettings),
        const HSpacer(8),
      ],
    );
  }
}
