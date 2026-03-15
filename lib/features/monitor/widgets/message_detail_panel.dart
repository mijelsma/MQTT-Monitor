import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/topic_node.dart';
import '../../../models/topic_node_value.dart';
import '../../../shared/widgets/json_highlighter.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Shows the details of the currently selected MQTT message.
class MessageDetailPanel extends StatelessWidget {
  const MessageDetailPanel({super.key, required this.node});

  final TopicTreeNode node;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TopicNodeValue?>(
      valueListenable: node.valueNotifier,
      builder: (context, value, _) {
        if (value == null) {
          return _EmptyDetail(topic: node.fullPath);
        }
        return _DetailContent(node: node, value: value);
      },
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopicHeader(topic: topic),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Icon(Icons.hourglass_empty_rounded, size: 32, color: tokens.muted),
                const SizedBox(height: 12),
                Text(
                  'Waiting for messages\u2026',
                  style: TextStyle(fontSize: 13, color: tokens.textTertiary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.node, required this.value});

  final TopicTreeNode node;
  final TopicNodeValue value;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopicHeader(topic: node.fullPath),
          const SizedBox(height: 16),
          _PropertiesCard(value: value),
          const SizedBox(height: 16),
          _PayloadCard(payload: value.payload),
        ],
      ),
    );
  }
}

// ── Topic header ────────────────────────────────────────────────────────

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.tag_rounded, size: 14, color: tokens.primary.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              topic,
              style: TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12.5, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.2),
            ),
          ),
          const SizedBox(width: 8),
          _CopyButton(text: topic, size: 14),
        ],
      ),
    );
  }
}

// ── Properties card ─────────────────────────────────────────────────────

class _PropertiesCard extends StatelessWidget {
  const _PropertiesCard({required this.value});

  final TopicNodeValue value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final timeStr = _formatTime(value.receivedAt);
    final sizeStr = _formatSize(value.payload);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Column(
        children: [
          _PropertyRow(
            icon: Icons.swap_vert_rounded,
            iconColor: _qosColor(value.qos),
            label: 'QoS',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QosTag(qos: value.qos),
                const SizedBox(width: 6),
                Text(qosLabel(value.qos), style: TextStyle(fontSize: 11, color: tokens.textTertiary)),
              ],
            ),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.push_pin_rounded,
            iconColor: value.retain ? AppColors.warning500 : tokens.muted,
            label: 'Retained',
            child: value.retain
                ? Text(
                    'Yes',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning500),
                  )
                : Text('No', style: TextStyle(fontSize: 12, color: tokens.textTertiary)),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.schedule_rounded,
            iconColor: tokens.textTertiary,
            label: 'Received',
            child: Text(
              timeStr,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.straighten_rounded,
            iconColor: tokens.textTertiary,
            label: 'Size',
            child: Text(sizeStr, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.numbers_rounded,
            iconColor: tokens.primary.withValues(alpha: 0.6),
            label: 'Messages',
            child: Text(
              '#${value.seq}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.primary, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppTokens tokens) {
    return Divider(height: 0.5, thickness: 0.5, color: tokens.border, indent: 36);
  }

  static Color _qosColor(int qos) => switch (qos) {
    0 => AppColors.neutral400,
    1 => AppColors.info500,
    2 => AppColors.warning500,
    _ => AppColors.neutral400,
  };

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  static String _formatSize(String payload) {
    final bytes = utf8.encode(payload).length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.icon, required this.iconColor, required this.label, required this.child});

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: tokens.textTertiary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Payload card ────────────────────────────────────────────────────────

class _PayloadCard extends StatelessWidget {
  const _PayloadCard({required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isJson = JsonHighlighter.isJson(payload);
    final formatLabel = isJson ? 'JSON' : 'TEXT';
    final formatColor = isJson ? AppColors.success500 : tokens.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.code_rounded, size: 13, color: tokens.textTertiary),
            const SizedBox(width: 6),
            Text(
              'PAYLOAD',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: tokens.textTertiary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: formatColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(
                formatLabel,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: formatColor, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border, width: 0.5),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: JsonHighlighter(source: payload),
              ),
              Positioned(top: 0, right: 0, child: _CopyButton(text: payload, size: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Copy button ─────────────────────────────────────────────────────────

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text, this.size = 16});

  final String text;
  final double size;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  bool _hovering = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = _copied
        ? AppColors.success400
        : _hovering
        ? tokens.textPrimary
        : tokens.textTertiary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _copy,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, key: ValueKey(_copied), size: widget.size, color: color),
          ),
        ),
      ),
    );
  }
}
