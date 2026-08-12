import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/history/history_policy_rules.dart';
import '../../../generated/l10n.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../settings_viewmodel.dart';

class AdvancedPanel extends StatefulWidget {
  const AdvancedPanel({super.key});

  @override
  State<AdvancedPanel> createState() => _AdvancedPanelState();
}

class _AdvancedPanelState extends State<AdvancedPanel> {
  int? _draftMaximum;

  Future<void> _resetSettings(SettingsViewModel viewModel) async {
    final strings = S.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.advancedPanelResetConfirmTitle),
            content: Text(strings.advancedPanelResetConfirmBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.tokens.error),
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings.advancedPanelResetAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final result = await viewModel.resetSettingsToDefaults();
    if (!mounted) return;
    final message = !result.succeeded
        ? strings.advancedPanelResetFailed
        : result.cleanupFailures > 0
        ? strings.advancedPanelResetCleanupWarning
        : strings.advancedPanelResetSuccess;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _finishMaximumChange(SettingsViewModel viewModel, int maximum) async {
    final current = viewModel.maximumHistoryRetention;
    var confirmed = true;
    if (maximum < current) {
      final impact = viewModel.previewMaximumHistoryRetention(maximum);
      if (impact.subscriptions > 0 || impact.defaultPolicy > 0 || impact.liveBuffers > 0) {
        if (!mounted) return;
        final strings = S.of(context);
        confirmed =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.advancedPanelMaximumConfirmTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(strings.advancedPanelMaximumConfirmBody), const SizedBox(height: 12), Text('${strings.advancedPanelAffectedSubscriptions}: ${impact.subscriptions}'), Text('${strings.advancedPanelAffectedDefault}: ${impact.defaultPolicy}'), Text('${strings.advancedPanelAffectedBuffers}: ${impact.liveBuffers}')],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.save)),
                ],
              ),
            ) ??
            false;
      }
    }

    if (confirmed) await viewModel.applyMaximumHistoryRetention(maximum);
    if (mounted) setState(() => _draftMaximum = null);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final strings = S.of(context);
    final maximum = _draftMaximum ?? viewModel.maximumHistoryRetention;

    return UiPanelScaffold(
      title: strings.advancedPanelTitle,
      description: strings.advancedPanelDescription,
      descriptionStyle: TextStyle(fontWeight: FontWeight.w600, color: context.tokens.error),
      children: [
        UiSection(
          label: strings.advancedPanelHistoryBuffer,
          children: [
            UiSwitchRow(label: strings.advancedPanelNewSubscriptionHistory, subtitle: strings.advancedPanelNewSubscriptionHistoryHint, value: viewModel.newSubscriptionHistoryEnabled, onChanged: viewModel.setNewSubscriptionHistoryEnabled),
            UiSliderRow(
              label: strings.advancedPanelDefaultRetention,
              subtitle: strings.advancedPanelDefaultRetentionHint,
              value: viewModel.newSubscriptionHistoryRetention.toDouble(),
              min: HistoryPolicyRules.minimumRetention.toDouble(),
              max: viewModel.maximumHistoryRetention.toDouble(),
              divisions: viewModel.maximumHistoryRetention - HistoryPolicyRules.minimumRetention,
              displayValue: '${viewModel.newSubscriptionHistoryRetention}',
              onChanged: viewModel.newSubscriptionHistoryEnabled ? (value) => viewModel.setNewSubscriptionHistoryRetention(value.round()) : null,
            ),
            UiSliderRow(
              label: strings.advancedPanelMaximumRetention,
              subtitle: strings.advancedPanelMaximumRetentionHint,
              value: maximum.toDouble(),
              min: HistoryPolicyRules.minimumMaximumRetention.toDouble(),
              max: HistoryPolicyRules.maximumMaximumRetention.toDouble(),
              divisions: (HistoryPolicyRules.maximumMaximumRetention - HistoryPolicyRules.minimumMaximumRetention) ~/ HistoryPolicyRules.maximumRetentionStep,
              displayValue: '$maximum',
              onChanged: (value) => setState(() => _draftMaximum = value.round()),
              onChangeEnd: (value) => _finishMaximumChange(viewModel, value.round()),
            ),
          ],
        ),
        UiSection(
          label: strings.advancedPanelResetSection,
          children: [_ResetSettingsRow(title: strings.advancedPanelResetTitle, subtitle: strings.advancedPanelResetHint, actionLabel: strings.advancedPanelResetAction, onPressed: () => _resetSettings(viewModel))],
        ),
      ],
    );
  }
}

class _ResetSettingsRow extends StatelessWidget {
  const _ResetSettingsRow({required this.title, required this.subtitle, required this.actionLabel, required this.onPressed});

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: tokens.error),
            onPressed: onPressed,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
