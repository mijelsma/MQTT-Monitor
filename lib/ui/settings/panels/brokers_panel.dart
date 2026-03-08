import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/broker_entry.dart';
import '../modals/broker_modal.dart';
import '../widgets/section_header.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';
import '../../widgets/spacers.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brokers', style: theme.textTheme.headlineSmall),
          VSpacer(6),
          Text('Configure MQTT brokers.', style: theme.textTheme.bodySmall),
          VSpacer(20),
          const SectionHeader(label: 'Connections'),
          VSpacer(8),

          // No brokers configured. Show empty state with prompt to add one.
          if (_brokers.isEmpty)
            const _EmptyBrokers()
          // Broker list with drag-to-reorder, tap-to-edit, and delete
          else
            _BrokerList(brokers: _brokers, onTap: _openEdit, onDelete: _delete, onReorder: _reorder),

          // Add Broker button at the end of the list
          VSpacer(20),
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
      ),
    );
  }
}

class _BrokerList extends StatelessWidget {
  const _BrokerList({required this.brokers, required this.onTap, required this.onDelete, required this.onReorder});

  final List<BrokerEntry> brokers;
  final ValueChanged<BrokerEntry> onTap;
  final ValueChanged<String> onDelete;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, __) => Material(color: Colors.transparent, child: child),
          onReorder: onReorder,
          itemCount: brokers.length,
          itemBuilder: (context, index) {
            final broker = brokers[index];
            return _BrokerRow(key: ValueKey(broker.id), broker: broker, index: index, isLast: index == brokers.length - 1, onTap: () => onTap(broker), onDelete: () => onDelete(broker.id));
          },
        ),
      ],
    );
  }
}

class _EmptyBrokers extends StatelessWidget {
  const _EmptyBrokers();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.dns_outlined, size: 50, color: context.tokens.textTertiary),
            VSpacer(12),
            Text('No brokers yet', style: theme.textTheme.bodyMedium),
            VSpacer(4),
            Text("Tap 'Add Broker' to create your first broker.", style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BrokerRow extends StatelessWidget {
  const _BrokerRow({super.key, required this.broker, required this.index, required this.isLast, required this.onTap, required this.onDelete});

  final BrokerEntry broker;
  final int index;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final secondary = context.tokens.textSecondary;

    return SettingsRow(
      isLast: isLast,
      dividerIndent: 62,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.drag_indicator_rounded, size: 20, color: context.tokens.textTertiary),
                ),
              ),

              // Icon chip
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.brokerGradient),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.dns_rounded, size: 18, color: Colors.white),
              ),
              HSpacer(12),

              // Name + address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(broker.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    VSpacer(2),
                    Text(broker.displayAddress, style: TextStyle(fontSize: 11.5, color: secondary)),
                  ],
                ),
              ),

              // Delete
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error500),
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                onPressed: onDelete,
              ),

              // Chevron
              Icon(Icons.chevron_right_rounded, size: 18, color: context.tokens.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
