import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/dashboard_layout.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../dashboard_view_model.dart';

/// Dropdown for selecting and managing saved dashboard layouts.
class DashboardSelector extends StatefulWidget {
  const DashboardSelector({super.key, this.onSaveLayout, this.onNewEmpty, this.onEditLayout, this.onManageDashboards, this.onManageVariables});

  final VoidCallback? onSaveLayout;
  final VoidCallback? onNewEmpty;
  final void Function(DashboardLayout layout)? onEditLayout;
  final VoidCallback? onManageDashboards;
  final VoidCallback? onManageVariables;

  @override
  State<DashboardSelector> createState() => _DashboardSelectorState();
}

class _DashboardSelectorState extends State<DashboardSelector> {
  final _menuKey = GlobalKey<PopupMenuButtonState<String>>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final layouts = vm.layouts;
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
              // Hidden popup menu button that we trigger programmatically.
              Positioned.fill(
                child: IgnorePointer(
                  child: PopupMenuButton<String>(
                    key: _menuKey,
                    onSelected: (id) => _onSelected(context, vm, id),
                    offset: const Offset(0, 46),
                    color: tokens.surface,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: tokens.border, width: 0.5),
                    ),
                    itemBuilder: (_) => _buildMenuItems(context, vm, layouts, active),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: active != null ? AppColors.brokerGradientFor(active.colorIndex) : AppColors.dashboardGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, size: 11, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      active?.title ?? 'Dashboard',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface, letterSpacing: -0.1),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.unfold_more_rounded, size: 14, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu items ──────────────────────────────────────────────────────

  static const _kSaveLayout = '__save__';
  static const _kNewEmpty = '__new_empty__';
  static const _kManageDashboards = '__manage_dashboards__';
  static const _kManageVariables = '__manage_variables__';

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context, DashboardViewModel vm, List<DashboardLayout> layouts, DashboardLayout? active) {
    final tokens = context.tokens;
    final items = <PopupMenuEntry<String>>[];

    // Saved layouts.
    for (final layout in layouts) {
      final isActive = layout.id == active?.id;
      items.add(
        PopupMenuItem<String>(
          value: layout.id,
          height: 40,
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.brokerGradientFor(layout.colorIndex), begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bar_chart_rounded, size: 11, color: Colors.white),
              ),
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
        ),
      );
    }

    if (layouts.isNotEmpty) items.add(const PopupMenuDivider(height: 8));

    // Actions.
    items.add(_actionItem(Icons.save_outlined, 'Save as layout…', _kSaveLayout, tokens.textSecondary));
    items.add(_actionItem(Icons.note_add_outlined, 'New empty dashboard', _kNewEmpty, tokens.textSecondary));
    items.add(const PopupMenuDivider(height: 8));
    items.add(_actionItem(Icons.dashboard_customize_outlined, 'Manage dashboards…', _kManageDashboards, tokens.textSecondary));
    items.add(_actionItem(Icons.data_object_rounded, 'Manage variables…', _kManageVariables, tokens.textSecondary));

    return items;
  }

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

  // ── Selection handler ───────────────────────────────────────────────

  void _onSelected(BuildContext context, DashboardViewModel vm, String id) {
    switch (id) {
      case _kSaveLayout:
        widget.onSaveLayout?.call();
      case _kNewEmpty:
        widget.onNewEmpty?.call();
      case _kManageDashboards:
        widget.onManageDashboards?.call();
      case _kManageVariables:
        widget.onManageVariables?.call();
      default:
        // It's a layout id — check if we should edit or select.
        final layout = vm.layouts.where((l) => l.id == id).firstOrNull;
        if (layout != null && layout.id == vm.activeLayoutId) {
          widget.onEditLayout?.call(layout);
        } else {
          vm.selectLayout(id);
        }
    }
  }
}
