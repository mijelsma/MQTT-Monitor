import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../models/mqtt_qos_default.dart';
import '../../../models/startup_connection.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/spacers.dart';
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: ColorPickerField(label: s.uiPanelAccentColor, value: vm.accentColor, onChanged: (c) => vm.setAccentColor(c)),
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
          children: [
            UiSwitchRow(label: s.uiPanelPersistLayout, subtitle: s.uiPanelPersistLayoutSubtitle, value: vm.persistLayout, onChanged: (v) => vm.setPersistLayout(v)),
            UiSwitchRow(label: s.uiPanelSidebarAnimations, subtitle: s.uiPanelSidebarAnimationsSubtitle, value: vm.sidebarAnimationsEnabled, onChanged: (v) => vm.setSidebarAnimationsEnabled(v)),
            if (vm.sidebarAnimationsEnabled) UiSliderRow(label: s.uiPanelSidebarAnimationSpeed, subtitle: s.uiPanelSidebarAnimationSpeedSubtitle, value: vm.sidebarAnimationSpeed.toDouble(), min: 0, max: 100, divisions: 10, displayValue: '${vm.sidebarAnimationSpeed}%', accent: accent, onChanged: (v) => vm.setSidebarAnimationSpeed(v.round())),
          ],
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

        // Defaults
        UiSection(
          label: s.uiPanelSectionDefaults,
          children: [
            _LabeledQosRow(
              label: s.uiPanelDefaultPublishQos,
              subtitle: s.uiPanelDefaultPublishQosSubtitle,
              accent: accent,
              value: vm.defaultPublishQos,
              lastUsedQos: vm.lastUsedQos,
              onChanged: (v) => vm.setDefaultPublishQos(v),
            ),
            _LabeledQosRow(
              label: s.uiPanelDefaultShortcutQos,
              subtitle: s.uiPanelDefaultShortcutQosSubtitle,
              accent: accent,
              value: vm.defaultShortcutQos,
              lastUsedQos: vm.lastUsedQos,
              onChanged: (v) => vm.setDefaultShortcutQos(v),
            ),
            _LabeledQosRow(
              label: s.uiPanelDefaultSubscribeQos,
              subtitle: s.uiPanelDefaultSubscribeQosSubtitle,
              accent: accent,
              value: vm.defaultSubscribeQos,
              lastUsedQos: vm.lastUsedQos,
              onChanged: (v) => vm.setDefaultSubscribeQos(v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A [MqttQosDefault] selector with a label and subtitle, used by the
/// Defaults section of the User Interface settings panel. The standard
/// [UiSegmentRow] doesn't expose a subtitle, so this wraps it with a
/// small caption underneath. Each option renders its enum-bundled icon
/// (last-used, Q0, Q1, Q2).
class _LabeledQosRow extends StatelessWidget {
  const _LabeledQosRow({required this.label, required this.subtitle, required this.accent, required this.value, required this.lastUsedQos, required this.onChanged});

  final String label;
  final String subtitle;
  final Color accent;
  final MqttQosDefault value;
  final int lastUsedQos;
  final ValueChanged<MqttQosDefault> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = S.of(context);
    final lastUsedLabel = MqttQosDefault.fromQos(lastUsedQos).shortLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const VSpacer(2),
          Text(subtitle, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary)),
          const VSpacer(10),
          Row(
            children: [
              for (final option in MqttQosDefault.values) ...[
                Expanded(
                  child: _QosChip(
                    icon: option.icon,
                    label: option == MqttQosDefault.lastUsed ? s.uiPanelQosOptionLastUsed : option.shortLabel,
                    description: option == MqttQosDefault.lastUsed ? s.uiPanelQosOptionLastUsedSubtitle : null,
                    isSelected: value == option,
                    accent: accent,
                    onTap: () => onChanged(option),
                  ),
                ),
                if (option != MqttQosDefault.values.last) const SizedBox(width: 6),
              ],
            ],
          ),
          if (value == MqttQosDefault.lastUsed) ...[
            const VSpacer(8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${s.uiPanelQosOptionLastUsed}: $lastUsedLabel',
                style: TextStyle(fontSize: 10.5, color: tokens.textTertiary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QosChip extends StatelessWidget {
  const _QosChip({required this.icon, required this.label, this.description, required this.isSelected, required this.accent, required this.onTap});

  final Widget icon;
  final String label;
  final String? description;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = isSelected ? tokens.onPrimary : tokens.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent : tokens.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? accent : tokens.border, width: isSelected ? 0.5 : 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: 20, color: fg),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: fg),
                child: icon,
              ),
            ),
            const VSpacer(4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
            ),
            if (description != null) ...[
              const VSpacer(2),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.75), height: 1.2),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
