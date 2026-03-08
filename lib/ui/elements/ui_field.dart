import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../widgets/spacers.dart';

class UiField extends StatelessWidget {
  const UiField({
    super.key,
    required this.label,
    this.optional = false,
    // Text field shortcuts
    this.controller,
    this.hint,
    this.validator,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.style,
    // Override: supply a fully custom widget instead of building a TextFormField
    this.child,
  });

  final String label;
  final bool optional;

  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final TextStyle? style;

  /// If provided, renders this widget instead of building a [TextFormField].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = tokens.primary;
    const radius = BorderRadius.all(Radius.circular(10));

    final field =
        child ??
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          style: style,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            isDense: true,
            filled: true,
            fillColor: tokens.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: tokens.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: tokens.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: tokens.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: tokens.error, width: 1.5),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            if (optional) ...[const SizedBox(width: 6), Text('optional', style: TextStyle(fontSize: 11, color: tokens.textSecondary))],
          ],
        ),
        const VSpacer(6),
        field,
      ],
    );
  }
}
