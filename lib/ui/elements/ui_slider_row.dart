import 'package:flutter/material.dart';
import 'package:mqtt_monitor/ui/widgets/spacers.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// A labelled slider row that fits inside a [UiSection].
///
/// Shows a label + current-value badge on the first line, an optional subtitle
/// on the second, and the slider beneath both.  Min/max labels flank the
/// slider track.
class UiSliderRow extends StatelessWidget {
  const UiSliderRow({super.key, required this.label, this.subtitle, required this.value, required this.min, required this.max, required this.divisions, required this.displayValue, required this.onChanged, this.accent});

  final String label;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;

  /// Formatted string shown in the value badge, e.g. `"10 pps"` or `"750 ms"`.
  final String displayValue;

  final ValueChanged<double> onChanged;

  /// Defaults to [context.tokens.primary].
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedAccent = accent ?? tokens.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label row ──────────────────────────────────────────────────
          Row(
            children: [
              // Label + optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[const SizedBox(height: 1), Text(subtitle!, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary))],
                  ],
                ),
              ),

              // Value badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: resolvedAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: resolvedAccent.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: resolvedAccent, letterSpacing: 0.1),
                ),
              ),
            ],
          ),

          // Slider
          SliderTheme(
            data: SliderTheme.of(
              context,
            ).copyWith(activeTrackColor: resolvedAccent, inactiveTrackColor: resolvedAccent.withValues(alpha: 0.15), thumbColor: resolvedAccent, overlayColor: resolvedAccent.withValues(alpha: 0.1), trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),

          // Min / Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(min), style: TextStyle(fontSize: 10.5, color: tokens.textTertiary)),
                Text(_format(max), style: TextStyle(fontSize: 10.5, color: tokens.textTertiary)),
              ],
            ),
          ),
          const VSpacer(4),
        ],
      ),
    );
  }

  String _format(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}
