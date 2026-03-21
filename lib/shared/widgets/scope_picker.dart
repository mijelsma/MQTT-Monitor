import 'package:flutter/material.dart';

import '../../models/broker_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// Uppercase section label used above scope pickers and similar groups.
Widget sectionLabel(BuildContext context, String label) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 2),
  child: Text(
    label.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: context.tokens.textSecondary),
  ),
);

/// A selectable pill that represents one scope choice (e.g. "Global" vs "Specific brokers").
class ScopeOption extends StatelessWidget {
  const ScopeOption({super.key, this.margin, required this.label, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  final EdgeInsetsGeometry? margin;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cs = Theme.of(context).colorScheme;
    Widget content = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? tokens.primary : tokens.border, width: selected ? 1.5 : 1.0),
          color: selected ? tokens.primary.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? tokens.primary : tokens.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, size: 16, color: tokens.primary),
          ],
        ),
      ),
    );
    if (margin != null) content = Padding(padding: margin!, child: content);
    return content;
  }
}

/// A list of brokers with checkboxes for multi-selection.
class BrokerCheckboxList extends StatelessWidget {
  const BrokerCheckboxList({super.key, required this.brokers, required this.selectedIds, required this.onToggle});

  final List<BrokerEntry> brokers;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cs = Theme.of(context).colorScheme;

    if (brokers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('No brokers configured.', style: TextStyle(fontSize: 12, color: tokens.textTertiary)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < brokers.length; i++) ...[
            if (i > 0) Divider(height: 1, color: tokens.border),
            InkWell(
              onTap: () => onToggle(brokers[i].id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.brokerGradientFor(brokers[i].colorIndex), begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.dns_rounded, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brokers[i].name,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface),
                          ),
                          Text(brokers[i].displayAddress, style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(selectedIds.contains(brokers[i].id) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 20, color: selectedIds.contains(brokers[i].id) ? tokens.primary : tokens.textTertiary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
