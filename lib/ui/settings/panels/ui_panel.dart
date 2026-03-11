import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n.dart';
import '../../../state/app_state.dart';
import '../../../state/keys/settings_keys.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';
import '../../elements/ui_slider_row.dart';
import '../../elements/ui_switch_row.dart';
import '../../elements/ui_segment_row.dart';

class UiPanel extends StatelessWidget {
  const UiPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateManager>();
    final accent = context.tokens.primary;

    final themeMode = state.read(SettingsKeys.themeMode);
    final showStatusBar = state.read(SettingsKeys.showStatusBar);
    final rateIntervalMs = state.read(SettingsKeys.rateIntervalMs);
    final showActivity = state.read(SettingsKeys.showActivity);
    final pulseRatePps = state.read(SettingsKeys.pulseRatePps);
    final pulseFadeMs = state.read(SettingsKeys.pulseFadeMs);
    final persistLayout = state.read(SettingsKeys.persistLayout);

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
              value: themeMode,
              onChanged: (mode) => context.read<AppStateManager>().write(SettingsKeys.themeMode, mode),
              options: [
                UiSegmentOption(value: ThemeMode.system, label: s.uiPanelThemeSystem, icon: Icons.brightness_auto_rounded),
                UiSegmentOption(value: ThemeMode.light, label: s.uiPanelThemeLight, icon: Icons.light_mode_rounded),
                UiSegmentOption(value: ThemeMode.dark, label: s.uiPanelThemeDark, icon: Icons.dark_mode_rounded),
              ],
            ),
            UiSwitchRow(label: s.uiPanelShowStatusBar, subtitle: s.uiPanelShowStatusBarSubtitle, value: showStatusBar, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.showStatusBar, v)),
            if (showStatusBar)
              UiSliderRow(
                label: s.uiPanelRateInterval,
                subtitle: s.uiPanelRateIntervalSubtitle,
                value: rateIntervalMs.toDouble(),
                min: 500,
                max: 5000,
                divisions: 9,
                displayValue: '${rateIntervalMs / 1000} s',
                accent: accent,
                onChanged: (v) {
                  final snapped = (v / 500).round() * 500;
                  context.read<AppStateManager>().write(SettingsKeys.rateIntervalMs, snapped);
                },
              ),
          ],
        ),

        // Data Display
        UiSection(
          label: s.uiPanelSectionDataDisplay,
          children: [
            UiSwitchRow(label: s.uiPanelShowActivity, subtitle: s.uiPanelShowActivitySubtitle, value: showActivity, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.showActivity, v)),
            if (showActivity) ...[
              UiSliderRow(label: s.uiPanelPulseRate, subtitle: s.uiPanelPulseRateSubtitle, value: pulseRatePps.toDouble(), min: 1, max: 30, divisions: 29, displayValue: '$pulseRatePps pps', accent: accent, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.pulseRatePps, v.round())),
              UiSliderRow(
                label: s.uiPanelPulseFade,
                subtitle: s.uiPanelPulseFadeSubtitle,
                value: pulseFadeMs.toDouble(),
                min: 100,
                max: 2000,
                divisions: 19,
                displayValue: '$pulseFadeMs ms',
                accent: accent,
                onChanged: (v) {
                  // Snap to nearest 100 ms step
                  final snapped = (v / 100).round() * 100;
                  context.read<AppStateManager>().write(SettingsKeys.pulseFadeMs, snapped);
                },
              ),
            ],
          ],
        ),

        // Layout
        UiSection(
          label: s.uiPanelSectionLayout,
          children: [UiSwitchRow(label: s.uiPanelPersistLayout, subtitle: s.uiPanelPersistLayoutSubtitle, value: persistLayout, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.persistLayout, v))],
        ),
      ],
    );
  }
}
