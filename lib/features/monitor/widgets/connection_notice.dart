import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/mqtt/connection_status.dart';
import '../../../shared/widgets/ui_inline_notice.dart';
import '../monitor_viewmodel.dart';

class ConnectionNotice extends StatefulWidget {
  const ConnectionNotice({super.key});

  @override
  State<ConnectionNotice> createState() => _ConnectionNoticeState();
}

class _ConnectionNoticeState extends State<ConnectionNotice> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String? _dismissedSignature;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 220), vsync: this);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    final status = vm.connectionStatus;
    final error = vm.connectionError;
    final detail = vm.connectionErrorDetail;
    final broker = vm.activeBroker;

    final signature = _signature(status, error, detail);
    final visible = _shouldShow(status, error) && _dismissedSignature != signature;

    if (visible) {
      if (!_controller.isCompleted) _controller.forward();
    } else {
      if (!_controller.isDismissed) _controller.reverse();
      if (!_shouldShow(status, error)) {
        _dismissedSignature = null;
      }
    }

    if (!visible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    final title = _title(status);
    final where = broker == null ? null : '${broker.name} · ${broker.displayAddress}';
    final why = _why(status, error);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: UiInlineNotice(kind: UiNoticeKind.error, title: title, subtitle: where, message: why, selectable: true, detail: detail, onDismiss: () => setState(() => _dismissedSignature = signature), margin: const EdgeInsets.fromLTRB(12, 10, 12, 0)),
      ),
    );
  }

  bool _shouldShow(ConnectionStatus status, String? error) {
    switch (status) {
      case ConnectionStatus.error:
      case ConnectionStatus.errorTlsHandshake:
      case ConnectionStatus.errorHostNotFound:
      case ConnectionStatus.errorNotPermitted:
      case ConnectionStatus.errorRefused:
        return true;
      case ConnectionStatus.disconnected:
        return error != null && error.trim().isNotEmpty;
      default:
        return false;
    }
  }

  String _signature(ConnectionStatus status, String? error, String? detail) => '${status.name}::${error ?? ''}::${detail ?? ''}';

  String _title(ConnectionStatus status) => switch (status) {
    ConnectionStatus.errorTlsHandshake => 'TLS handshake failed',
    ConnectionStatus.errorHostNotFound => 'Host not found',
    ConnectionStatus.errorNotPermitted => 'Connection blocked',
    ConnectionStatus.errorRefused => 'Connection refused',
    ConnectionStatus.error => 'Connection failed',
    ConnectionStatus.disconnected => 'Disconnected',
    _ => 'Connection issue',
  };

  String _why(ConnectionStatus status, String? error) {
    final trimmed = error?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return switch (status) {
      ConnectionStatus.errorTlsHandshake => 'The TLS handshake with the broker could not be completed. Check the broker certificate and your mTLS credentials.',
      ConnectionStatus.errorHostNotFound => 'The broker hostname could not be resolved. Verify the address and your network.',
      ConnectionStatus.errorRefused => 'The broker refused the connection. Make sure it is running and listening on the configured port.',
      ConnectionStatus.errorNotPermitted => 'The operating system blocked the connection. Check your firewall or network permissions.',
      _ => 'Check the broker address, port, credentials, and TLS settings.',
    };
  }
}
