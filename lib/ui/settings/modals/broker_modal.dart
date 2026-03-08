import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/broker_entry.dart';
import '../models/subscription_entry.dart';
import '../../elements/ui_field.dart';
import '../../elements/ui_modal_scaffold.dart';
import '../../elements/ui_section.dart';
import '../../elements/ui_sortable_row.dart';
import '../../widgets/spacers.dart';
import '../../widgets/qos_tag.dart';
import 'subscription_modal.dart';

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
  late bool _useSSL;
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
    _useSSL = b?.useSSL ?? false;
    _subscriptions = List.from(b?.subscriptions ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
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
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
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

  // ── Section builders ─────────────────────────────────────────────────────

  Widget _buildConnectionSection(Color accent) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, 'Connection'),
        const VSpacer(10),
        UiField(
          label: 'Name',
          child: TextFormField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(context, accent: accent, hint: 'e.g. Home Server'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
        ),
        const VSpacer(14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: UiField(
                label: 'Host',
                child: TextFormField(
                  controller: _host,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(context, accent: accent, hint: 'e.g. 192.168.1.100'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a host' : null,
                ),
              ),
            ),
            const HSpacer(10),
            Expanded(
              flex: 1,
              child: UiField(
                label: 'Port',
                child: TextFormField(
                  controller: _port,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(context, accent: accent, hint: '1883'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1 || n > 65535) return '1–65535';
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const VSpacer(12),
        // SSL toggle (bordered container matching original SslToggle)
        Container(
          decoration: BoxDecoration(
            color: tokens.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border, width: 0.5),
          ),
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            title: const Text('Use SSL / TLS', style: TextStyle(fontSize: 14)),
            subtitle: Text('Encrypts the connection using TLS', style: TextStyle(fontSize: 11.5, color: tokens.textSecondary)),
            value: _useSSL,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.35),
            onChanged: (v) => setState(() => _useSSL = v),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthSection(Color accent) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel(context, 'Authentication'),
      const VSpacer(10),
      UiField(
        label: 'Username',
        optional: true,
        child: TextFormField(
          controller: _username,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(context, accent: accent, hint: 'Optional'),
        ),
      ),
      const VSpacer(14),
      UiField(
        label: 'Password',
        optional: true,
        child: TextFormField(
          controller: _password,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration(
            context,
            accent: accent,
            hint: 'Optional',
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: context.tokens.textSecondary),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildSubscriptionsSection(Color accent) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel(context, 'Subscriptions'),
      const VSpacer(10),
      if (_subscriptions.isNotEmpty) ...[
        UiSection(
          label: 'Topics',
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
          label: const Text('Add Subscription'),
          style: TextButton.styleFrom(foregroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), visualDensity: VisualDensity.compact),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.primary;

    return UiModalScaffold(
      title: _isEditing ? 'Edit Broker' : 'Add Broker',
      isEditing: _isEditing,
      onDelete: (widget.onDelete != null)
          ? () {
              Navigator.pop(context);
              widget.onDelete!();
            }
          : null,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      submitLabel: _isEditing ? 'Save' : 'Add',
      body: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildConnectionSection(accent), const VSpacer(20), _buildAuthSection(accent), const VSpacer(20), _buildSubscriptionsSection(accent), const VSpacer(8)]),
      ),
    );
  }
}
