import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';

enum UiNoticeKind { error, warning, success, info }

class _NoticeStyle {
  const _NoticeStyle(this.color, this.icon);
  final Color color;
  final IconData icon;
}

const _styles = <UiNoticeKind, _NoticeStyle>{
  UiNoticeKind.error: _NoticeStyle(AppColors.error500, Icons.cloud_off_rounded),
  UiNoticeKind.warning: _NoticeStyle(AppColors.warning500, Icons.history_rounded),
  UiNoticeKind.success: _NoticeStyle(AppColors.success500, Icons.check_circle_rounded),
  UiNoticeKind.info: _NoticeStyle(AppColors.info500, Icons.info_outline_rounded),
};

/// A reusable themed banner for inline notifications: invalid certificate,
/// connection failure, historical view, etc.
///
/// Variants ([UiNoticeKind]) drive the icon and colour palette so all
/// inline notices across the app share the same look.
///
/// Use the optional [title] for a short headline, [message] for the body,
/// [selectable] to make the body copyable, [onDismiss] to show an X,
/// and [actionLabel] / [onAction] for an inline action button.
class UiInlineNotice extends StatelessWidget {
  const UiInlineNotice({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.subtitle,
    this.selectable = false,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
    this.margin,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 8, 10),
    this.radius = 12,
  });

  final UiNoticeKind kind;
  final String? title;
  final String? message;

  /// Optional muted line between [title] and [message], e.g. the broker
  /// the error belongs to. Truncated with an ellipsis.
  final String? subtitle;

  /// Make [message] selectable (for copying long error details).
  final bool selectable;

  /// Show a dismiss (X) button. Null = no dismiss affordance.
  final VoidCallback? onDismiss;

  /// Inline action button label — requires [onAction] to render.
  final String? actionLabel;
  final VoidCallback? onAction;

  final EdgeInsets? margin;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = _styles[kind]!;
    final color = style.color;
    final icon = style.icon;

    final body = <Widget>[];
    if (title != null) {
      body.add(
        Text(title!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
      );
    }
    if (subtitle != null) {
      body.add(const SizedBox(height: 1));
      body.add(
        Text(subtitle!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tokens.textSecondary), overflow: TextOverflow.ellipsis),
      );
    }
    if (message != null) {
      if (title != null || subtitle != null) body.add(const SizedBox(height: 4));
      body.add(
        selectable
            ? SelectableText(message!, style: TextStyle(fontSize: 12, height: 1.35, color: tokens.textPrimary.withValues(alpha: 0.85)))
            : Text(message!, style: TextStyle(fontSize: 12, height: 1.35, color: tokens.textPrimary.withValues(alpha: 0.85))),
      );
    }

    final children = <Widget>[
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: body)),
    ];

    if (actionLabel != null && onAction != null) {
      children.add(const SizedBox(width: 8));
      children.add(_ActionButton(label: actionLabel!, onTap: onAction!));
    }

    if (onDismiss != null) {
      children.add(const SizedBox(width: 4));
      children.add(
        IconButton(
          onPressed: onDismiss,
          tooltip: 'Dismiss',
          visualDensity: VisualDensity.compact,
          splashRadius: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: Icon(Icons.close_rounded, size: 16, color: tokens.textSecondary),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.10), tokens.surface),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      padding: padding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tokens.border, width: 0.5),
          ),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tokens.textSecondary)),
        ),
      ),
    );
  }
}