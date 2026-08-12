import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../models/dashboard_layout.dart';
import '../../../shared/widgets/chart_type_toggle.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/interpolation_toggle.dart';
import '../../../shared/widgets/scope_badge.dart';
import '../../../shared/widgets/ui_add_button.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../../../theme/app_colors.dart';
import '../dialogs/create_dashboard_dialog.dart';
import '../settings_viewmodel.dart';

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({super.key});

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  late final TextEditingController _maxSamplesController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SettingsViewModel>();
    final val = vm.defaultMaxSamples;
    _maxSamplesController = TextEditingController(text: val.toString());
  }

  @override
  void dispose() {
    _maxSamplesController.dispose();
    super.dispose();
  }

  Future<void> _openAdd(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final layout = await showCreateDashboardDialog(context, brokers: vm.brokers);
    if (layout == null) return;
    vm.addLayout(layout);
  }

  Future<void> _openEdit(BuildContext context, DashboardLayout layout) async {
    final vm = context.read<SettingsViewModel>();
    final updated = await showCreateDashboardDialog(context, dashboard: layout, brokers: vm.brokers, onDelete: () => vm.deleteLayout(layout.id));
    if (updated == null) return;
    vm.updateLayout(updated);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final s = S.of(context);
    final layouts = vm.layouts;

    return UiPanelScaffold(
      title: s.dashboardPanelTitle,
      description: s.dashboardPanelDescription,
      children: [
        UiSection(
          label: s.dashboardPanelDefaults,
          children: [
            ColorPickerField(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), label: s.dashboardPanelColor, value: vm.defaultCardColor, onChanged: vm.setDefaultCardColor),
            ChartTypeToggle(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), label: s.dashboardPanelChartType, value: vm.defaultChartType, onChanged: vm.setDefaultChartType),
            InterpolationToggle(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), label: s.dashboardPanelInterpolation, value: vm.defaultInterpolation, onChanged: vm.setDefaultInterpolation),
            UiSliderRow(label: s.dashboardPanelDotSize, value: vm.defaultDotSize, min: 0, max: 10, divisions: 20, displayValue: vm.defaultDotSize.toStringAsFixed(1), onChanged: vm.setDefaultDotSize),
            UiField(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              label: s.dashboardPanelMaxSamples,
              hint: s.dashboardPanelMaxSamplesHint,
              controller: _maxSamplesController,
              keyboardType: TextInputType.number,
              onFieldSubmitted: (v) {
                final parsed = int.tryParse(v.trim()) ?? vm.defaultMaxSamples;
                vm.setDefaultMaxSamples(parsed);
                _maxSamplesController.text = vm.defaultMaxSamples.toString();
              },
            ),
          ],
        ),
        if (layouts.isEmpty)
          UiEmptyState(icon: Icons.dashboard_outlined, title: s.dashboardPanelNoDashboardsTitle, message: s.dashboardPanelNoDashboardsMessage)
        else
          UiSection(
            label: s.dashboardPanelDashboards,
            sortable: true,
            onReorder: (o, n) => vm.reorderLayouts(o, n),
            children: [
              for (int i = 0; i < layouts.length; i++)
                UiSortableRow(
                  key: ValueKey(layouts[i].id),
                  index: i,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.brokerGradientFor(layouts[i].colorIndex)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.dashboard_rounded, size: 18, color: Colors.white),
                  ),
                  title: layouts[i].title,
                  trailing: [ScopeBadge(isGlobal: layouts[i].isGlobal, brokerCount: layouts[i].brokerIds.length)],
                  onTap: () => _openEdit(context, layouts[i]),
                  onDelete: () => vm.deleteLayout(layouts[i].id),
                ),
            ],
          ),
        UiAddButton(label: s.dashboardPanelAddDashboard, onPressed: () => _openAdd(context)),
      ],
    );
  }
}
