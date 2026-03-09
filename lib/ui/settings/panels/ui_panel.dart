import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final hideStatusBar = state.read(SettingsKeys.hideStatusBar);
    final showActivity = state.read(SettingsKeys.showActivity);
    final persistLayout = state.read(SettingsKeys.persistLayout);

    return UiPanelScaffold(
      title: 'UI',
      description: 'Appearance and layout preferences.',
      children: [
        // Appearance
        UiSection(
          label: 'Appearance',
          children: [
            UiSegmentRow<ThemeMode>(
              label: 'Theme Mode',
              accent: accent,
              value: themeMode,
              onChanged: (mode) => context.read<AppStateManager>().write(SettingsKeys.themeMode, mode),
              options: const [
                UiSegmentOption(value: ThemeMode.system, label: 'System', icon: Icons.brightness_auto_rounded),
                UiSegmentOption(value: ThemeMode.light, label: 'Light', icon: Icons.light_mode_rounded),
                UiSegmentOption(value: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_rounded),
              ],
            ),
            UiSwitchRow(label: 'Hide status bar', subtitle: 'Hides bottom status bar', value: hideStatusBar, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.hideStatusBar, v)),
          ],
        ),

        // Data Display
        UiSection(
          label: 'Data Display',
          children: [UiSwitchRow(label: 'Show activity', subtitle: 'Pulse topic when activity occurs', value: showActivity, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.showActivity, v))],
        ),

        // Layout
        UiSection(
          label: 'Layout',
          children: [UiSwitchRow(label: 'Persist Layout', subtitle: 'Restore panel sizes and positions on restart', value: persistLayout, onChanged: (v) => context.read<AppStateManager>().write(SettingsKeys.persistLayout, v))],
        ),
      ],
    );
  }
}
