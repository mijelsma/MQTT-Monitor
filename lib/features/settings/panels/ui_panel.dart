import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../models/startup_connection.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_segment_row.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../settings_viewmodel.dart';

class UiPanel extends StatelessWidget {
  const UiPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final accent = context.tokens.primary;
    final s = S.of(context);

    return UiPanelScaffold(
      title: s.uiPanelTitle,
      description: s.uiPanelDescription,
      children: [
        // Appearance
        UiSection(
          label: s.uiPanelSectionAppearance,
          children: [
            UiSegmentRow<ThemeMode>(
              label: s.uiPanelThemeMode,
              accent: accent,
              value: vm.themeMode,
              onChanged: (mode) => vm.setThemeMode(mode),
              options: [
                UiSegmentOption(value: ThemeMode.system, label: s.uiPanelThemeSystem, icon: Icons.brightness_auto_rounded),
                UiSegmentOption(value: ThemeMode.light, label: s.uiPanelThemeLight, icon: Icons.light_mode_rounded),
                UiSegmentOption(value: ThemeMode.dark, label: s.uiPanelThemeDark, icon: Icons.dark_mode_rounded),
              ],
            ),
            UiSwitchRow(label: s.uiPanelShowStatusBar, subtitle: s.uiPanelShowStatusBarSubtitle, value: vm.showStatusBar, onChanged: (v) => vm.setShowStatusBar(v)),
            if (vm.showStatusBar)
              UiSliderRow(
                label: s.uiPanelRateInterval,
                subtitle: s.uiPanelRateIntervalSubtitle,
                value: vm.rateIntervalMs.toDouble(),
                min: 500,
                max: 5000,
                divisions: 9,
                displayValue: '${vm.rateIntervalMs / 1000} s',
                accent: accent,
                onChanged: (v) {
                  final snapped = (v / 500).round() * 500;
                  vm.setRateIntervalMs(snapped);
                },
              ),
          ],
        ),

        // Data Display
        UiSection(
          label: s.uiPanelSectionDataDisplay,
          children: [
            UiSwitchRow(label: s.uiPanelShowActivity, subtitle: s.uiPanelShowActivitySubtitle, value: vm.showActivity, onChanged: (v) => vm.setShowActivity(v)),
            if (vm.showActivity) ...[
              UiSliderRow(label: s.uiPanelPulseRate, subtitle: s.uiPanelPulseRateSubtitle, value: vm.pulseRatePps.toDouble(), min: 1, max: 30, divisions: 29, displayValue: '${vm.pulseRatePps} pps', accent: accent, onChanged: (v) => vm.setPulseRatePps(v.round())),
              UiSliderRow(
                label: s.uiPanelPulseFade,
                subtitle: s.uiPanelPulseFadeSubtitle,
                value: vm.pulseFadeMs.toDouble(),
                min: 50,
                max: 2000,
                divisions: 39,
                displayValue: '${vm.pulseFadeMs} ms',
                accent: accent,
                onChanged: (v) {
                  final snapped = (v / 50).round() * 50;
                  vm.setPulseFadeMs(snapped);
                },
              ),
            ],
          ],
        ),

        // Layout
        UiSection(
          label: s.uiPanelSectionLayout,
          children: [UiSwitchRow(label: s.uiPanelPersistLayout, subtitle: s.uiPanelPersistLayoutSubtitle, value: vm.persistLayout, onChanged: (v) => vm.setPersistLayout(v))],
        ),

        // Connection
        UiSection(
          label: s.uiPanelSectionConnection,
          children: [
            UiSegmentRow<StartupConnection>(
              label: s.uiPanelStartupBehavior,
              accent: accent,
              value: vm.startupConnection,
              onChanged: (v) => vm.setStartupConnection(v),
              options: [
                UiSegmentOption(value: StartupConnection.alwaysConnect, label: s.uiPanelStartupConnect, icon: Icons.power_rounded),
                UiSegmentOption(value: StartupConnection.lastStatus, label: s.uiPanelStartupLastStatus, icon: Icons.restore_rounded),
                UiSegmentOption(value: StartupConnection.stayDisconnected, label: s.uiPanelStartupDisconnected, icon: Icons.power_off_rounded),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
