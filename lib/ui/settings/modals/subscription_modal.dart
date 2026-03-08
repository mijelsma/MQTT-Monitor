import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/subscription_entry.dart';
import '../../elements/ui_field.dart';
import '../../elements/ui_modal_scaffold.dart';
import '../../widgets/spacers.dart';
import '../../widgets/qos_tag.dart';

// ── Input decoration shared across all form fields in this modal ──────────────
InputDecoration _inputDecoration(BuildContext context, {required Color accent, String? hint, Widget? suffixIcon}) {
  final tokens = context.tokens;
  const radius = BorderRadius.all(Radius.circular(10));
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffixIcon,
    isDense: true,
    filled: true,
    fillColor: tokens.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: tokens.border, width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: tokens.border, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: accent, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.error500, width: 1.0),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.error500, width: 1.5),
    ),
  );
}

/// Opens the add / edit subscription dialog.
/// Returns the saved [SubscriptionEntry], or `null` if cancelled.
Future<SubscriptionEntry?> showSubscriptionModal(BuildContext context, {SubscriptionEntry? entry}) {
  return showDialog<SubscriptionEntry>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => SubscriptionModal(entry: entry),
  );
}

class SubscriptionModal extends StatefulWidget {
  const SubscriptionModal({super.key, this.entry});

  final SubscriptionEntry? entry;

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topic;
  late final TextEditingController _name;
  late int _qos;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _topic = TextEditingController(text: widget.entry?.topic ?? '');
    _name = TextEditingController(text: widget.entry?.name ?? '');
    _qos = widget.entry?.qos ?? 0;
  }

  @override
  void dispose() {
    _topic.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, SubscriptionEntry(topic: _topic.text.trim(), qos: _qos, name: _name.text.trim().isEmpty ? null : _name.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.primary;

    return UiModalScaffold(
      title: _isEditing ? 'Edit Subscription' : 'Add Subscription',
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      submitLabel: _isEditing ? 'Save' : 'Add',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiField(
              label: 'Topic Filter',
              child: TextFormField(
                controller: _topic,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: _inputDecoration(context, accent: accent, hint: 'e.g. home/+/temperature or sensors/#'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a topic filter' : null,
              ),
            ),
            VSpacer(14),
            UiField(
              label: 'Display Name',
              optional: true,
              child: TextFormField(
                controller: _name,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _inputDecoration(context, accent: accent, hint: 'Optional friendly name'),
              ),
            ),
            VSpacer(18),
            UiField(
              label: 'Quality of Service',
              child: _QosSelector(value: _qos, accent: accent, onChanged: (v) => setState(() => _qos = v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QosSelector extends StatelessWidget {
  const _QosSelector({required this.value, required this.accent, required this.onChanged});

  final int value;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      children: List.generate(3, (qos) {
        final selected = qos == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: qos < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onChanged(qos),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.12) : tokens.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? accent : tokens.border, width: selected ? 1.5 : 0.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'QoS $qos',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? accent : tokens.textSecondary),
                    ),
                    VSpacer(2),
                    Text(
                      qosLabel(qos),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9.5, color: tokens.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
