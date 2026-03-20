import 'package:flutter/material.dart';

import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/scope_picker.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Dialog for saving the current dashboard.
///
/// Returns a record of (title, brokerIds, colorIndex) or null if cancelled.
Future<({String title, List<String> brokerIds, int colorIndex})?> showSaveDashboardDialog(BuildContext context, {required String brokerName, required String brokerId}) {
  return showDialog<({String title, List<String> brokerIds, int colorIndex})>(
    context: context,
    builder: (_) => _SaveDashboardDialog(brokerName: brokerName, brokerId: brokerId),
  );
}

class _SaveDashboardDialog extends StatefulWidget {
  const _SaveDashboardDialog({required this.brokerName, required this.brokerId});

  final String brokerName;
  final String brokerId;

  @override
  State<_SaveDashboardDialog> createState() => _SaveDashboardDialogState();
}

class _SaveDashboardDialogState extends State<_SaveDashboardDialog> {
  final _titleController = TextEditingController();
  bool _isBrokerScoped = false;
  Color _color = AppColors.brokerColorOptions[0];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AlertDialog(
      title: const Text('Save dashboard'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiField(label: 'Dashboard name', controller: _titleController, autofocus: true, hint: 'e.g. Sensors Values', onFieldSubmitted: (_) => _submit()),
            ColorPickerField(margin: const EdgeInsets.only(top: 16), label: 'Color', value: _color, onChanged: (c) => setState(() => _color = c)),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Scope',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
            ),
            ScopeOption(margin: const EdgeInsets.only(top: 8), label: 'Global', subtitle: 'Available across all brokers', icon: Icons.public_rounded, selected: !_isBrokerScoped, onTap: () => setState(() => _isBrokerScoped = false)),
            ScopeOption(margin: const EdgeInsets.only(top: 6), label: widget.brokerName, subtitle: 'Only for this broker', icon: Icons.dns_rounded, selected: _isBrokerScoped, onTap: () => setState(() => _isBrokerScoped = true)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: Text('Cancel', style: TextStyle(color: tokens.textSecondary)),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop((title: title, brokerIds: _isBrokerScoped ? [widget.brokerId] : <String>[], colorIndex: AppColors.colorIndex(_color)));
  }
}
