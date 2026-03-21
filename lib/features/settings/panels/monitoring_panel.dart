import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../settings_viewmodel.dart';

class MonitoringPanel extends StatefulWidget {
  const MonitoringPanel({super.key});

  @override
  State<MonitoringPanel> createState() => _MonitoringPanelState();
}

class _MonitoringPanelState extends State<MonitoringPanel> {
  late final TextEditingController _defaultHistoryController;
  late final TextEditingController _extendedHistoryController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SettingsViewModel>();
    _defaultHistoryController = TextEditingController(text: vm.defaultHistorySize.toString());
    _extendedHistoryController = TextEditingController(text: vm.increasedHistorySize.toString());
  }

  @override
  void dispose() {
    _defaultHistoryController.dispose();
    _extendedHistoryController.dispose();
    super.dispose();
  }

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: UiField(
                label: s.monitoringPanelStandardBufferSize,
                hint: s.monitoringPanelStandardBufferHint,
                controller: _defaultHistoryController,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (v) {
                  final parsed = int.tryParse(v.trim()) ?? 50;
                  vm.setDefaultHistorySize(parsed.clamp(1, 10000));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: UiField(
                label: s.monitoringPanelIncreasedBufferSize,
                hint: s.monitoringPanelIncreasedBufferHint,
                controller: _extendedHistoryController,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (v) {
                  final parsed = int.tryParse(v.trim()) ?? 500;
                  vm.setIncreasedHistorySize(parsed.clamp(1, 100000));
                },
              ),
            ),
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
