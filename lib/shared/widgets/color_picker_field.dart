import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'spacers.dart';

/// A labeled field that shows a row of color swatches.
/// The user taps one to select it; [onChanged] fires with the new [Color].
class ColorPickerField extends StatelessWidget {
  const ColorPickerField({super.key, this.margin, required this.label, required this.value, required this.onChanged});

  final EdgeInsetsGeometry? margin;
  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const VSpacer(6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in AppColors.brokerColorOptions)
              GestureDetector(
                onTap: () => onChanged(color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    border: color.toARGB32() == value.toARGB32() ? Border.all(color: tokens.textPrimary, width: 2) : null,
                  ),
                  child: color.toARGB32() == value.toARGB32() ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                ),
              ),
          ],
        ),
      ],
    );
    if (margin != null) content = Padding(padding: margin!, child: content);
    return content;
  }
}
