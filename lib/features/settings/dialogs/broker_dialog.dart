import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../../core/mqtt/app_private_certificate_storage.dart';
import '../../../core/mqtt/certificate_validation_exception.dart';
import '../../../core/mqtt/client_certificate_kind.dart';
import '../../../core/mqtt/client_certificate_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/keys/settings_keys.dart';
import '../../../generated/l10n.dart';
import '../../../models/broker_entry.dart';
import '../../../models/client_certificate_config.dart';
import '../../../models/mqtt_protocol_version.dart';
import '../../../models/mqtt_qos_default.dart';
import '../../../models/subscription_entry.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_inline_notice.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_segment_row.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import 'subscription_dialog.dart';

/// Builds the compact uppercase label used above dialog sections.
Widget _sectionLabel(BuildContext context, String label) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 2),
  child: Text(
    label.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: context.tokens.textSecondary),
  ),
);

/// Opens a broker editor and returns the submitted profile.
Future<BrokerEntry?> showBrokerDialog(BuildContext context, {BrokerEntry? broker, VoidCallback? onDelete}) {
  return showDialog<BrokerEntry>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => BrokerDialog(broker: broker, onDelete: onDelete),
  );
}

/// Edits broker connection, authentication, certificate, and subscription data.
class BrokerDialog extends StatefulWidget {
  /// Creates a broker editor for an optional existing [broker].
  const BrokerDialog({super.key, this.broker, this.onDelete});

  final BrokerEntry? broker;
  final VoidCallback? onDelete;

  /// Creates the mutable dialog state.
  @override
  State<BrokerDialog> createState() => _BrokerDialogState();
}

/// Owns temporary editor values and uncommitted certificate imports.
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
  late ClientCertificateConfig _clientCertificates;
  late final String _brokerId;
  final _certificateService = ClientCertificateService();
  final _certificateStorage = AppPrivateCertificateStorage.standard();
  final Set<String> _importedCertificatePaths = {};
  bool _submitted = false;
  String? _certificateError;
  late bool _validateCertificates;
  late bool _randomClientIdSuffix;
  late Color _color;
  bool _obscurePassword = true;
  late List<SubscriptionEntry> _subscriptions;

  /// Returns whether the dialog edits an existing broker.
  bool get _isEditing => widget.broker != null;
  bool _defaultSubscriptionApplied = false;

  /// Initializes controllers and a stable broker ID for certificate ownership.
  @override
  void initState() {
    super.initState();
    final b = widget.broker;
    _brokerId = b?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _name = TextEditingController(text: b?.name ?? '');
    _host = TextEditingController(text: b?.host ?? '');
    _port = TextEditingController(text: b?.port.toString() ?? '1883');
    _username = TextEditingController(text: b?.username ?? '');
    _password = TextEditingController(text: b?.password ?? '');
    _clientId = TextEditingController(text: b?.clientId ?? '');
    _useSSL = b?.useSSL ?? false;
    _protocolVersion = b?.protocolVersion ?? MqttProtocolVersion.v311;
    _clientCertificates = b?.clientCertificates ?? const ClientCertificateConfig();
    _validateCertificates = b?.validateCertificates ?? true;
    _randomClientIdSuffix = b?.randomClientIdSuffix ?? true;
    _color = AppColors.brokerColorOptions[b?.colorIndex ?? 0];
    _subscriptions = List.from(b?.subscriptions ?? []);
  }

  /// Adds the configured default subscription once localization is available.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.broker == null && !_defaultSubscriptionApplied) {
      _defaultSubscriptionApplied = true;
      final state = context.read<AppStateManager>();
      state.load(SettingsKeys.defaultSubscribeQos);
      state.load(SettingsKeys.lastUsedQos);
      final strategy = state.read<MqttQosDefault>(SettingsKeys.defaultSubscribeQos);
      final defaultQos = strategy.resolve(state.read(SettingsKeys.lastUsedQos));
      _subscriptions.add(SubscriptionEntry(topic: '#', qos: defaultQos, name: S.of(context).brokerDialogDefaultSubscriptionName));
    }
  }

  /// Disposes controllers and schedules cleanup for abandoned imports.
  @override
  void dispose() {
    if (!_submitted) unawaited(_cleanupImportedCertificates());
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _clientId.dispose();
    super.dispose();
  }

  /// Validates the form and transfers certificate ownership to the repository.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_clientCertificates.isEmpty && !_useSSL) {
      setState(() => _certificateError = 'mTLS requires an SSL/TLS connection.');
      return;
    }
    try {
      await _certificateService.validateConfiguration(_clientCertificates);
    } on CertificateValidationException catch (error) {
      if (!mounted) return;
      setState(() => _certificateError = error.message);
      return;
    }
    if (!mounted) return;
    _submitted = true;
    Navigator.pop(
      context,
      BrokerEntry(
        id: _brokerId,
        name: _name.text.trim(),
        host: _host.text.trim(),
        port: int.tryParse(_port.text.trim()) ?? 1883,
        protocolVersion: _protocolVersion,
        clientCertificates: _clientCertificates,
        useSSL: _useSSL,
        validateCertificates: _validateCertificates,
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
        passwordReference: widget.broker?.passwordReference,
        clientId: _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
        randomClientIdSuffix: _randomClientIdSuffix,
        colorIndex: AppColors.colorIndex(_color),
        subscriptions: _subscriptions,
      ),
    );
  }

  /// Imports and validates one certificate into an isolated broker slot.
  Future<void> _pickCertificate(ClientCertificateKind kind) async {
    String? importedPath;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pem', 'crt', 'cer', 'key'], withData: true);
      if (result == null || result.files.isEmpty) return;

      final selected = result.files.single;
      final Uint8List bytes;
      if (selected.bytes != null) {
        bytes = selected.bytes!;
      } else if (selected.path != null) {
        bytes = await File(selected.path!).readAsBytes();
      } else {
        throw const CertificateValidationException('The selected file could not be read.');
      }
      _certificateService.validateBytes(kind, bytes);
      importedPath = await _certificateStorage.store(_brokerId, kind, bytes, originalFileName: selected.name);
      if (!mounted) {
        await _certificateStorage.delete(importedPath);
        return;
      }
      final previousPath = _certificatePath(kind);
      if (previousPath != null && _importedCertificatePaths.remove(previousPath)) {
        await _certificateStorage.delete(previousPath);
      }
      setState(() {
        _importedCertificatePaths.add(importedPath!);
        _useSSL = true;
        _certificateError = null;
        _clientCertificates = switch (kind) {
          ClientCertificateKind.rootCa => _clientCertificates.copyWith(rootCaPath: importedPath),
          ClientCertificateKind.privateKey => _clientCertificates.copyWith(clientPrivateKeyPath: importedPath),
          ClientCertificateKind.clientCertificate => _clientCertificates.copyWith(clientCertificatePath: importedPath),
        };
      });
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _certificateError = 'Could not open the file picker: ${error.message ?? error.code}');
      }
    } on CertificateValidationException catch (error) {
      if (mounted) setState(() => _certificateError = error.message);
    } catch (error) {
      if (importedPath != null && !_importedCertificatePaths.contains(importedPath)) {
        try {
          await _certificateStorage.delete(importedPath);
        } on Object {
          // The original import failure is more actionable to the user.
        }
      }
      if (mounted) {
        setState(() => _certificateError = 'Could not import the selected file: $error');
      }
    }
  }

  /// Clears a certificate slot and deletes it immediately when still temporary.
  Future<void> _clearCertificate(ClientCertificateKind kind) async {
    final previousPath = _certificatePath(kind);
    if (previousPath != null && _importedCertificatePaths.contains(previousPath)) {
      try {
        await _certificateStorage.delete(previousPath);
        _importedCertificatePaths.remove(previousPath);
      } on Object catch (error) {
        if (mounted) {
          setState(() => _certificateError = 'Could not remove the imported certificate: $error');
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _certificateError = null;
      _clientCertificates = switch (kind) {
        ClientCertificateKind.rootCa => _clientCertificates.copyWith(clearRootCa: true),
        ClientCertificateKind.privateKey => _clientCertificates.copyWith(clearClientPrivateKey: true),
        ClientCertificateKind.clientCertificate => _clientCertificates.copyWith(clearClientCertificate: true),
      };
    });
  }

  /// Returns the configured path for [kind].
  String? _certificatePath(ClientCertificateKind kind) => switch (kind) {
    ClientCertificateKind.rootCa => _clientCertificates.rootCaPath,
    ClientCertificateKind.privateKey => _clientCertificates.clientPrivateKeyPath,
    ClientCertificateKind.clientCertificate => _clientCertificates.clientCertificatePath,
  };

  /// Deletes every certificate imported during an abandoned edit.
  Future<void> _cleanupImportedCertificates() async {
    for (final filePath in _importedCertificatePaths) {
      try {
        await _certificateStorage.delete(filePath);
      } on Object {
        // Repository ownership starts only after submit, so cleanup is best effort.
      }
    }
    _importedCertificatePaths.clear();
  }

  /// Deletes temporary imports before closing without a submitted profile.
  Future<void> _cancel() async {
    await _cleanupImportedCertificates();
    if (mounted) Navigator.pop(context);
  }

  /// Deletes temporary imports before requesting deletion of the saved broker.
  Future<void> _delete() async {
    await _cleanupImportedCertificates();
    if (!mounted) return;
    Navigator.pop(context);
    widget.onDelete!();
  }

  /// Adds a subscription using the configured default QoS policy.
  Future<void> _addSubscription() async {
    final state = context.read<AppStateManager>();
    state.load(SettingsKeys.defaultSubscribeQos);
    state.load(SettingsKeys.lastUsedQos);
    final strategy = state.read<MqttQosDefault>(SettingsKeys.defaultSubscribeQos);
    final defaultQos = strategy.resolve(state.read(SettingsKeys.lastUsedQos));
    final sub = await showSubscriptionDialog(context, defaultQos: defaultQos);
    if (sub == null) return;
    setState(() => _subscriptions.add(sub));
  }

  /// Replaces the subscription at [index] when the editor returns a value.
  Future<void> _editSubscription(int index) async {
    final sub = await showSubscriptionDialog(context, entry: _subscriptions[index]);
    if (sub == null) return;
    setState(() => _subscriptions[index] = sub);
  }

  /// Removes the subscription at [index].
  void _removeSubscription(int index) => setState(() => _subscriptions.removeAt(index));

  /// Reorders subscriptions using Flutter's insertion-index convention.
  void _reorderSubscriptions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _subscriptions.removeAt(oldIndex);
      _subscriptions.insert(newIndex, item);
    });
  }

  /// Builds the broker endpoint and protocol controls.
  Widget _buildConnectionSection(Color accent) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, s.brokerDialogSectionConnection),
        const VSpacer(10),
        UiField(label: s.brokerDialogFieldName, controller: _name, hint: 'e.g. Home Server', textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? s.brokerDialogValidateName : null),
        ColorPickerField(margin: const EdgeInsets.only(top: 14), label: s.brokerDialogFieldColor, value: _color, onChanged: (c) => setState(() => _color = c)),
        const VSpacer(14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: UiField(label: s.brokerDialogFieldHost, controller: _host, hint: 'e.g. broker.example.com', textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? s.brokerDialogValidateHost : null),
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
        UiSegmentRow<MqttProtocolVersion>(
          label: 'Protocol version',
          options: MqttProtocolVersion.values.map((version) => UiSegmentOption(value: version, label: version.displayName)).toList(),
          value: _protocolVersion,
          onChanged: (value) => setState(() => _protocolVersion = value),
          accent: accent,
        ),
        UiSwitchRow(margin: const EdgeInsets.only(top: 12), label: s.brokerDialogUseSSL, subtitle: s.brokerDialogUseSSLSubtitle, value: _useSSL, accent: accent, bordered: true, onChanged: (v) => setState(() => _useSSL = v)),
        UiSwitchRow(margin: const EdgeInsets.only(top: 12), label: s.brokerDialogValidateCertificates, subtitle: s.brokerDialogValidateCertificatesSubtitle, value: _validateCertificates, accent: accent, bordered: true, onChanged: (v) => setState(() => _validateCertificates = v)),
        UiField(margin: const EdgeInsets.only(top: 14), label: s.brokerDialogFieldClientId, optional: true, controller: _clientId, hint: 'mqtt-monitor', textInputAction: TextInputAction.next),
        UiSwitchRow(margin: const EdgeInsets.only(top: 12), label: s.brokerDialogRandomSuffix, subtitle: s.brokerDialogRandomSuffixSubtitle, value: _randomClientIdSuffix, accent: accent, bordered: true, onChanged: (v) => setState(() => _randomClientIdSuffix = v)),
      ],
    );
  }

  /// Builds username, password, and mTLS controls.
  Widget _buildAuthSection() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, s.brokerDialogSectionAuthentication),
        const VSpacer(10),
        UiField(label: s.brokerDialogFieldUsername, optional: true, controller: _username, hint: s.optional, textInputAction: TextInputAction.next),
        UiField(
          margin: const EdgeInsets.only(top: 14),
          label: s.brokerDialogFieldPassword,
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
        const VSpacer(18),
        _CertificatePickerRow(
          label: 'Root CA certificate',
          fileName: _fileName(_clientCertificates.rootCaPath),
          onSelect: () => _pickCertificate(ClientCertificateKind.rootCa),
          onClear: _clientCertificates.rootCaPath == null
              ? null
              : () {
                  _clearCertificate(ClientCertificateKind.rootCa);
                },
        ),
        _CertificatePickerRow(
          label: 'Client private key',
          fileName: _fileName(_clientCertificates.clientPrivateKeyPath),
          onSelect: () => _pickCertificate(ClientCertificateKind.privateKey),
          onClear: _clientCertificates.clientPrivateKeyPath == null
              ? null
              : () {
                  _clearCertificate(ClientCertificateKind.privateKey);
                },
        ),
        _CertificatePickerRow(
          label: 'Client certificate',
          fileName: _fileName(_clientCertificates.clientCertificatePath),
          onSelect: () => _pickCertificate(ClientCertificateKind.clientCertificate),
          onClear: _clientCertificates.clientCertificatePath == null
              ? null
              : () {
                  _clearCertificate(ClientCertificateKind.clientCertificate);
                },
        ),
        if (_certificateError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: UiInlineNotice(kind: UiNoticeKind.error, message: _certificateError, selectable: true, onDismiss: () => setState(() => _certificateError = null), radius: 10),
          ),
      ],
    );
  }

  /// Returns a compact filename or the empty-slot label for [filePath].
  String _fileName(String? filePath) => filePath == null ? 'Not configured' : path.basename(filePath);

  /// Builds the editable subscription collection.
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
            style: TextButton.styleFrom(foregroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), visualDensity: VisualDensity.compact),
          ),
        ),
      ],
    );
  }

  /// Builds the complete broker dialog.
  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.primary;
    final s = S.of(context);

    return UiModalScaffold(
      title: _isEditing ? s.brokerDialogEditTitle : s.brokerDialogAddTitle,
      isEditing: _isEditing,
      onDelete: widget.onDelete == null ? null : _delete,
      onCancel: _cancel,
      onSubmit: _submit,
      submitLabel: _isEditing ? s.save : s.add,
      body: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildConnectionSection(accent), const VSpacer(20), _buildAuthSection(), const VSpacer(20), _buildSubscriptionsSection(accent), const VSpacer(8)]),
      ),
    );
  }
}

/// Displays one certificate slot with choose, replace, and clear actions.
class _CertificatePickerRow extends StatelessWidget {
  /// Creates a certificate picker row.
  const _CertificatePickerRow({required this.label, required this.fileName, required this.onSelect, this.onClear});

  final String label;
  final String fileName;
  final VoidCallback onSelect;
  final VoidCallback? onClear;

  /// Builds the certificate slot controls.
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSelect, child: Text(onClear == null ? 'Choose' : 'Replace')),
          if (onClear != null) IconButton(onPressed: onClear, tooltip: 'Clear', visualDensity: VisualDensity.compact, icon: const Icon(Icons.clear_rounded, size: 16)),
        ],
      ),
    );
  }
}
