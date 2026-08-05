import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/keys/settings_keys.dart';
import '../../../generated/l10n.dart';
import '../../../models/broker_entry.dart';
import '../../../models/mqtt_qos_default.dart';
import '../../../models/publish_shortcut.dart';
import '../../../shared/format_helpers.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/payload_editor.dart';
import '../../../shared/widgets/scope_picker.dart';
import '../../../shared/widgets/ui_segment_row.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../../../theme/app_colors.dart';

/// Shows a dialog for creating or editing a publish shortcut.
///
/// Returns the resulting [PublishShortcut] on save, or null if dismissed.
Future<PublishShortcut?> showShortcutDialog(BuildContext context, {PublishShortcut? shortcut, List<BrokerEntry> brokers = const [], VoidCallback? onDelete, int? defaultQos}) {
  return showDialog<PublishShortcut>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _ShortcutDialog(shortcut: shortcut, brokers: brokers, onDelete: onDelete, defaultQos: defaultQos),
  );
}

class _ShortcutDialog extends StatefulWidget {
  const _ShortcutDialog({this.shortcut, required this.brokers, this.onDelete, this.defaultQos});

  final PublishShortcut? shortcut;
  final List<BrokerEntry> brokers;
  final VoidCallback? onDelete;

  /// QoS used when [shortcut] is null (i.e. creating a new shortcut).
  /// Honored from the user-configurable default-shortcut-QoS setting
  /// when not null.
  final int? defaultQos;

  @override
  State<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<_ShortcutDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _topicController;
  late final HighlightingController _payloadController;
  late int _qos;
  late bool _retain;
  late Color _color;
  late bool _isGlobal;
  late Set<String> _selectedBrokerIds;
  late PayloadFormat _format;
  String? _validationError;

  bool get _isEditing => widget.shortcut != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shortcut?.name ?? '');
    _topicController = TextEditingController(text: widget.shortcut?.topic ?? '');
    _payloadController = HighlightingController(text: widget.shortcut?.payload ?? '');
    if (widget.shortcut != null) {
      _qos = widget.shortcut!.qos;
    } else if (widget.defaultQos != null) {
      // Caller passed a resolved (clamped 0..2) QoS.
      _qos = widget.defaultQos!.clamp(0, 2);
    } else {
      // Fall back to the user's default-shortcut-QoS setting, honoring
      // the "last used" strategy if selected.
      final state = context.read<AppStateManager>();
      state.load(SettingsKeys.defaultShortcutQos);
      state.load(SettingsKeys.lastUsedQos);
      final strategy = state.read<MqttQosDefault>(SettingsKeys.defaultShortcutQos);
      _qos = strategy.resolve(state.read(SettingsKeys.lastUsedQos));
    }
    _retain = widget.shortcut?.retain ?? false;
    _color = widget.shortcut?.displayColor ?? AppColors.brokerColorOptions.first;
    _isGlobal = widget.shortcut?.isGlobal ?? true;
    _selectedBrokerIds = {...?widget.shortcut?.brokerIds};
    _format = (widget.shortcut?.payloadFormatIsJson ?? false) ? PayloadFormat.json : PayloadFormat.text;
    _payloadController.highlightJson = _format == PayloadFormat.json;
    _payloadController.addListener(_onPayloadChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  void _onPayloadChanged() {
    if (_format == PayloadFormat.json) {
      final error = validateJson(_payloadController.text);
      if (error != _validationError) setState(() => _validationError = error);
    } else if (_validationError != null) {
      setState(() => _validationError = null);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, PublishShortcut(name: _nameController.text.trim(), topic: _topicController.text.trim(), payload: _payloadController.text, payloadFormatIsJson: _format == PayloadFormat.json, qos: _qos, retain: _retain, color: _color.toARGB32(), brokerIds: _isGlobal ? [] : _selectedBrokerIds.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Form(
      key: _formKey,
      child: UiModalScaffold(
        title: _isEditing ? s.shortcutDialogEditTitle : s.shortcutDialogAddTitle,
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
            UiField(label: s.shortcutDialogFieldName, controller: _nameController, hint: 'e.g. Turn on lights', validator: (v) => (v == null || v.trim().isEmpty) ? s.shortcutDialogValidateName : null),
            const VSpacer(14),
            UiField(label: s.shortcutDialogFieldTopic, controller: _topicController, hint: 'e.g. home/lights/toggle', validator: (v) => (v == null || v.trim().isEmpty) ? s.shortcutDialogValidateTopic : null),
            const VSpacer(14),
            SizedBox(
              height: 180,
              child: PayloadEditor(
                controller: _payloadController,
                format: _format,
                onFormatChanged: (f) {
                  setState(() => _format = f);
                  _payloadController.highlightJson = f == PayloadFormat.json;
                  _onPayloadChanged();
                },
                validationError: _validationError,
              ),
            ),
            const VSpacer(14),
            ColorPickerField(label: s.shortcutDialogFieldColor, value: _color, onChanged: (c) => setState(() => _color = c)),
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
                // picks it up the next time a shortcut is added.
                context.read<AppStateManager>().write(SettingsKeys.lastUsedQos, v);
              },
            ),
            const VSpacer(8),
            UiSwitchRow(label: s.shortcutDialogRetain, subtitle: s.shortcutDialogRetainSubtitle, value: _retain, onChanged: (v) => setState(() => _retain = v)),
            const VSpacer(18),
            sectionLabel(context, s.dashboardDialogSectionScope),
            const VSpacer(10),
            ScopeOption(label: s.scopeGlobal, subtitle: s.shortcutDialogScopeGlobalSubtitle, icon: Icons.public_rounded, selected: _isGlobal, onTap: () => setState(() => _isGlobal = true)),
            const VSpacer(6),
            ScopeOption(label: s.scopeSpecificBrokers, subtitle: s.shortcutDialogScopeBrokersSubtitle, icon: Icons.dns_rounded, selected: !_isGlobal, onTap: () => setState(() => _isGlobal = false)),
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
