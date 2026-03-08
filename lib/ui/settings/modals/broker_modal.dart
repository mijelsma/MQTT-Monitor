import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/broker_entry.dart';
import '../models/subscription_entry.dart';
import '../widgets/field_label.dart';
import '../widgets/modal_input_decoration.dart';
import '../widgets/section_header.dart';
import '../widgets/ssl_toggle.dart';
import '../../widgets/spacers.dart';
import '../../widgets/qos_tag.dart';
import 'subscription_modal.dart';

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

  Widget _buildConnectionSection(Color accent) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionHeader(label: 'Connection'),
      VSpacer(10),
      const FieldLabel(label: 'Name'),
      VSpacer(6),
      TextFormField(
        controller: _name,
        textInputAction: TextInputAction.next,
        decoration: modalInputDecoration(context, accent: accent, hint: 'e.g. Home Server'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
      ),
      VSpacer(14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(label: 'Host'),
                VSpacer(6),
                TextFormField(
                  controller: _host,
                  textInputAction: TextInputAction.next,
                  decoration: modalInputDecoration(context, accent: accent, hint: 'e.g. 192.168.1.100'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a host' : null,
                ),
              ],
            ),
          ),
          HSpacer(10),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(label: 'Port'),
                VSpacer(6),
                TextFormField(
                  controller: _port,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: modalInputDecoration(context, accent: accent, hint: '1883'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1 || n > 65535) return '1–65535';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      VSpacer(12),
      SslToggle(value: _useSSL, accent: accent, onChanged: (v) => setState(() => _useSSL = v)),
    ],
  );

  Widget _buildAuthSection(Color accent) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionHeader(label: 'Authentication'),
      VSpacer(10),
      const FieldLabel(label: 'Username', optional: true),
      VSpacer(6),
      TextFormField(
        controller: _username,
        textInputAction: TextInputAction.next,
        decoration: modalInputDecoration(context, accent: accent, hint: 'Optional'),
      ),
      VSpacer(14),
      const FieldLabel(label: 'Password', optional: true),
      VSpacer(6),
      TextFormField(
        controller: _password,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        decoration: modalInputDecoration(
          context,
          accent: accent,
          hint: 'Optional',
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: context.tokens.textSecondary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    ],
  );

  Widget _buildSubscriptionsSection(Color accent) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionHeader(label: 'Subscriptions'),
      VSpacer(10),
      if (_subscriptions.isNotEmpty) ...[
        ReorderableListView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, __) => Material(color: Colors.transparent, child: child),
          onReorder: _reorderSubscriptions,
          itemCount: _subscriptions.length,
          itemBuilder: (context, index) {
            final sub = _subscriptions[index];
            return _SubscriptionRow(key: ValueKey('${sub.topic}_$index'), sub: sub, index: index, onTap: () => _editSubscription(index), onDelete: () => _removeSubscription(index));
          },
        ),
        VSpacer(6),
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
    final theme = Theme.of(context);
    final accent = context.tokens.primary;
    final cardColor = context.tokens.surface;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                children: [
                  Text(_isEditing ? 'Edit Broker' : 'Add Broker', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: context.tokens.textSecondary),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Spacer
            VSpacer(4),

            // Horizontal divider
            Divider(height: 0.5, thickness: 0.5, color: context.tokens.border),

            // Scrollable content with form fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildConnectionSection(accent),
                      VSpacer(20),
                      _buildAuthSection(accent),
                      VSpacer(20),
                      _buildSubscriptionsSection(accent),
                      VSpacer(8), //
                    ],
                  ),
                ),
              ),
            ),

            Divider(height: 0.5, thickness: 0.5, color: context.tokens.border),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Row(
                children: [
                  if (_isEditing && widget.onDelete != null) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.error500),
                      child: const Text('Delete'),
                    ),
                  ],
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
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({super.key, required this.sub, required this.index, required this.onTap, required this.onDelete});

  final SubscriptionEntry sub;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasName = sub.name != null && sub.name!.isNotEmpty;
    final primaryText = hasName ? sub.name! : sub.topic;
    final secondaryText = hasName ? sub.topic : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_indicator_rounded, size: 18, color: tokens.textTertiary),
            ),
          ),

          // QoS badge
          QosTag(qos: sub.qos),
          HSpacer(10),

          // Name / topic (tappable to edit)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (secondaryText != null) ...[
                    VSpacer(1),
                    Text(
                      secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.textSecondary, fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Delete
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: tokens.textTertiary),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
