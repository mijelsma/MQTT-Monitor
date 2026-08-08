import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../settings_viewmodel.dart';

/// Snaps a slider position to the allowed history sizes: 1, then multiples of 5 (5, 10, 15, ...) up to the maximum.
int snapPerTopicHistory(double value) => value <= 3 ? 1 : (value / 5).round() * 5;

class AdvancedPanel extends StatelessWidget {
  const AdvancedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final s = S.of(context);

    return UiPanelScaffold(
      title: s.advancedPanelTitle,
      description: s.advancedPanelDescription,
      descriptionStyle: TextStyle(fontWeight: FontWeight.w600, color: context.tokens.error),
      children: [
        UiSection(
          label: s.advancedPanelHistoryBuffer,
          children: [
            UiSliderRow(label: s.advancedPanelMessagesPerTopic, subtitle: s.advancedPanelMessagesPerTopicHint, value: vm.defaultHistorySize.toDouble(), min: 1, max: 500, divisions: 100, displayValue: '${vm.defaultHistorySize}', onChanged: (v) => vm.setDefaultHistorySize(snapPerTopicHistory(v))),
            UiSliderRow(label: s.monitoringPanelIncreasedBufferSize, subtitle: s.monitoringPanelIncreasedBufferHint, value: vm.increasedHistorySize.toDouble(), min: 50, max: 5000, divisions: 99, displayValue: '${vm.increasedHistorySize}', onChanged: (v) => vm.setIncreasedHistorySize(v.round())),
          ],
        ),
      ],
    );
  }
}
