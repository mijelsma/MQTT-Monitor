import 'package:flutter/material.dart';

import '../../../core/mqtt/connection_status.dart';
import '../../../core/mqtt/models/mqtt_protocol_version_model.dart';
import '../../../generated/l10n.dart';
import '../../../theme/app_tokens/app_tokens.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key, this.status = ConnectionStatus.disconnected, this.brokerUrl, this.messageCount = 0, this.messageRate = 0, this.activeProtocol, this.showUpdateAvailable = false, this.onUpdateAvailable});

  final ConnectionStatus status;
  final String? brokerUrl;
  final int messageCount;
  final int messageRate;

  /// The protocol actually negotiated with the broker. Only shown when
  /// connected (or connecting) — disconnected status hides the chip.
  final MqttProtocolVersionModel? activeProtocol;

  /// True after the background check finds a newer compatible release.
  final bool showUpdateAvailable;
  final VoidCallback? onUpdateAvailable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant, letterSpacing: -0.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1.0, color: Theme.of(context).dividerColor),
        BottomAppBar(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatusPill(status: status),
              if (activeProtocol != null) ...[const SizedBox(width: 6), _ProtocolChip(protocol: activeProtocol!)],
              const SizedBox(width: 8),
              if (brokerUrl != null)
                Expanded(
                  child: Text(brokerUrl!, style: labelStyle, overflow: TextOverflow.ellipsis),
                )
              else
                const Spacer(),
              if (showUpdateAvailable) ...[const SizedBox(width: 10), _UpdateAvailableBadge(onTap: onUpdateAvailable)],
              const SizedBox(width: 8),
              Text(S.of(context).statusMessages(messageCount, messageRate), style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpdateAvailableBadge extends StatelessWidget {
  const _UpdateAvailableBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Tooltip(
      message: S.of(context).statusOpenUpdateSettings,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(color: tokens.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update_alt_rounded, size: 11, color: tokens.info),
              SizedBox(width: 4),
              Text(
                S.of(context).statusUpdateAvailable,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tokens.info, letterSpacing: -0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = S.of(context);
    var (color, label) = switch (status) {
      ConnectionStatus.connected => (tokens.success, strings.statusConnected),
      ConnectionStatus.connecting => (tokens.warning, strings.statusConnecting),
      ConnectionStatus.disconnected => (tokens.error, strings.statusDisconnected),
      ConnectionStatus.errorHostNotFound => (tokens.error, strings.statusHostNotFound),
      ConnectionStatus.errorNotPermitted => (tokens.error, strings.statusNotPermitted),
      ConnectionStatus.errorRefused => (tokens.error, strings.statusConnectionRefused),
      ConnectionStatus.errorTlsHandshake => (tokens.error, strings.statusTlsFailed),
      ConnectionStatus.error => (tokens.error, strings.statusError),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}

/// Small "MQTT 5" / "MQTT 3" chip in the status bar. The build
/// spec requires the UI to clearly show which protocol is in use on the
/// current connection.
class _ProtocolChip extends StatelessWidget {
  const _ProtocolChip({required this.protocol});

  final MqttProtocolVersionModel protocol;

  @override
  Widget build(BuildContext context) {
    final isFallback = protocol == MqttProtocolVersionModel.v311;
    final tokens = context.tokens;
    final strings = S.of(context);
    final color = isFallback ? tokens.warning : tokens.info;
    return Tooltip(
      message: switch (protocol) {
        MqttProtocolVersionModel.v5 => strings.statusMqtt5Detail,
        MqttProtocolVersionModel.v311 => strings.statusMqtt311Detail,
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 9, color: color),
            const SizedBox(width: 3),
            Text(
              protocol.shortLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.1),
            ),
          ],
        ),
      ),
    );
  }
}
