import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../settings_viewmodel.dart';

class MonitoringPanel extends StatelessWidget {
  const MonitoringPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final s = S.of(context);

    return UiPanelScaffold(
      title: s.monitoringPanelTitle,
      description: s.monitoringPanelDescription,
      children: [
        UiSection(
          label: s.monitoringPanelRateSampling,
          children: [UiSliderRow(label: s.monitoringPanelRateSampleSize, subtitle: s.monitoringPanelRateSampleHint, value: vm.messageRateSampleSize.toDouble(), min: 2, max: 50, divisions: 48, displayValue: '${vm.messageRateSampleSize}', onChanged: (v) => vm.setMessageRateSampleSize(v.round()))],
        ),
      ],
    );
  }
}
