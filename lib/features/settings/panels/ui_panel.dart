import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../core/publishing/models/mqtt_qos_default_model.dart';
import '../../../core/mqtt/models/mqtt_protocol_version_model.dart';
import '../../../core/ui/models/sidebar_panel_default_model.dart';
import '../../../core/ui/models/search_defaults.dart';
import '../../../core/mqtt/models/startup_connection_model.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/ui_inline_segment_row.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_segment_row.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../view_models/settings_view_model.dart';

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
            UiSwitchRow(label: s.uiPanelDisableSelectionHighlight, subtitle: s.uiPanelDisableSelectionHighlightSubtitle, value: vm.disableSelectionHighlight, onChanged: (v) => vm.setDisableSelectionHighlight(v)),
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

        UiSection(
          label: s.uiPanelSectionSearch,
          children: [
            UiSegmentRow<SearchMatchMode>(
              label: s.uiPanelSearchMatchDefault,
              accent: accent,
              value: vm.defaultSearchMatchMode,
              onChanged: vm.setDefaultSearchMatchMode,
              options: [
                UiSegmentOption(value: SearchMatchMode.any, label: s.searchModeAny),
                UiSegmentOption(value: SearchMatchMode.all, label: s.searchModeAll),
              ],
            ),
            UiSegmentRow<SearchScope>(
              label: s.uiPanelSearchScopeDefault,
              accent: accent,
              value: vm.defaultSearchScope,
              onChanged: vm.setDefaultSearchScope,
              options: [
                UiSegmentOption(value: SearchScope.all, label: s.searchScopeAll),
                UiSegmentOption(value: SearchScope.topic, label: s.searchScopeTopic),
                UiSegmentOption(value: SearchScope.value, label: s.searchScopeValue),
              ],
            ),
          ],
        ),

        // Connection
        UiSection(
          label: s.uiPanelSectionConnection,
          children: [
            UiSegmentRow<StartupConnectionModel>(
              label: s.uiPanelStartupBehavior,
              accent: accent,
              value: vm.startupConnection,
              onChanged: (v) => vm.setStartupConnection(v),
              options: [
                UiSegmentOption(value: StartupConnectionModel.alwaysConnect, label: s.uiPanelStartupConnect, icon: Icons.power_rounded),
                UiSegmentOption(value: StartupConnectionModel.lastStatus, label: s.uiPanelStartupLastStatus, icon: Icons.restore_rounded),
                UiSegmentOption(value: StartupConnectionModel.stayDisconnected, label: s.uiPanelStartupDisconnected, icon: Icons.power_off_rounded),
              ],
            ),
            UiSegmentRow<MqttProtocolVersionModel>(
              label: s.uiPanelDefaultBrokerProtocol,
              accent: accent,
              value: vm.defaultBrokerProtocol,
              onChanged: vm.setDefaultBrokerProtocol,
              options: [for (final version in MqttProtocolVersionModel.values) UiSegmentOption(value: version, label: version.displayName)],
            ),
          ],
        ),

        // Sidebar Panel Defaults
        UiSection(
          label: s.uiPanelSectionSidebarPanels,
          children: [
            UiInlineSegmentRow<SidebarPanelDefaultModel>(
              icon: const Icon(Icons.info_outline_rounded),
              label: s.sidebarMessageDetail,
              accent: accent,
              value: vm.defaultSidebarDetail,
              onChanged: (v) => vm.setDefaultSidebarDetail(v),
              options: [
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.collapsed, label: s.uiPanelDefaultStateCollapsed, icon: const Icon(Icons.expand_less_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.expanded, label: s.uiPanelDefaultStateExpanded, icon: const Icon(Icons.expand_more_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.lastStatus, label: s.uiPanelDefaultStateLastStatus, icon: const Icon(Icons.restore_rounded)),
              ],
            ),
            UiInlineSegmentRow<SidebarPanelDefaultModel>(
              icon: const Icon(Icons.history_rounded),
              label: s.sidebarHistory,
              accent: accent,
              value: vm.defaultSidebarHistory,
              onChanged: (v) => vm.setDefaultSidebarHistory(v),
              options: [
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.collapsed, label: s.uiPanelDefaultStateCollapsed, icon: const Icon(Icons.expand_less_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.expanded, label: s.uiPanelDefaultStateExpanded, icon: const Icon(Icons.expand_more_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.lastStatus, label: s.uiPanelDefaultStateLastStatus, icon: const Icon(Icons.restore_rounded)),
              ],
            ),
            UiInlineSegmentRow<SidebarPanelDefaultModel>(
              icon: const Icon(Icons.send_rounded),
              label: s.sidebarPublish,
              accent: accent,
              value: vm.defaultSidebarPublish,
              onChanged: (v) => vm.setDefaultSidebarPublish(v),
              options: [
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.collapsed, label: s.uiPanelDefaultStateCollapsed, icon: const Icon(Icons.expand_less_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.expanded, label: s.uiPanelDefaultStateExpanded, icon: const Icon(Icons.expand_more_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.lastStatus, label: s.uiPanelDefaultStateLastStatus, icon: const Icon(Icons.restore_rounded)),
              ],
            ),
            UiInlineSegmentRow<SidebarPanelDefaultModel>(
              icon: const Icon(Icons.bolt_rounded),
              label: s.sidebarShortcuts,
              accent: accent,
              value: vm.defaultSidebarShortcuts,
              onChanged: (v) => vm.setDefaultSidebarShortcuts(v),
              options: [
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.collapsed, label: s.uiPanelDefaultStateCollapsed, icon: const Icon(Icons.expand_less_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.expanded, label: s.uiPanelDefaultStateExpanded, icon: const Icon(Icons.expand_more_rounded)),
                UiInlineSegmentOption(value: SidebarPanelDefaultModel.lastStatus, label: s.uiPanelDefaultStateLastStatus, icon: const Icon(Icons.restore_rounded)),
              ],
            ),
          ],
        ),

        // Defaults
        UiSection(
          label: s.uiPanelSectionDefaults,
          children: [
            UiInlineSegmentRow<MqttQosDefaultModel>(
              label: s.uiPanelDefaultPublishQos,
              subtitle: s.uiPanelDefaultPublishQosSubtitle,
              accent: accent,
              value: vm.defaultPublishQos,
              onChanged: (v) => vm.setDefaultPublishQos(v),
              footer: vm.defaultPublishQos == MqttQosDefaultModel.lastUsed ? Text('${s.uiPanelQosOptionLastUsed}: ${MqttQosDefaultModel.fromQos(vm.lastUsedQos).shortLabel}') : null,
              options: [for (final option in MqttQosDefaultModel.values) UiInlineSegmentOption(value: option, label: option == MqttQosDefaultModel.lastUsed ? s.uiPanelQosOptionLastUsed : option.shortLabel, icon: option == MqttQosDefaultModel.lastUsed ? const Icon(Icons.history_rounded) : null)],
            ),
            UiInlineSegmentRow<MqttQosDefaultModel>(
              label: s.uiPanelDefaultShortcutQos,
              subtitle: s.uiPanelDefaultShortcutQosSubtitle,
              accent: accent,
              value: vm.defaultShortcutQos,
              onChanged: (v) => vm.setDefaultShortcutQos(v),
              footer: vm.defaultShortcutQos == MqttQosDefaultModel.lastUsed ? Text('${s.uiPanelQosOptionLastUsed}: ${MqttQosDefaultModel.fromQos(vm.lastUsedQos).shortLabel}') : null,
              options: [for (final option in MqttQosDefaultModel.values) UiInlineSegmentOption(value: option, label: option == MqttQosDefaultModel.lastUsed ? s.uiPanelQosOptionLastUsed : option.shortLabel, icon: option == MqttQosDefaultModel.lastUsed ? const Icon(Icons.history_rounded) : null)],
            ),
            UiInlineSegmentRow<MqttQosDefaultModel>(
              label: s.uiPanelDefaultSubscribeQos,
              subtitle: s.uiPanelDefaultSubscribeQosSubtitle,
              accent: accent,
              value: vm.defaultSubscribeQos,
              onChanged: (v) => vm.setDefaultSubscribeQos(v),
              footer: vm.defaultSubscribeQos == MqttQosDefaultModel.lastUsed ? Text('${s.uiPanelQosOptionLastUsed}: ${MqttQosDefaultModel.fromQos(vm.lastUsedQos).shortLabel}') : null,
              options: [for (final option in MqttQosDefaultModel.values) UiInlineSegmentOption(value: option, label: option == MqttQosDefaultModel.lastUsed ? s.uiPanelQosOptionLastUsed : option.shortLabel, icon: option == MqttQosDefaultModel.lastUsed ? const Icon(Icons.history_rounded) : null)],
            ),
          ],
        ),
      ],
    );
  }
}
