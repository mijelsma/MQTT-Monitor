import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../generated/l10n.dart';
import '../../../models/broker_entry.dart';
import '../../../models/mqtt_protocol_version.dart';
import '../../../models/subscription_entry.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_segment_row.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import 'subscription_dialog.dart';

Widget _sectionLabel(BuildContext context, String label) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 2),
  child: Text(
    label.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: context.tokens.textSecondary,
    ),
  ),
);

Future<BrokerEntry?> showBrokerDialog(
  BuildContext context, {
  BrokerEntry? broker,
  VoidCallback? onDelete,
}) {
  return showDialog<BrokerEntry>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => BrokerDialog(broker: broker, onDelete: onDelete),
  );
}

class BrokerDialog extends StatefulWidget {
  const BrokerDialog({super.key, this.broker, this.onDelete});

  final BrokerEntry? broker;
  final VoidCallback? onDelete;

  @override
  State<BrokerDialog> createState() => _BrokerDialogState();
}

class _BrokerDialogState extends State<BrokerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _clientId;
  late bool _useSSL;
  late MqttProtocolVersion _protocolVersion;
  late bool _validateCertificates;
  late bool _randomClientIdSuffix;
  late Color _color;
  bool _obscurePassword = true;
  late List<SubscriptionEntry> _subscriptions;

  bool get _isEditing => widget.broker != null;

  @override
  void initState() {
    super.initState();
    final b = widget.broker;
    _name = TextEditingController(text: b?.name ?? '');
    _host = TextEditingController(text: b?.host ?? '');
    _port = TextEditingController(text: b?.port.toString() ?? '1883');
    _username = TextEditingController(text: b?.username ?? '');
    _password = TextEditingController(text: b?.password ?? '');
    _clientId = TextEditingController(text: b?.clientId ?? '');
    _useSSL = b?.useSSL ?? false;
    _protocolVersion = b?.protocolVersion ?? MqttProtocolVersion.v311;
    _validateCertificates = b?.validateCertificates ?? true;
    _randomClientIdSuffix = b?.randomClientIdSuffix ?? true;
    _color = AppColors.brokerColorOptions[b?.colorIndex ?? 0];
    _subscriptions = List.from(b?.subscriptions ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _clientId.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      BrokerEntry(
        id:
            widget.broker?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        host: _host.text.trim(),
        port: int.tryParse(_port.text.trim()) ?? 1883,
        protocolVersion: _protocolVersion,
        useSSL: _useSSL,
        validateCertificates: _validateCertificates,
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
        clientId: _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
        randomClientIdSuffix: _randomClientIdSuffix,
        colorIndex: AppColors.colorIndex(_color),
        subscriptions: _subscriptions,
      ),
    );
  }

  Future<void> _addSubscription() async {
    final sub = await showSubscriptionDialog(context);
    if (sub == null) return;
    setState(() => _subscriptions.add(sub));
  }

  Future<void> _editSubscription(int index) async {
    final sub = await showSubscriptionDialog(
      context,
      entry: _subscriptions[index],
    );
    if (sub == null) return;
    setState(() => _subscriptions[index] = sub);
  }

  void _removeSubscription(int index) =>
      setState(() => _subscriptions.removeAt(index));

  void _reorderSubscriptions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _subscriptions.removeAt(oldIndex);
      _subscriptions.insert(newIndex, item);
    });
  }

  Widget _buildConnectionSection(Color accent) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, s.brokerDialogSectionConnection),
        const VSpacer(10),
        UiField(
          label: s.brokerDialogFieldName,
          controller: _name,
          hint: 'e.g. Home Server',
          textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? s.brokerDialogValidateName
              : null,
        ),
        ColorPickerField(
          margin: const EdgeInsets.only(top: 14),
          label: s.brokerDialogFieldColor,
          value: _color,
          onChanged: (c) => setState(() => _color = c),
        ),
        const VSpacer(14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: UiField(
                label: s.brokerDialogFieldHost,
                controller: _host,
                hint: 'e.g. broker.example.com',
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.brokerDialogValidateHost
                    : null,
              ),
            ),
            const HSpacer(10),
            Expanded(
              flex: 1,
              child: UiField(
                label: s.brokerDialogFieldPort,
                controller: _port,
                hint: '1883',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 65535) return '1–65535:';
                  return null;
                },
              ),
            ),
          ],
        ),
        UiSwitchRow(
          margin: const EdgeInsets.only(top: 12),
          label: s.brokerDialogUseSSL,
          subtitle: s.brokerDialogUseSSLSubtitle,
          value: _useSSL,
          accent: accent,
          bordered: true,
          onChanged: (v) => setState(() => _useSSL = v),
        ),
        UiSegmentRow<MqttProtocolVersion>(
          label: 'Protocol version',
          options: MqttProtocolVersion.values
              .map(
                (version) =>
                    UiSegmentOption(value: version, label: version.displayName),
              )
              .toList(),
          value: _protocolVersion,
          onChanged: (value) => setState(() => _protocolVersion = value),
          accent: accent,
        ),
        UiSwitchRow(
          margin: const EdgeInsets.only(top: 12),
          label: s.brokerDialogValidateCertificates,
          subtitle: s.brokerDialogValidateCertificatesSubtitle,
          value: _validateCertificates,
          accent: accent,
          bordered: true,
          onChanged: (v) => setState(() => _validateCertificates = v),
        ),
        UiField(
          margin: const EdgeInsets.only(top: 14),
          label: s.brokerDialogFieldClientId,
          optional: true,
          controller: _clientId,
          hint: 'mqtt_monitor',
          textInputAction: TextInputAction.next,
        ),
        UiSwitchRow(
          margin: const EdgeInsets.only(top: 12),
          label: s.brokerDialogRandomSuffix,
          subtitle: s.brokerDialogRandomSuffixSubtitle,
          value: _randomClientIdSuffix,
          accent: accent,
          bordered: true,
          onChanged: (v) => setState(() => _randomClientIdSuffix = v),
        ),
      ],
    );
  }

  Widget _buildAuthSection() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, s.brokerDialogSectionAuthentication),
        const VSpacer(10),
        UiField(
          label: s.brokerDialogFieldUsername,
          optional: true,
          controller: _username,
          hint: s.optional,
          textInputAction: TextInputAction.next,
        ),
        UiField(
          margin: const EdgeInsets.only(top: 14),
          label: s.brokerDialogFieldPassword,
          optional: true,
          controller: _password,
          hint: s.optional,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: context.tokens.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionsSection(Color accent) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VSpacer(10),
        if (_subscriptions.isNotEmpty) ...[
          UiSection(
            label: s.brokerDialogSectionTopics,
            sortable: true,
            onReorder: _reorderSubscriptions,
            children: List.generate(_subscriptions.length, (i) {
              final sub = _subscriptions[i];
              final hasName = sub.name != null && sub.name!.isNotEmpty;
              return UiSortableRow(
                key: ValueKey('${sub.topic}_$i'),
                index: i,
                leading: QosTag(qos: sub.qos),
                title: hasName ? sub.name! : sub.topic,
                subtitle: hasName ? sub.topic : null,
                onTap: () => _editSubscription(i),
                onDelete: () => _removeSubscription(i),
              );
            }),
          ),
          const VSpacer(6),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addSubscription,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(s.brokerDialogAddSubscription),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.primary;
    final s = S.of(context);

    return UiModalScaffold(
      title: _isEditing ? s.brokerDialogEditTitle : s.brokerDialogAddTitle,
      isEditing: _isEditing,
      onDelete: (widget.onDelete != null)
          ? () {
              Navigator.pop(context);
              widget.onDelete!();
            }
          : null,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      submitLabel: _isEditing ? s.save : s.add,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionSection(accent),
            const VSpacer(20),
            _buildAuthSection(),
            const VSpacer(20),
            _buildSubscriptionsSection(accent),
            const VSpacer(8),
          ],
        ),
      ),
    );
  }
}
