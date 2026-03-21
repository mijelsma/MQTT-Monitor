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
          label: s.monitoringPanelHistoryBuffer,
          children: [
            UiSliderRow(label: s.monitoringPanelStandardBufferSize, subtitle: s.monitoringPanelStandardBufferHint, value: vm.defaultHistorySize.toDouble(), min: 10, max: 1000, divisions: 99, displayValue: '${vm.defaultHistorySize}', onChanged: (v) => vm.setDefaultHistorySize(v.round())),
            UiSliderRow(label: s.monitoringPanelIncreasedBufferSize, subtitle: s.monitoringPanelIncreasedBufferHint, value: vm.increasedHistorySize.toDouble(), min: 100, max: 10000, divisions: 99, displayValue: '${vm.increasedHistorySize}', onChanged: (v) => vm.setIncreasedHistorySize(v.round())),
            UiSliderRow(label: s.monitoringPanelRateSampleSize, subtitle: s.monitoringPanelRateSampleHint, value: vm.messageRateSampleSize.toDouble(), min: 2, max: 50, divisions: 48, displayValue: '${vm.messageRateSampleSize}', onChanged: (v) => vm.setMessageRateSampleSize(v.round())),
          ],
        ),
        if (vm.increasedMonitoringTopics.isNotEmpty)
          UiSection(
            label: s.monitoringPanelIncreasedMonitoring,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${vm.increasedMonitoringTopics.length} topic(s)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    TextButton(
                      onPressed: () => vm.clearIncreasedMonitoringTopics(),
                      child: Text(s.monitoringPanelClearAll, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              for (final topic in vm.increasedMonitoringTopics)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topic,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => vm.removeIncreasedMonitoringTopic(topic), icon: const Icon(Icons.close_rounded, size: 14), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24), splashRadius: 14, tooltip: s.remove),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
