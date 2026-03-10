import 'package:flutter/material.dart';
import '../../../generated/l10n.dart';
import '../models/subscription_entry.dart';
import '../../elements/ui_field.dart';
import '../../elements/ui_modal_scaffold.dart';
import '../../elements/ui_segment_row.dart';
import '../../widgets/spacers.dart';

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
    final s = S.of(context);
    return UiModalScaffold(
      title: _isEditing ? s.subscriptionModalEditTitle : s.subscriptionModalAddTitle,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      submitLabel: _isEditing ? s.save : s.add,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiField(
              label: s.subscriptionModalFieldTopicFilter,
              controller: _topic,
              hint: 'e.g. home/+/sensor/#',
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? s.subscriptionModalValidateTopicFilter : null, //
            ),
            VSpacer(14),
            UiField(
              label: s.subscriptionModalFieldDisplayName,
              optional: true,
              controller: _name,
              hint: s.subscriptionModalHintDisplayName,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(), //
            ),
            VSpacer(18),
            UiSegmentRow<int>(
              label: s.subscriptionModalQoSLabel,
              options: [
                UiSegmentOption(value: 0, label: s.subscriptionModalQoS0Label, description: s.subscriptionModalQoS0Description),
                UiSegmentOption(value: 1, label: s.subscriptionModalQoS1Label, description: s.subscriptionModalQoS1Description),
                UiSegmentOption(value: 2, label: s.subscriptionModalQoS2Label, description: s.subscriptionModalQoS2Description),
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
