import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../generated/l10n.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/broker_entry.dart';
import '../models/subscription_entry.dart';
import '../../elements/ui_field.dart';
import '../../elements/ui_modal_scaffold.dart';
import '../../elements/ui_switch_row.dart';
import '../../elements/ui_section.dart';
import '../../elements/ui_sortable_row.dart';
import '../../widgets/spacers.dart';
import '../../widgets/qos_tag.dart';
import 'subscription_modal.dart';

// ── Section label matching SectionHeader style ────────────────────────────────
Widget _sectionLabel(BuildContext context, String label) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 2),
  child: Text(
    label.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: context.tokens.textSecondary),
  ),
);

Future<BrokerEntry?> showBrokerModal(BuildContext context, {BrokerEntry? broker, VoidCallback? onDelete}) {
  return showDialog<BrokerEntry>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => BrokerModal(broker: broker, onDelete: onDelete),
  );
}

class BrokerModal extends StatefulWidget {
  const BrokerModal({super.key, this.broker, this.onDelete});

  final BrokerEntry? broker;
  final VoidCallback? onDelete;

  @override
  State<BrokerModal> createState() => _BrokerModalState();
}

class _BrokerModalState extends State<BrokerModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _clientId;
  late bool _useSSL;
  late bool _validateCertificates;
  late bool _randomClientIdSuffix;
  late int _colorIndex;
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
    _validateCertificates = b?.validateCertificates ?? true;
    _randomClientIdSuffix = b?.randomClientIdSuffix ?? true;
    _colorIndex = b?.colorIndex ?? 0;
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
        id: widget.broker?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        host: _host.text.trim(),
        port: int.tryParse(_port.text.trim()) ?? 1883,
        useSSL: _useSSL,
        validateCertificates: _validateCertificates,
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
        clientId: _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
        randomClientIdSuffix: _randomClientIdSuffix,
        colorIndex: _colorIndex,
        subscriptions: _subscriptions,
      ),
    );
  }

  Future<void> _addSubscription() async {
    final sub = await showSubscriptionModal(context);
    if (sub == null) return;
    setState(() => _subscriptions.add(sub));
  }

  Future<void> _editSubscription(int index) async {
    final sub = await showSubscriptionModal(context, entry: _subscriptions[index]);
    if (sub == null) return;
    setState(() => _subscriptions[index] = sub);
  }

  void _removeSubscription(int index) => setState(() => _subscriptions.removeAt(index));

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
        _sectionLabel(context, s.brokerModalSectionConnection),
        const VSpacer(10),
        UiField(label: s.brokerModalFieldName, controller: _name, hint: 'e.g. Home Server', textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? s.brokerModalValidateName : null),

        const VSpacer(14),

        // Color picker
        _buildColorPicker(),

        const VSpacer(14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: UiField(label: s.brokerModalFieldHost, controller: _host, hint: 'e.g. broker.example.com', textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? s.brokerModalValidateHost : null),
            ),

            const HSpacer(10),

            Expanded(
              flex: 1,
              child: UiField(
                label: s.brokerModalFieldPort,
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

        const VSpacer(12),

        UiSwitchRow(label: s.brokerModalUseSSL, subtitle: s.brokerModalUseSSLSubtitle, value: _useSSL, accent: accent, bordered: true, onChanged: (v) => setState(() => _useSSL = v)),

        const VSpacer(12),

        UiSwitchRow(label: s.brokerModalValidateCertificates, subtitle: s.brokerModalValidateCertificatesSubtitle, value: _validateCertificates, accent: accent, bordered: true, onChanged: (v) => setState(() => _validateCertificates = v)),

        const VSpacer(14),

        UiField(label: s.brokerModalFieldClientId, optional: true, controller: _clientId, hint: 'mqtt_monitor', textInputAction: TextInputAction.next),

        const VSpacer(12),

        UiSwitchRow(label: s.brokerModalRandomSuffix, subtitle: s.brokerModalRandomSuffixSubtitle, value: _randomClientIdSuffix, accent: accent, bordered: true, onChanged: (v) => setState(() => _randomClientIdSuffix = v)),
      ],
    );
  }

  Widget _buildColorPicker() {
    final s = S.of(context);
    final colors = AppColors.brokerColorOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(s.brokerModalFieldColor, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.tokens.textSecondary)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(colors.length, (i) {
            final isSelected = i == _colorIndex;
            final gradient = AppColors.brokerGradientFor(i);
            return GestureDetector(
              onTap: () => setState(() => _colorIndex = i),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors[i], width: 2.5) : null,
                  boxShadow: isSelected ? [BoxShadow(color: colors[i].withValues(alpha: 0.4), blurRadius: 6)] : null,
                ),
                child: isSelected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAuthSection() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, s.brokerModalSectionAuthentication),
        const VSpacer(10),
        UiField(label: s.brokerModalFieldUsername, optional: true, controller: _username, hint: s.optional, textInputAction: TextInputAction.next),
        const VSpacer(14),
        UiField(
          label: s.brokerModalFieldPassword,
          optional: true,
          controller: _password,
          hint: s.optional,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: context.tokens.textSecondary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
            label: s.brokerModalSectionTopics,
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
            label: Text(s.brokerModalAddSubscription),
            style: TextButton.styleFrom(foregroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), visualDensity: VisualDensity.compact),
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
      title: _isEditing ? s.brokerModalEditTitle : s.brokerModalAddTitle,
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildConnectionSection(accent), const VSpacer(20), _buildAuthSection(), const VSpacer(20), _buildSubscriptionsSection(accent), const VSpacer(8)]),
      ),
    );
  }
}
