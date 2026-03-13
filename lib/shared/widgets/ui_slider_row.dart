import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'spacers.dart';

class UiSliderRow extends StatelessWidget {
  const UiSliderRow({super.key, required this.label, this.subtitle, required this.value, required this.min, required this.max, required this.divisions, required this.displayValue, required this.onChanged, this.accent});

  final String label;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[const SizedBox(height: 1), Text(subtitle!, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary))],
                  ],
                ),
              ),
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
          SliderTheme(
            data: SliderTheme.of(
              context,
            ).copyWith(activeTrackColor: resolvedAccent, inactiveTrackColor: resolvedAccent.withValues(alpha: 0.15), thumbColor: resolvedAccent, overlayColor: resolvedAccent.withValues(alpha: 0.1), trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
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
