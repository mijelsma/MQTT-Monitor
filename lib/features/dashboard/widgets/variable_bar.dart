import 'package:flutter/material.dart';

import '../../../models/environment_variable.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../dashboard_view_model.dart';

/// A horizontal bar shown at the top of the dashboard that lets the user
/// set the current value for each environment variable.
class VariableBar extends StatelessWidget {
  const VariableBar({super.key, required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final variables = vm.environmentVariables;
    if (variables.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;
    final values = vm.variableValues;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border, width: 0.5)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.data_object_rounded, size: 16, color: tokens.textSecondary),
          for (final variable in variables) _VariableChip(variable: variable, currentValue: values[variable.name] ?? '', onChanged: (v) => vm.setVariableValue(variable.name, v)),
        ],
      ),
    );
  }
}

class _VariableChip extends StatelessWidget {
  const _VariableChip({required this.variable, required this.currentValue, required this.onChanged});

  final EnvironmentVariable variable;
  final String currentValue;
  final ValueChanged<String> onChanged;

  void _showPicker(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _VariablePickerDialog(variable: variable, currentValue: currentValue),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasValue = currentValue.isNotEmpty;

    // Find the matching option label if there is one.
    String? optionLabel;
    for (final opt in variable.options) {
      if (opt.value == currentValue) {
        optionLabel = opt.label;
        break;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasValue ? tokens.primary.withValues(alpha: 0.08) : tokens.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasValue ? tokens.primary.withValues(alpha: 0.3) : tokens.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              variable.name,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
            ),
            if (hasValue) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('=', style: TextStyle(fontSize: 12, color: tokens.textTertiary)),
              ),
              Text(
                optionLabel ?? currentValue,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.primary),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(Icons.edit_rounded, size: 12, color: tokens.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog for picking/entering a variable value. Shows predefined options
/// as selectable chips and also offers a free-text input.
class _VariablePickerDialog extends StatefulWidget {
  const _VariablePickerDialog({required this.variable, required this.currentValue});

  final EnvironmentVariable variable;
  final String currentValue;

  @override
  State<_VariablePickerDialog> createState() => _VariablePickerDialogState();
}

class _VariablePickerDialogState extends State<_VariablePickerDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final options = widget.variable.options;

    return Dialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set ${widget.variable.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              if (options.isNotEmpty) ...[
                Text(
                  'Options',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final opt in options)
                      _OptionChip(
                        label: opt.label,
                        subtitle: opt.value,
                        selected: _controller.text == opt.value,
                        onTap: () {
                          _controller.text = opt.value;
                          Navigator.pop(context, opt.value);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: tokens.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or type a value', style: TextStyle(fontSize: 11, color: tokens.textTertiary)),
                    ),
                    Expanded(child: Divider(color: tokens.border)),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _controller,
                autofocus: options.isEmpty,
                decoration: InputDecoration(
                  hintText: 'Enter value…',
                  isDense: true,
                  filled: true,
                  fillColor: tokens.inputFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tokens.border, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tokens.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tokens.primary, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(backgroundColor: tokens.primary, foregroundColor: tokens.onPrimary),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label, required this.subtitle, required this.selected, required this.onTap});

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.primary.withValues(alpha: 0.12) : tokens.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? tokens.primary : tokens.border, width: selected ? 1.5 : 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? tokens.primary : tokens.textPrimary),
            ),
            if (subtitle != label) ...[const SizedBox(height: 1), Text(subtitle, style: TextStyle(fontSize: 10.5, color: tokens.textTertiary))],
          ],
        ),
      ),
    );
  }
}
