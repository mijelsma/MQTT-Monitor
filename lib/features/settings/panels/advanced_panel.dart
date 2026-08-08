import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../settings_viewmodel.dart';

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
            UiSliderRow(label: s.advancedPanelMessagesPerTopic, subtitle: s.advancedPanelMessagesPerTopicHint, value: vm.defaultHistorySize.toDouble(), min: 10, max: 500, divisions: 99, displayValue: '${vm.defaultHistorySize}', onChanged: (v) => vm.setDefaultHistorySize(v.round())),
            UiSliderRow(label: s.monitoringPanelIncreasedBufferSize, subtitle: s.monitoringPanelIncreasedBufferHint, value: vm.increasedHistorySize.toDouble(), min: 100, max: 5000, divisions: 99, displayValue: '${vm.increasedHistorySize}', onChanged: (v) => vm.setIncreasedHistorySize(v.round())),
          ],
        ),
      ],
    );
  }
}
