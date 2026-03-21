import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return UiPanelScaffold(
      title: 'Monitoring',
      description: 'Configure message history retention for topics.',
      children: [
        UiSection(
          label: 'History buffer',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: UiField(
                label: 'Standard buffer size',
                hint: 'Messages stored per topic',
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
                label: 'Increased buffer size',
                hint: 'Messages for monitored topics',
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
            label: 'Increased monitoring',
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
                      child: const Text('Clear all', style: TextStyle(fontSize: 12)),
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
                      IconButton(onPressed: () => vm.removeIncreasedMonitoringTopic(topic), icon: const Icon(Icons.close_rounded, size: 14), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24), splashRadius: 14, tooltip: 'Remove'),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
