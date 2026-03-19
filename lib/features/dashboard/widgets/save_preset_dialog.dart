import 'package:flutter/material.dart';

import '../../../shared/widgets/color_picker_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Dialog for saving the current dashboard as a new layout.
///
/// Returns a record of (title, brokerIds, colorIndex) or null if cancelled.
Future<({String title, List<String> brokerIds, int colorIndex})?> showSaveLayoutDialog(BuildContext context, {required String brokerName, required String brokerId}) {
  return showDialog<({String title, List<String> brokerIds, int colorIndex})>(
    context: context,
    builder: (_) => _SaveLayoutDialog(brokerName: brokerName, brokerId: brokerId),
  );
}

class _SaveLayoutDialog extends StatefulWidget {
  const _SaveLayoutDialog({required this.brokerName, required this.brokerId});

  final String brokerName;
  final String brokerId;

  @override
  State<_SaveLayoutDialog> createState() => _SaveLayoutDialogState();
}

class _SaveLayoutDialogState extends State<_SaveLayoutDialog> {
  final _titleController = TextEditingController();
  bool _isBrokerScoped = false;
  int _colorIndex = 0;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Save layout'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Layout name',
                hintText: 'e.g. Home sensors',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: TextStyle(fontSize: 14, color: tokens.textPrimary),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ColorPickerField(
              label: 'Color',
              value: AppColors.brokerColorOptions[_colorIndex],
              onChanged: (c) {
                final idx = AppColors.brokerColorOptions.indexWhere((o) => o.toARGB32() == c.toARGB32());
                if (idx >= 0) setState(() => _colorIndex = idx);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Scope',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
            ),
            const SizedBox(height: 8),
            _ScopeOption(label: 'Global', subtitle: 'Available across all brokers', icon: Icons.public_rounded, selected: !_isBrokerScoped, onTap: () => setState(() => _isBrokerScoped = false), tokens: tokens, cs: cs),
            const SizedBox(height: 6),
            _ScopeOption(label: widget.brokerName, subtitle: 'Only for this broker', icon: Icons.dns_rounded, selected: _isBrokerScoped, onTap: () => setState(() => _isBrokerScoped = true), tokens: tokens, cs: cs),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: tokens.textSecondary)),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop((title: title, brokerIds: _isBrokerScoped ? [widget.brokerId] : <String>[], colorIndex: _colorIndex));
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({required this.label, required this.subtitle, required this.icon, required this.selected, required this.onTap, required this.tokens, required this.cs});

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final AppTokens tokens;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
  }
}
