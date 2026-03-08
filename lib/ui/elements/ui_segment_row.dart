import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../widgets/spacers.dart';

class UiSegmentOption<T> {
  const UiSegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;

  /// Optional icon displayed above the label inside the chip.
  final IconData? icon;
}

class UiSegmentRow<T> extends StatelessWidget {
  const UiSegmentRow({super.key, required this.label, required this.options, required this.value, required this.onChanged, this.accent});

  final String label;
  final List<UiSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Falls back to [context.tokens.primary].
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedAccent = accent ?? tokens.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const VSpacer(10),
          Row(
            children: options.map((opt) {
              final isSelected = opt.value == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onChanged(opt.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? resolvedAccent : tokens.elevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? resolvedAccent : tokens.border, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          if (opt.icon != null) ...[Icon(opt.icon, size: 20, color: isSelected ? Colors.white : tokens.textSecondary), const VSpacer(4)],
                          Text(
                            opt.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
