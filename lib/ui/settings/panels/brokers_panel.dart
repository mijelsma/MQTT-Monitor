import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/broker_entry.dart';
import '../modals/broker_modal.dart';
import '../../elements/ui_empty_state.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';
import '../../elements/ui_sortable_row.dart';

class BrokersPanel extends StatefulWidget {
  const BrokersPanel({super.key});

  @override
  State<BrokersPanel> createState() => _BrokersPanelState();
}

class _BrokersPanelState extends State<BrokersPanel> {
  final List<BrokerEntry> _brokers = [
    const BrokerEntry(id: '1', name: 'Broker Placeholder 1', host: '192.168.1.100', port: 1883),
    const BrokerEntry(id: '2', name: 'Broker Placeholder 2', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '3', name: 'Broker Placeholder 3', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '4', name: 'Broker Placeholder 4', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '5', name: 'Broker Placeholder 5', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '6', name: 'Broker Placeholder 6', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '7', name: 'Broker Placeholder 7', host: '192.168.1.100', port: 1883),
    const BrokerEntry(id: '8', name: 'Broker Placeholder 8', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '9', name: 'Broker Placeholder 9', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '10', name: 'Broker Placeholder 10', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '11', name: 'Broker Placeholder 11', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '12', name: 'Broker Placeholder 12', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '13', name: 'Broker Placeholder 13', host: '192.168.1.100', port: 1883),
    const BrokerEntry(id: '14', name: 'Broker Placeholder 14', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '15', name: 'Broker Placeholder 15', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '16', name: 'Broker Placeholder 16', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '17', name: 'Broker Placeholder 17', host: 'broker.example.com', port: 8883, useSSL: true),
    const BrokerEntry(id: '18', name: 'Broker Placeholder 18', host: 'broker.example.com', port: 8883, useSSL: true),
  ];

  Future<void> _openAdd() async {
    final entry = await showBrokerModal(context);
    if (entry == null) return;
    setState(() => _brokers.add(entry));
  }

  Future<void> _openEdit(BrokerEntry broker) async {
    final updated = await showBrokerModal(context, broker: broker, onDelete: () => _delete(broker.id));
    if (updated == null) return;
    setState(() {
      final i = _brokers.indexWhere((b) => b.id == updated.id);
      if (i != -1) _brokers[i] = updated;
    });
  }

  void _delete(String id) => setState(() => _brokers.removeWhere((b) => b.id == id));

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _brokers.removeAt(oldIndex);
      _brokers.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return UiPanelScaffold(
      title: 'Brokers',
      description: 'Configure MQTT brokers.',
      children: [
        // Connections section
        if (_brokers.isEmpty)
          const UiEmptyState(icon: Icons.dns_outlined, title: 'No brokers yet', message: "Tap 'Add Broker' to create your first broker.")
        else
          UiSection(
            label: 'Connections',
            sortable: true,
            onReorder: _reorder,
            children: [
              for (int i = 0; i < _brokers.length; i++)
                UiSortableRow(
                  key: ValueKey(_brokers[i].id),
                  index: i,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.brokerGradient),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.dns_rounded, size: 18, color: Colors.white),
                  ),
                  title: _brokers[i].name,
                  subtitle: _brokers[i].displayAddress,
                  onTap: () => _openEdit(_brokers[i]),
                  onDelete: () => _delete(_brokers[i].id),
                ),
            ],
          ),

        // Add broker button
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FilledButton.icon(
              onPressed: _openAdd,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Broker'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), textStyle: theme.textTheme.labelLarge),
            ),
          ),
        ),
      ],
    );
  }
}
