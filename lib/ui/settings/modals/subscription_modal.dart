import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/subscription_entry.dart';
import '../widgets/field_label.dart';
import '../widgets/modal_input_decoration.dart';
import '../../widgets/spacers.dart';
import '../../widgets/qos_tag.dart';

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
    final theme = Theme.of(context);
    final accent = context.tokens.primary;
    final cardColor = context.tokens.surface;
    final tokens = context.tokens;

    return Dialog(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Text(_isEditing ? 'Edit Subscription' : 'Add Subscription', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

                VSpacer(20),

                // Topic filter
                const FieldLabel(label: 'Topic Filter'),
                VSpacer(6),
                TextFormField(
                  controller: _topic,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  decoration: modalInputDecoration(context, accent: accent, hint: 'e.g. home/+/temperature or sensors/#'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a topic filter' : null,
                ),
                VSpacer(14),

                // Display name
                const FieldLabel(label: 'Display Name', optional: true),
                VSpacer(6),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: modalInputDecoration(context, accent: accent, hint: 'Optional friendly name'),
                ),
                VSpacer(18),

                // QoS selector
                const FieldLabel(label: 'Quality of Service'),
                VSpacer(10),
                _QosSelector(value: _qos, accent: accent, onChanged: (v) => setState(() => _qos = v)),
                VSpacer(20),

                // Actions
                Row(
                  children: [
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    HSpacer(8),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
                      child: Text(_isEditing ? 'Save' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
