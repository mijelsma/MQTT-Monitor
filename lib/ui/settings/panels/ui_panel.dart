import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';
import '../../elements/ui_switch_row.dart';
import '../../elements/ui_segment_row.dart';

class UiPanel extends StatefulWidget {
  const UiPanel({super.key});

  @override
  State<UiPanel> createState() => _UiPanelState();
}

class _UiPanelState extends State<UiPanel> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _compactDensity = false;
  bool _showTopicTree = true;
  bool _persistLayout = true;

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.primary;

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
              value: _themeMode,
              onChanged: (mode) => setState(() => _themeMode = mode),
              options: const [
                UiSegmentOption(value: ThemeMode.system, label: 'System', icon: Icons.brightness_auto_rounded),
                UiSegmentOption(value: ThemeMode.light, label: 'Light', icon: Icons.light_mode_rounded),
                UiSegmentOption(value: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_rounded),
              ],
            ),
            UiSwitchRow(label: 'Hide status bar', subtitle: 'Hides bottom status bar', value: _compactDensity, onChanged: (v) => setState(() => _compactDensity = v)),
          ],
        ),

        // Data Display
        UiSection(
          label: 'Data Display',
          children: [
            UiSwitchRow(label: 'Show activity', subtitle: 'Pulse topic when activity occurs', value: _showTopicTree, onChanged: (v) => setState(() => _showTopicTree = v)), //
          ],
        ),

        // Layout
        UiSection(
          label: 'Layout',
          children: [
            UiSwitchRow(label: 'Persist Layout', subtitle: 'Restore panel sizes and positions on restart', value: _persistLayout, onChanged: (v) => setState(() => _persistLayout = v)), //
          ],
        ),
      ],
    );
  }
}
