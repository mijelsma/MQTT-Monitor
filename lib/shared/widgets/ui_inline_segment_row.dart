import 'package:flutter/material.dart';

import '../../theme/accent_contrast.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'spacers.dart';
import 'ui_inline_segment_option.dart';

export 'ui_inline_segment_option.dart';

/// A compact, inline segmented selector for a small enum of options.
///
/// Unlike [UiSegmentRow] — which gives each option an equal share of the
/// full row width — this lays the options out as a tight pill-track on the
/// right, leaving the left side for an optional leading icon, a label,
/// and an optional subtitle. Use it for settings where the value set is
/// small and the row should stay on a single line (e.g. "Collapsed /
/// Expanded / Last Status", or "Q0 / Q1 / Q2 / Last used").
class UiInlineSegmentRow<T> extends StatelessWidget {
  const UiInlineSegmentRow({super.key, this.icon, required this.label, this.subtitle, this.footer, this.accent, required this.options, required this.value, required this.onChanged});

  /// Optional leading icon shown before the label. Pass an [Icon] for a
  /// stock glyph, or any widget for a custom badge.
  final Widget? icon;

  final String label;
  final String? subtitle;

  /// Optional widget rendered below the row (e.g. a dynamic hint that
  /// depends on the current [value]).
  final Widget? footer;

  /// Accent color for the selected chip. Defaults to the theme primary.
  final Color? accent;

  final List<UiInlineSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedAccent = accent ?? tokens.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[IconTheme(data: const IconThemeData(size: 16), child: icon!), const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[const VSpacer(2), Text(subtitle!, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary))],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _InlineSegmentTrack<T>(accent: resolvedAccent, options: options, value: value, onChanged: onChanged),
            ],
          ),
          if (footer != null) ...[
            const VSpacer(8),
            Padding(
              padding: const EdgeInsets.only(left: 0),
              child: DefaultTextStyle.merge(
                style: TextStyle(fontSize: 10.5, color: tokens.textTertiary, fontStyle: FontStyle.italic),
                child: footer!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineSegmentTrack<T> extends StatelessWidget {
  const _InlineSegmentTrack({required this.accent, required this.options, required this.value, required this.onChanged});

  final Color accent;
  final List<UiInlineSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < options.length; i++) ...[_InlineSegmentChip<T>(option: options[i], selected: options[i].value == value, accent: accent, onTap: () => onChanged(options[i].value)), if (i < options.length - 1) const SizedBox(width: 2)],
        ],
      ),
    );
  }
}

class _InlineSegmentChip<T> extends StatelessWidget {
  const _InlineSegmentChip({required this.option, required this.selected, required this.accent, required this.onTap});

  final UiInlineSegmentOption<T> option;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = selected ? tokens.onPrimary : tokens.textPrimary;
    final selectedFill = accentFillForWhiteForeground(accent);
    return Semantics(
      container: true,
      label: option.label,
      excludeSemantics: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.controlRadius - 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: selected ? selectedFill : Colors.transparent, borderRadius: BorderRadius.circular(tokens.controlRadius - 2)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                IconTheme(
                  data: IconThemeData(size: 15, color: fg),
                  child: option.icon!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                option.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
