import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../widgets/section_header.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';
import '../widgets/switch_row.dart';
import '../../widgets/spacers.dart';

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
    final theme = Theme.of(context);
    final accent = context.tokens.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('UI', style: theme.textTheme.headlineSmall),

          // Spacer
          VSpacer(6),

          // Description
          Text('Appearance and layout preferences.', style: theme.textTheme.bodySmall),
          VSpacer(20),

          // Appearance
          const SectionHeader(label: 'Appearance'),
          VSpacer(8),
          SettingsGroup(
            children: [
              SettingsRow(
                isLast: false,
                child: _ThemeModeSelector(value: _themeMode, accent: accent, onChanged: (mode) => setState(() => _themeMode = mode)),
              ),
              SwitchRow(label: 'Hide status bar', subtitle: 'Hides bottom status bar', value: _compactDensity, onChanged: (v) => setState(() => _compactDensity = v)),
            ],
          ),

          // Spacer
          VSpacer(20),

          // Data Display
          const SectionHeader(label: 'Data Display'),
          VSpacer(8),
          SettingsGroup(
            children: [SwitchRow(label: 'Show activity', subtitle: 'Pulse topic when activity occurs', value: _showTopicTree, isLast: false, onChanged: (v) => setState(() => _showTopicTree = v))],
          ),
          VSpacer(20),

          // Layout
          const SectionHeader(label: 'Layout'),
          VSpacer(8),
          SettingsGroup(
            children: [SwitchRow(label: 'Persist Layout', subtitle: 'Restore panel sizes and positions on restart', value: _persistLayout, onChanged: (v) => setState(() => _persistLayout = v))],
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.value, required this.accent, required this.onChanged});

  final ThemeMode value;
  final Color accent;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          VSpacer(10),
          Row(
            children: ThemeMode.values.map((mode) {
              final label = switch (mode) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              };
              final icon = switch (mode) {
                ThemeMode.system => Icons.brightness_auto_rounded,
                ThemeMode.light => Icons.light_mode_rounded,
                ThemeMode.dark => Icons.dark_mode_rounded,
              };
              final isSelected = value == mode;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onChanged(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? accent : tokens.elevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? accent : tokens.border, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          Icon(icon, size: 20, color: isSelected ? Colors.white : tokens.textSecondary),
                          VSpacer(4),
                          Text(
                            label,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
