import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../models/broker_entry.dart';
import '../../../models/environment_variable.dart';
import '../../../shared/widgets/scope_picker.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Shows a dialog for creating or editing an environment variable.
///
/// Returns the resulting [EnvironmentVariable] on save, or null if dismissed.
Future<EnvironmentVariable?> showVariableDialog(BuildContext context, {EnvironmentVariable? variable, Set<String> existingNames = const {}, List<BrokerEntry> brokers = const [], VoidCallback? onDelete}) {
  return showDialog<EnvironmentVariable>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _VariableDialog(variable: variable, existingNames: existingNames, brokers: brokers, onDelete: onDelete),
  );
}

class _VariableDialog extends StatefulWidget {
  const _VariableDialog({this.variable, required this.existingNames, required this.brokers, this.onDelete});

  final EnvironmentVariable? variable;
  final Set<String> existingNames;
  final List<BrokerEntry> brokers;
  final VoidCallback? onDelete;

  @override
  State<_VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<_VariableDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<_OptionEntry> _options;
  late bool _isGlobal;
  late Set<String> _selectedBrokerIds;

  bool get _isEditing => widget.variable != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.variable?.name ?? '');
    _options =
        widget.variable?.options
            .map(
              (o) => _OptionEntry(
                label: TextEditingController(text: o.label),
                value: TextEditingController(text: o.value),
              ),
            )
            .toList() ??
        [];
    _isGlobal = widget.variable?.isGlobal ?? true;
    _selectedBrokerIds = {...?widget.variable?.brokerIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final o in _options) {
      o.label.dispose();
      o.value.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add(_OptionEntry(label: TextEditingController(), value: TextEditingController()));
    });
  }

  void _removeOption(int index) {
    final entry = _options.removeAt(index);
    entry.label.dispose();
    entry.value.dispose();
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final options = _options.where((o) => o.label.text.trim().isNotEmpty && o.value.text.trim().isNotEmpty).map((o) => EnvironmentVariableOption(label: o.label.text.trim(), value: o.value.text.trim())).toList();
    Navigator.pop(context, EnvironmentVariable(name: name, brokerIds: _isGlobal ? [] : _selectedBrokerIds.toList(), options: options));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = S.of(context);

    return Form(
      key: _formKey,
      child: UiModalScaffold(
        title: _isEditing ? s.variableDialogEditTitle : s.variableDialogAddTitle,
        isEditing: _isEditing,
        onDelete: widget.onDelete != null
            ? () {
                widget.onDelete!();
                Navigator.pop(context);
              }
            : null,
        onCancel: () => Navigator.pop(context),
        onSubmit: _submit,
        submitLabel: _isEditing ? s.save : s.add,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiField(
              label: s.variableDialogFieldName,
              controller: _nameController,
              hint: 'e.g. SENSOR_ID',
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return s.variableDialogValidateName;
                if (widget.existingNames.contains(trimmed)) return s.variableDialogNameExists;
                if (trimmed.contains(RegExp(r'[\s{}\$]'))) return s.variableDialogNameInvalid;
                return null;
              },
            ),
            const VSpacer(6),
            Text('Use \${${_nameController.text.trim().isEmpty ? 'NAME' : _nameController.text.trim()}} in a chart topic to reference this variable.', style: TextStyle(fontSize: 11, color: tokens.textTertiary)),

            const VSpacer(24),
            Row(
              children: [
                Text(
                  s.variableDialogPredefinedOptions,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textPrimary),
                ),
                const SizedBox(width: 8),
                Text(s.optional, style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
              ],
            ),
            const VSpacer(4),
            Text(s.variableDialogOptionsHint, style: TextStyle(fontSize: 11, color: tokens.textTertiary)),
            const VSpacer(12),

            for (int i = 0; i < _options.length; i++) ...[_OptionRow(entry: _options[i], onRemove: () => _removeOption(i)), const VSpacer(8)],

            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(s.variableDialogAddOption),
              style: TextButton.styleFrom(foregroundColor: tokens.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              onPressed: _addOption,
            ),

            const VSpacer(24),
            sectionLabel(context, s.dashboardDialogSectionScope),
            const VSpacer(10),
            ScopeOption(label: s.scopeGlobal, subtitle: s.variableDialogScopeGlobalSubtitle, icon: Icons.public_rounded, selected: _isGlobal, onTap: () => setState(() => _isGlobal = true)),
            const VSpacer(6),
            ScopeOption(label: s.scopeSpecificBrokers, subtitle: s.variableDialogScopeBrokersSubtitle, icon: Icons.dns_rounded, selected: !_isGlobal, onTap: () => setState(() => _isGlobal = false)),
            if (!_isGlobal) ...[
              const VSpacer(12),
              BrokerCheckboxList(
                brokers: widget.brokers,
                selectedIds: _selectedBrokerIds,
                onToggle: (id) => setState(() {
                  if (_selectedBrokerIds.contains(id)) {
                    _selectedBrokerIds.remove(id);
                  } else {
                    _selectedBrokerIds.add(id);
                  }
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionEntry {
  _OptionEntry({required this.label, required this.value});
  final TextEditingController label;
  final TextEditingController value;
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.entry, required this.onRemove});

  final _OptionEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = S.of(context);

    InputDecoration fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
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
    );

    return Row(
      children: [
        Expanded(
          child: TextFormField(controller: entry.label, decoration: fieldDecoration(s.variableDialogDisplayName)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(controller: entry.value, decoration: fieldDecoration(s.variableDialogValue)),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 18, color: tokens.textSecondary),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(6),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
