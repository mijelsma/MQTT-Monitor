import 'package:flutter/material.dart';

import '../../../models/broker_entry.dart';
import '../../../models/environment_variable.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Shows a dialog for creating or editing an environment variable.
///
/// Returns the resulting [EnvironmentVariable] on save, or null if dismissed.
Future<EnvironmentVariable?> showVariableModal(BuildContext context, {EnvironmentVariable? variable, Set<String> existingNames = const {}, List<BrokerEntry> brokers = const [], VoidCallback? onDelete}) {
  return showDialog<EnvironmentVariable>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _VariableModal(variable: variable, existingNames: existingNames, brokers: brokers, onDelete: onDelete),
  );
}

class _VariableModal extends StatefulWidget {
  const _VariableModal({this.variable, required this.existingNames, required this.brokers, this.onDelete});

  final EnvironmentVariable? variable;
  final Set<String> existingNames;
  final List<BrokerEntry> brokers;
  final VoidCallback? onDelete;

  @override
  State<_VariableModal> createState() => _VariableModalState();
}

class _VariableModalState extends State<_VariableModal> {
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
    _options = widget.variable?.options.map((o) => _OptionEntry(label: TextEditingController(text: o.label), value: TextEditingController(text: o.value))).toList() ?? [];
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
    final options = _options
        .where((o) => o.label.text.trim().isNotEmpty && o.value.text.trim().isNotEmpty)
        .map((o) => EnvironmentVariableOption(label: o.label.text.trim(), value: o.value.text.trim()))
        .toList();
    Navigator.pop(context, EnvironmentVariable(name: name, brokerIds: _isGlobal ? [] : _selectedBrokerIds.toList(), options: options));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Form(
      key: _formKey,
      child: UiModalScaffold(
        title: _isEditing ? 'Edit Variable' : 'Add Variable',
        isEditing: _isEditing,
        onDelete: widget.onDelete != null
            ? () {
                widget.onDelete!();
                Navigator.pop(context);
              }
            : null,
        onCancel: () => Navigator.pop(context),
        onSubmit: _submit,
        submitLabel: _isEditing ? 'Save' : 'Add',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiField(
              label: 'Name',
              controller: _nameController,
              hint: 'e.g. SENSOR_ID',
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'Enter a variable name';
                if (widget.existingNames.contains(trimmed)) return 'A variable with this name already exists';
                if (trimmed.contains(RegExp(r'[\[\]\s]'))) return 'Name cannot contain spaces or brackets';
                return null;
              },
            ),
            const VSpacer(6),
            Text(
              'Use [${ _nameController.text.trim().isEmpty ? 'NAME' : _nameController.text.trim()}] in a chart topic to reference this variable.',
              style: TextStyle(fontSize: 11, color: tokens.textTertiary),
            ),

            const VSpacer(24),
            Row(
              children: [
                Text('Pre-defined Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textPrimary)),
                const SizedBox(width: 8),
                Text('optional', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
              ],
            ),
            const VSpacer(4),
            Text(
              'Options let you pick from a list in the dashboard instead of typing each time.',
              style: TextStyle(fontSize: 11, color: tokens.textTertiary),
            ),
            const VSpacer(12),

            for (int i = 0; i < _options.length; i++) ...[
              _OptionRow(
                entry: _options[i],
                onRemove: () => _removeOption(i),
              ),
              const VSpacer(8),
            ],

            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Option'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _addOption,
            ),

            const VSpacer(24),
            _sectionLabel(context, 'Scope'),
            const VSpacer(10),
            _ScopeOption(
              label: 'Global',
              subtitle: 'Available across all brokers',
              icon: Icons.public_rounded,
              selected: _isGlobal,
              onTap: () => setState(() => _isGlobal = true),
              tokens: tokens,
            ),
            const VSpacer(6),
            _ScopeOption(
              label: 'Specific brokers',
              subtitle: 'Only for selected brokers',
              icon: Icons.dns_rounded,
              selected: !_isGlobal,
              onTap: () => setState(() => _isGlobal = false),
              tokens: tokens,
            ),
            if (!_isGlobal) ...[  
              const VSpacer(12),
              _BrokerCheckboxList(
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

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: entry.label,
            decoration: InputDecoration(
              hintText: 'Display name',
              isDense: true,
              filled: true,
              fillColor: tokens.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: tokens.border, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: tokens.border, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: tokens.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: entry.value,
            decoration: InputDecoration(
              hintText: 'Value',
              isDense: true,
              filled: true,
              fillColor: tokens.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: tokens.border, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: tokens.border, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: tokens.primary, width: 1.5)),
            ),
          ),
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

// ── Scope widgets (shared pattern with preset_modal) ────────────────────

Widget _sectionLabel(BuildContext context, String label) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 2),
  child: Text(
    label.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: context.tokens.textSecondary),
  ),
);

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({required this.label, required this.subtitle, required this.icon, required this.selected, required this.onTap, required this.tokens});

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
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

class _BrokerCheckboxList extends StatelessWidget {
  const _BrokerCheckboxList({required this.brokers, required this.selectedIds, required this.onToggle});

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
                          Text(brokers[i].name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
                          Text(brokers[i].displayAddress, style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(
                      selectedIds.contains(brokers[i].id) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: selectedIds.contains(brokers[i].id) ? tokens.primary : tokens.textTertiary,
                    ),
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
