import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../models/broker_entry.dart';
import '../../../models/dashboard_layout.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/scope_picker.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../theme/app_colors.dart';

Future<DashboardLayout?> showCreateDashboardDialog(BuildContext context, {DashboardLayout? dashboard, required List<BrokerEntry> brokers, VoidCallback? onDelete}) {
  return showDialog<DashboardLayout>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _CreateDashboardDialog(dashboard: dashboard, brokers: brokers, onDelete: onDelete),
  );
}

class _CreateDashboardDialog extends StatefulWidget {
  const _CreateDashboardDialog({this.dashboard, required this.brokers, this.onDelete});

  final DashboardLayout? dashboard;
  final List<BrokerEntry> brokers;
  final VoidCallback? onDelete;

  @override
  State<_CreateDashboardDialog> createState() => _CreateDashboardDialogState();
}

class _CreateDashboardDialogState extends State<_CreateDashboardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late Color _color;
  late bool _isGlobal;
  late Set<String> _selectedBrokerIds;

  bool get _isEditing => widget.dashboard != null;

  @override
  void initState() {
    super.initState();
    final l = widget.dashboard;
    _title = TextEditingController(text: l?.title ?? '');
    _color = AppColors.brokerColorOptions[l?.colorIndex ?? 0];
    _isGlobal = l?.isGlobal ?? true;
    _selectedBrokerIds = {...l?.brokerIds ?? []};
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.pop(context);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final brokerIds = _isGlobal ? <String>[] : _selectedBrokerIds.toList();
    if (_isEditing) {
      Navigator.pop(context, widget.dashboard!.copyWith(title: _title.text.trim(), colorIndex: AppColors.colorIndex(_color), brokerIds: brokerIds));
    } else {
      final id = 'layout_${DateTime.now().millisecondsSinceEpoch}';
      Navigator.pop(context, DashboardLayout(id: id, title: _title.text.trim(), colorIndex: AppColors.colorIndex(_color), brokerIds: brokerIds));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return UiModalScaffold(
      title: _isEditing ? s.dashboardDialogEditTitle : s.dashboardDialogNewTitle,
      isEditing: _isEditing,
      onDelete: widget.onDelete != null
          ? () {
              Navigator.pop(context);
              widget.onDelete!();
            }
          : null,
      onCancel: _cancel,
      onSubmit: _submit,
      submitLabel: s.save,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dashboard details section: name and color.
            sectionLabel(context, s.dashboardDialogSectionDetails),
            UiField(margin: const EdgeInsets.only(top: 20), label: s.dashboardDialogFieldName, controller: _title, hint: 'e.g. Sensors', textInputAction: TextInputAction.done, validator: (v) => (v == null || v.trim().isEmpty) ? s.dashboardDialogValidateName : null, onFieldSubmitted: (_) => _submit()),
            ColorPickerField(margin: const EdgeInsets.only(top: 14, bottom: 20), label: s.dashboardPanelColor, value: _color, onChanged: (c) => setState(() => _color = c)),

            // Scope section: global or selected brokers.
            sectionLabel(context, s.dashboardDialogSectionScope),
            ScopeOption(margin: const EdgeInsets.only(top: 20), label: s.scopeGlobal, subtitle: s.dashboardDialogScopeGlobalSubtitle, icon: Icons.public_rounded, selected: _isGlobal, onTap: () => setState(() => _isGlobal = true)),
            ScopeOption(margin: const EdgeInsets.only(top: 6), label: s.scopeSelectedBrokers, subtitle: s.dashboardDialogScopeBrokersSubtitle, icon: Icons.dns_rounded, selected: !_isGlobal, onTap: () => setState(() => _isGlobal = false)),

            // If "Selected brokers" is chosen, show the broker checklist.
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
