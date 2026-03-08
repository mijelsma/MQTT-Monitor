import 'package:flutter/material.dart';
import '../app_colors.dart';

part 'light.dart';
part 'dark.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({required this.bg, required this.surface, required this.elevated, required this.inputFill, required this.primary, required this.onPrimary, required this.selectedBg, required this.border, required this.muted, required this.error, required this.textPrimary, required this.textSecondary, required this.textTertiary});

  /// Scaffold / page background.
  final Color bg;

  /// Card / panel background (one step above [bg]).
  final Color surface;

  /// Slightly raised surface — nested containers.
  final Color elevated;

  /// Background fill for text inputs and selection cards.
  final Color inputFill;

  /// Interactive brand/accent color — buttons, active states, tinted fills.
  final Color primary;

  /// Text / icon color for content placed on a [primary]-filled surface.
  final Color onPrimary;

  /// Sidebar / list selected-item background.
  final Color selectedBg;

  /// Dividers and border strokes.
  final Color border;

  /// Placeholder icons / muted decorative elements.
  final Color muted;

  /// Destructive / error accent — delete buttons, validation errors.
  final Color error;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Preset instances for light mode and dark mode.
  static const AppTokens light = _lightTokens;
  static const AppTokens dark = _darkTokens;

  @override
  AppTokens copyWith({Color? bg, Color? surface, Color? elevated, Color? inputFill, Color? primary, Color? onPrimary, Color? selectedBg, Color? border, Color? muted, Color? error, Color? textPrimary, Color? textSecondary, Color? textTertiary}) => AppTokens(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    elevated: elevated ?? this.elevated,
    inputFill: inputFill ?? this.inputFill,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    selectedBg: selectedBg ?? this.selectedBg,
    border: border ?? this.border,
    muted: muted ?? this.muted,
    error: error ?? this.error,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
  );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      selectedBg: Color.lerp(selectedBg, other.selectedBg, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      error: Color.lerp(error, other.error, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}

/// Shortcut: `context.tokens.bg`, `context.tokens.textPrimary`, etc.
extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
