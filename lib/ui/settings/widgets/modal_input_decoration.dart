import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Builds the bordered, filled [InputDecoration] used in all settings modals.
InputDecoration modalInputDecoration(BuildContext context, {required Color accent, String? hint, Widget? suffixIcon}) {
  final tokens = context.tokens;
  const radius = BorderRadius.all(Radius.circular(10));

  return InputDecoration(
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
    errorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.error500, width: 1.0),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.error500, width: 1.5),
    ),
  );
}
