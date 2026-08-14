import 'package:flutter/material.dart';
import '../../theme/accent_contrast.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'spacers.dart';
import 'ui_segment_option.dart';

export 'ui_segment_option.dart';

class UiSegmentRow<T> extends StatelessWidget {
  const UiSegmentRow({super.key, required this.label, required this.options, required this.value, required this.onChanged, this.accent});

  final String label;
  final List<UiSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedAccent = accent ?? tokens.primary;
    final selectedFill = accentFillForWhiteForeground(resolvedAccent);

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
                  child: Semantics(
                    container: true,
                    label: opt.label,
                    excludeSemantics: true,
                    button: true,
                    selected: isSelected,
                    inMutuallyExclusiveGroup: true,
                    child: InkWell(
                      onTap: () => onChanged(opt.value),
                      borderRadius: BorderRadius.circular(tokens.controlRadius),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedFill : tokens.inputFill,
                          borderRadius: BorderRadius.circular(tokens.controlRadius),
                          border: Border.all(color: isSelected ? selectedFill : tokens.border, width: isSelected ? 0.5 : 1.0),
                        ),
                        child: Column(
                          children: [
                            if (opt.icon != null) ...[Icon(opt.icon, size: 20, color: isSelected ? tokens.onPrimary : tokens.textPrimary), const VSpacer(4)],
                            Text(
                              opt.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? tokens.onPrimary : tokens.textPrimary),
                            ),
                            if (opt.description != null) ...[
                              const VSpacer(2),
                              Text(
                                opt.description!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 9.5, color: isSelected ? tokens.onPrimary : tokens.textSecondary),
                              ),
                            ],
                          ],
                        ),
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
