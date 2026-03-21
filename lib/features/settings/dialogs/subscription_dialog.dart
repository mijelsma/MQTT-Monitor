import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../models/subscription_entry.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../shared/widgets/ui_segment_row.dart';

Future<SubscriptionEntry?> showSubscriptionDialog(BuildContext context, {SubscriptionEntry? entry}) {
  return showDialog<SubscriptionEntry>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => SubscriptionDialog(entry: entry),
  );
}

class SubscriptionDialog extends StatefulWidget {
  const SubscriptionDialog({super.key, this.entry});

  final SubscriptionEntry? entry;

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
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
    final s = S.of(context);
    return UiModalScaffold(
      title: _isEditing ? s.subscriptionDialogEditTitle : s.subscriptionDialogAddTitle,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      submitLabel: _isEditing ? s.save : s.add,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiField(label: s.subscriptionDialogFieldTopicFilter, controller: _topic, hint: 'e.g. home/+/sensor/#', textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? s.subscriptionDialogValidateTopicFilter : null),
            UiField(margin: const EdgeInsets.only(top: 14), label: s.subscriptionDialogFieldDisplayName, optional: true, controller: _name, hint: s.subscriptionDialogHintDisplayName, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _submit()),
            const VSpacer(18),
            UiSegmentRow<int>(
              label: s.subscriptionDialogQoSLabel,
              options: [
                UiSegmentOption(value: 0, label: s.subscriptionDialogQoS0Label, description: s.subscriptionDialogQoS0Description),
                UiSegmentOption(value: 1, label: s.subscriptionDialogQoS1Label, description: s.subscriptionDialogQoS1Description),
                UiSegmentOption(value: 2, label: s.subscriptionDialogQoS2Label, description: s.subscriptionDialogQoS2Description),
              ],
              value: _qos,
              onChanged: (v) => setState(() => _qos = v),
            ),
          ],
        ),
      ),
    );
  }
}
