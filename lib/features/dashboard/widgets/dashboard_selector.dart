import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/dashboard_layout.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../dashboard_view_model.dart';

/// Dropdown button for selecting and managing saved dashboard layouts.
///
/// Wraps a hidden [PopupMenuButton] that is triggered programmatically
/// so the entire visible area acts as the tap target.
class DashboardSelector extends StatefulWidget {
  const DashboardSelector({super.key, this.onSaveLayout, this.onUpdateLayout, this.onDiscardChanges, this.onNewEmpty, this.onEditLayout, this.onManageDashboards, this.onManageVariables});

  final VoidCallback? onSaveLayout;
  final VoidCallback? onUpdateLayout;
  final VoidCallback? onDiscardChanges;
  final VoidCallback? onNewEmpty;
  final void Function(DashboardLayout layout)? onEditLayout;
  final VoidCallback? onManageDashboards;
  final VoidCallback? onManageVariables;

  @override
  State<DashboardSelector> createState() => _DashboardSelectorState();
}

class _DashboardSelectorState extends State<DashboardSelector> {
  final _menuKey = GlobalKey<PopupMenuButtonState<String>>();

  // Menu item identifiers for action entries (non-layout items).
  static const _kSaveLayout = '__save__';
  static const _kUpdateLayout = '__update__';
  static const _kDiscardChanges = '__discard__';
  static const _kNewEmpty = '__new_empty__';
  static const _kManageDashboards = '__manage_dashboards__';
  static const _kManageVariables = '__manage_variables__';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final active = vm.activeLayout;

    const borderRadius = BorderRadius.all(Radius.circular(8));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: cs.surface,
        child: InkWell(
          onTap: () => _menuKey.currentState?.showButtonMenu(),
          child: Stack(
            children: [
              // Visible button content.
              _buildSelector(active, vm, cs, borderRadius),
              // Hidden popup menu — triggered by the InkWell tap above.
              _buildPopupMenu(vm, tokens),
            ],
          ),
        ),
      ),
    );
  }

  /// The visible chip that shows the active layout name and status.
  Widget _buildSelector(DashboardLayout? active, DashboardViewModel vm, ColorScheme cs, BorderRadius borderRadius) {
    final hasActive = active != null;
    final gradient = hasActive ? AppColors.brokerGradientFor(active.colorIndex) : AppColors.dashboardGradient;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color swatch icon
          _GradientIcon(gradient: gradient, size: 18, borderRadius: 5),
          const SizedBox(width: 8),

          // Layout title
          Text(
            active?.title ?? 'No layout selected',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: hasActive ? cs.onSurface : cs.onSurfaceVariant, letterSpacing: -0.1, fontStyle: hasActive ? FontStyle.normal : FontStyle.italic),
          ),

          // Unsaved-changes indicator dot
          if (vm.hasUnsavedChanges) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: context.tokens.warning, shape: BoxShape.circle),
            ),
          ],

          const SizedBox(width: 3),
          Icon(Icons.unfold_more_rounded, size: 14, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  /// The invisible [PopupMenuButton] that powers the dropdown menu.
  Widget _buildPopupMenu(DashboardViewModel vm, AppTokens tokens) {
    return Positioned.fill(
      child: IgnorePointer(
        child: PopupMenuButton<String>(
          key: _menuKey,
          onSelected: (id) => _onSelected(vm, id),
          offset: const Offset(0, 46),
          color: tokens.surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: tokens.border, width: 0.5),
          ),
          itemBuilder: (_) => _buildMenuItems(vm, tokens),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// Builds all popup menu entries: saved layouts + action items.
  List<PopupMenuEntry<String>> _buildMenuItems(DashboardViewModel vm, AppTokens tokens) {
    final layouts = vm.layouts;
    final active = vm.activeLayout;
    final items = <PopupMenuEntry<String>>[];

    // — Saved layouts —
    for (final layout in layouts) {
      final isActive = layout.id == active?.id;
      items.add(_layoutItem(layout, isActive, tokens));
    }

    if (layouts.isNotEmpty) items.add(const PopupMenuDivider(height: 8));

    // — Action items —
    final actionColor = tokens.textSecondary;
    if (active != null) {
      items.add(_actionItem(Icons.save_rounded, 'Save "${active.title}"', _kUpdateLayout, actionColor));
      if (vm.hasUnsavedChanges) {
        items.add(_actionItem(Icons.undo_rounded, 'Discard changes', _kDiscardChanges, actionColor));
      }
    }
    items.add(_actionItem(Icons.save_outlined, 'Save as new layout…', _kSaveLayout, actionColor));
    items.add(_actionItem(Icons.note_add_outlined, 'New empty dashboard', _kNewEmpty, actionColor));
    items.add(const PopupMenuDivider(height: 8));
    items.add(_actionItem(Icons.dashboard_customize_outlined, 'Manage dashboards…', _kManageDashboards, actionColor));
    items.add(_actionItem(Icons.data_object_rounded, 'Manage variables…', _kManageVariables, actionColor));

    return items;
  }

  /// A single saved-layout row inside the popup menu.
  PopupMenuItem<String> _layoutItem(DashboardLayout layout, bool isActive, AppTokens tokens) {
    return PopupMenuItem<String>(
      value: layout.id,
      height: 40,
      child: Row(
        children: [
          _GradientIcon(gradient: AppColors.brokerGradientFor(layout.colorIndex), size: 22, borderRadius: 6),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              layout.title,
              style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? tokens.primary : tokens.textPrimary),
            ),
          ),
          if (isActive) Icon(Icons.check_rounded, size: 14, color: tokens.primary),
        ],
      ),
    );
  }

  /// A generic action row (save, new, manage, etc.) inside the popup menu.
  PopupMenuItem<String> _actionItem(IconData icon, String label, String value, Color color) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  /// Called when the user picks an item from the popup menu.
  void _onSelected(DashboardViewModel vm, String id) {
    switch (id) {
      case _kSaveLayout:
        widget.onSaveLayout?.call();
      case _kUpdateLayout:
        widget.onUpdateLayout?.call();
      case _kDiscardChanges:
        widget.onDiscardChanges?.call();
      case _kNewEmpty:
        widget.onNewEmpty?.call();
      case _kManageDashboards:
        widget.onManageDashboards?.call();
      case _kManageVariables:
        widget.onManageVariables?.call();
      default:
        // Tapped a layout — edit it if already active, otherwise select it.
        final layout = vm.layouts.where((l) => l.id == id).firstOrNull;
        if (layout != null && layout.id == vm.activeLayoutId) {
          widget.onEditLayout?.call(layout);
        } else {
          vm.selectLayout(id);
        }
    }
  }
}

/// A tiny square with a gradient background and a bar-chart icon.
/// Used for the color swatch next to layout names.
class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.gradient, required this.size, required this.borderRadius});

  final List<Color> gradient;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.bar_chart_rounded, size: size * 0.6, color: Colors.white),
    );
  }
}
