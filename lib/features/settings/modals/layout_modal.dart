import 'package:flutter/material.dart';

import '../../../models/broker_entry.dart';
import '../../../models/dashboard_layout.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

Future<DashboardLayout?> showLayoutModal(BuildContext context, {DashboardLayout? layout, required List<BrokerEntry> brokers, VoidCallback? onDelete}) {
  return showDialog<DashboardLayout>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _LayoutModal(layout: layout, brokers: brokers, onDelete: onDelete),
  );
}

class _LayoutModal extends StatefulWidget {
  const _LayoutModal({this.layout, required this.brokers, this.onDelete});

  final DashboardLayout? layout;
  final List<BrokerEntry> brokers;
  final VoidCallback? onDelete;

  @override
  State<_LayoutModal> createState() => _LayoutModalState();
}

class _LayoutModalState extends State<_LayoutModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late int _colorIndex;
  late bool _isGlobal;
  late Set<String> _selectedBrokerIds;

  bool get _isEditing => widget.layout != null;

  @override
  void initState() {
    super.initState();
    final l = widget.layout;
    _title = TextEditingController(text: l?.title ?? '');
    _colorIndex = l?.colorIndex ?? 0;
    _isGlobal = l?.isGlobal ?? true;
    _selectedBrokerIds = {...l?.brokerIds ?? []};
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final brokerIds = _isGlobal ? <String>[] : _selectedBrokerIds.toList();
    if (_isEditing) {
      Navigator.pop(context, widget.layout!.copyWith(title: _title.text.trim(), colorIndex: _colorIndex, brokerIds: brokerIds));
    } else {
      final id = 'layout_${DateTime.now().millisecondsSinceEpoch}';
      Navigator.pop(context, DashboardLayout(id: id, title: _title.text.trim(), colorIndex: _colorIndex, brokerIds: brokerIds));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return UiModalScaffold(
      title: _isEditing ? 'Edit Layout' : 'New Layout',
      isEditing: _isEditing,
      onDelete: widget.onDelete != null
          ? () {
              Navigator.pop(context);
              widget.onDelete!();
            }
          : null,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      submitLabel: 'Save',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel(context, 'Details'),
            const VSpacer(10),
            UiField(label: 'Name', controller: _title, hint: 'e.g. Sensors', textInputAction: TextInputAction.done, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null, onFieldSubmitted: (_) => _submit()),
            const VSpacer(14),
            ColorPickerField(
              label: 'Color',
              value: AppColors.brokerColorOptions[_colorIndex],
              onChanged: (c) {
                final idx = AppColors.brokerColorOptions.indexWhere((o) => o.toARGB32() == c.toARGB32());
                if (idx >= 0) setState(() => _colorIndex = idx);
              },
            ),
            const VSpacer(20),
            _sectionLabel(context, 'Scope'),
            const VSpacer(10),
            _ScopeOption(label: 'Global', subtitle: 'Use dashboard across all brokers', icon: Icons.public_rounded, selected: _isGlobal, onTap: () => setState(() => _isGlobal = true), tokens: tokens),
            const VSpacer(6),
            _ScopeOption(label: 'Selected brokers', subtitle: 'Only for selected brokers', icon: Icons.dns_rounded, selected: !_isGlobal, onTap: () => setState(() => _isGlobal = false), tokens: tokens),
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
