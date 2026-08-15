import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/dashboard/dashboard_series_policy.dart';
import '../../../generated/l10n.dart';
import '../../../core/dashboard/models/dashboard_layout_model.dart';
import '../../../shared/widgets/chart_type_toggle.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/interpolation_toggle.dart';
import '../../../shared/widgets/scope_badge.dart';
import '../../../shared/widgets/ui_add_button.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../../../theme/app_colors.dart';
import '../dialogs/create_dashboard_dialog.dart';
import '../view_models/settings_view_model.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key});

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
            ColorPickerField(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              label: s.dashboardPanelColor,
              value: vm.defaultCardColor,
              onChanged: vm.setDefaultCardColor,
            ),
            ChartTypeToggle(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              label: s.dashboardPanelChartType,
              value: vm.defaultChartType,
              onChanged: vm.setDefaultChartType,
            ),
            InterpolationToggle(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              label: s.dashboardPanelInterpolation,
              value: vm.defaultInterpolation,
              onChanged: vm.setDefaultInterpolation,
            ),
            UiSliderRow(
              label: s.dashboardPanelDotSize,
              subtitle: s.dashboardPanelDotSizeHint,
              value: vm.defaultDotSize,
              min: 0,
              max: 10,
              divisions: 20,
              displayValue: vm.defaultDotSize.toStringAsFixed(1),
              onChanged: vm.setDefaultDotSize,
            ),
            UiSliderRow(
              label: s.dashboardPanelMaxSamples,
              subtitle: s.dashboardPanelMaxSamplesHint,
              value: DashboardSeriesPolicy.settingSliderPosition(
                vm.defaultMaxSamples,
              ),
              min: 0,
              max: DashboardSeriesPolicy.settingsSliderDivisions.toDouble(),
              divisions: DashboardSeriesPolicy.settingsSliderDivisions,
              displayValue: vm.defaultMaxSamples.toString(),
              minimumLabel: DashboardSeriesPolicy.minimumSamples.toString(),
              maximumLabel: DashboardSeriesPolicy.settingsMaximumSamples
                  .toString(),
              semanticFormatterCallback: (position) =>
                  DashboardSeriesPolicy.samplesForSettingSlider(
                    position,
                  ).toString(),
              onChanged: (position) => vm.setDefaultMaxSamples(
                DashboardSeriesPolicy.samplesForSettingSlider(position),
              ),
            ),
          ],
        ),
        if (layouts.isEmpty)
          UiEmptyState(
            icon: Icons.dashboard_outlined,
            title: s.dashboardPanelNoDashboardsTitle,
            message: s.dashboardPanelNoDashboardsMessage,
          )
        else
          UiSection(
            label: s.dashboardPanelDashboards,
            sortable: true,
            onReorder: (oldIndex, newIndex) =>
                vm.reorderLayouts(oldIndex, newIndex),
            children: [
              for (var index = 0; index < layouts.length; index++)
                UiSortableRow(
                  key: ValueKey(layouts[index].id),
                  index: index,
                  leading: Container(
                    width: 3.5,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.brokerGradientFor(
                          layouts[index].colorIndex,
                        ),
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: layouts[index].title,
                  trailing: [
                    ScopeBadge(
                      isGlobal: layouts[index].isGlobal,
                      brokerCount: layouts[index].brokerIds.length,
                    ),
                  ],
                  onTap: () => _openEdit(context, layouts[index]),
                  onDelete: () => vm.deleteLayout(layouts[index].id),
                ),
            ],
          ),
        UiAddButton(
          label: s.dashboardPanelAddDashboard,
          onPressed: () => _openAdd(context),
        ),
      ],
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final layout = await showCreateDashboardDialog(
      context,
      brokers: vm.brokers,
    );
    if (layout != null) vm.addLayout(layout);
  }

  Future<void> _openEdit(
    BuildContext context,
    DashboardLayoutModel layout,
  ) async {
    final vm = context.read<SettingsViewModel>();
    final updated = await showCreateDashboardDialog(
      context,
      dashboard: layout,
      brokers: vm.brokers,
      onDelete: () => vm.deleteLayout(layout.id),
    );
    if (updated != null) vm.updateLayout(updated);
  }
}
