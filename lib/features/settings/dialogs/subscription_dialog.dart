import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/keys/settings_keys.dart';
import '../../../core/history/history_policy_rules.dart';
import '../../../core/mqtt/mqtt_topic_filter.dart';
import '../../../generated/l10n.dart';
import '../../../models/subscription_entry.dart';
import '../../../models/subscription_history_policy.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_inline_notice.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../shared/widgets/ui_segment_row.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';

Future<SubscriptionEntry?> showSubscriptionDialog(
  BuildContext context, {
  SubscriptionEntry? entry,
  int defaultQos = 1,
  bool defaultHistoryEnabled = HistoryPolicyRules.defaultEnabled,
  int defaultHistoryRetention = HistoryPolicyRules.defaultRetention,
  int maximumHistoryRetention = HistoryPolicyRules.defaultMaximumRetention,
  Set<String> existingTopicFilters = const {},
}) {
  return showDialog<SubscriptionEntry>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => SubscriptionDialog(entry: entry, defaultQos: defaultQos, defaultHistoryEnabled: defaultHistoryEnabled, defaultHistoryRetention: defaultHistoryRetention, maximumHistoryRetention: maximumHistoryRetention, existingTopicFilters: existingTopicFilters),
  );
}

class SubscriptionDialog extends StatefulWidget {
  const SubscriptionDialog({super.key, this.entry, this.defaultQos = 1, this.defaultHistoryEnabled = HistoryPolicyRules.defaultEnabled, this.defaultHistoryRetention = HistoryPolicyRules.defaultRetention, this.maximumHistoryRetention = HistoryPolicyRules.defaultMaximumRetention, this.existingTopicFilters = const {}});

  final SubscriptionEntry? entry;

  /// QoS used when [entry] is null (i.e. creating a new subscription).
  /// Honored from the user-configurable default-subscribe-QoS setting.
  final int defaultQos;
  final bool defaultHistoryEnabled;
  final int defaultHistoryRetention;
  final int maximumHistoryRetention;
  final Set<String> existingTopicFilters;

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topic;
  late final TextEditingController _name;
  late int _qos;
  late bool _historyEnabled;
  late int _historyRetention;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _topic = TextEditingController(text: widget.entry?.topic ?? '');
    _name = TextEditingController(text: widget.entry?.name ?? '');
    _qos = widget.entry?.qos ?? widget.defaultQos;
    _historyEnabled = widget.entry?.history.enabled ?? widget.defaultHistoryEnabled;
    _historyRetention = (widget.entry?.history.retention ?? widget.defaultHistoryRetention).clamp(HistoryPolicyRules.minimumRetention, widget.maximumHistoryRetention);
  }

  @override
  void dispose() {
    _topic.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final topic = _topic.text.trim();
    final name = _name.text.trim();
    final history = SubscriptionHistoryPolicy(enabled: _historyEnabled, retention: _historyRetention);
    final entry = widget.entry;
    Navigator.pop(context, entry == null ? SubscriptionEntry.create(topic: topic, qos: _qos, name: name.isEmpty ? null : name, history: history) : entry.copyWith(topic: topic, qos: _qos, name: name, clearName: name.isEmpty, history: history));
  }

  String? _validateTopic(String? value) {
    final strings = S.of(context);
    final topic = value?.trim() ?? '';
    if (topic.isEmpty) return strings.subscriptionDialogValidateTopicFilter;
    if (MqttTopicFilter.validate(topic) != null) {
      return strings.subscriptionDialogInvalidTopicFilter;
    }
    if (widget.existingTopicFilters.contains(topic)) {
      return strings.subscriptionDialogDuplicateTopicFilter;
    }
    return null;
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
            UiField(label: s.subscriptionDialogFieldTopicFilter, controller: _topic, hint: 'e.g. home/+/sensor/#', textInputAction: TextInputAction.next, validator: _validateTopic),
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
              onChanged: (v) {
                setState(() => _qos = v);
                // Record the pick so the "last used" default strategy
                // picks it up the next time a subscription is added.
                context.read<AppStateManager>().write(SettingsKeys.lastUsedQos, v);
              },
            ),
            const VSpacer(18),
            Text(s.subscriptionDialogHistoryLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const VSpacer(8),
            UiSwitchRow(key: const Key('subscription-history-enabled'), contentPadding: const EdgeInsets.symmetric(horizontal: 12), label: s.subscriptionDialogHistoryEnabled, subtitle: s.subscriptionDialogHistoryEnabledHint, value: _historyEnabled, bordered: true, onChanged: (value) => setState(() => _historyEnabled = value)),
            UiSliderRow(
              key: const Key('subscription-history-retention'),
              margin: const EdgeInsets.fromLTRB(2, 14, 2, 4),
              label: s.subscriptionDialogHistoryRetention,
              subtitle: s.subscriptionDialogHistoryRetentionHint,
              value: _historyRetention.toDouble(),
              min: HistoryPolicyRules.minimumRetention.toDouble(),
              max: widget.maximumHistoryRetention.toDouble(),
              divisions: widget.maximumHistoryRetention - HistoryPolicyRules.minimumRetention,
              displayValue: '$_historyRetention',
              onChanged: _historyEnabled ? (value) => setState(() => _historyRetention = value.round()) : null,
            ),
            UiInlineNotice(kind: UiNoticeKind.info, message: s.subscriptionDialogHistoryOverlapHint, radius: 10),
          ],
        ),
      ),
    );
  }
}
