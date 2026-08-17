import 'package:flutter/material.dart';

import '../../theme/accent_contrast.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// A small themed segmented control for compact toolbars and option rows.
class UiCompactSegment<T> extends StatelessWidget {
  const UiCompactSegment({super.key, required this.options, required this.value, required this.onChanged, this.optionKey});

  final List<UiCompactSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Key Function(T value)? optionKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final selectedFill = accentFillForWhiteForeground(tokens.primary);
    return Container(
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            Semantics(
              container: true,
              label: option.semanticsLabel ?? option.label,
              button: true,
              selected: option.value == value,
              inMutuallyExclusiveGroup: true,
              child: GestureDetector(
                key: optionKey?.call(option.value),
                onTap: () => onChanged(option.value),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: option.value == value ? selectedFill : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      option.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: option.value == value ? tokens.onPrimary : tokens.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UiCompactSegmentOption<T> {
  const UiCompactSegmentOption({required this.value, required this.label, this.semanticsLabel});

  final T value;
  final String label;
  final String? semanticsLabel;
}
