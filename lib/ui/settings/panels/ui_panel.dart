import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n.dart';
import '../../../state/app_state.dart';
import '../../../state/keys/settings_keys.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';
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
    final showActivity = state.read(SettingsKeys.showActivity);
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
          ],
        ),

        // Data Display
        UiSection(
          label: s.uiPanelSectionDataDisplay,
          children: [UiSwitchRow(label: s.uiPanelShowActivity, subtitle: s.uiPanelShowActivitySubtitle, value: showActivity, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.showActivity, v))],
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
