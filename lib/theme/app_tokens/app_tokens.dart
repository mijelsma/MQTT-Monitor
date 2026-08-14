import 'package:flutter/material.dart';
import '../app_colors.dart';

part 'light.dart';
part 'dark.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.elevated,
    required this.inputFill,
    required this.primary,
    required this.onPrimary,
    required this.selectedBg,
    required this.border,
    required this.muted,
    required this.success,
    required this.warning,
    required this.info,
    required this.error,
    required this.focusRing,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.controlRadius,
    required this.panelRadius,
  });

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

  /// Positive state such as a connected broker or valid payload.
  final Color success;

  /// Caution state such as retained data or a connection in progress.
  final Color warning;

  /// Informational state that is not the current brand accent.
  final Color info;

  /// Destructive / error accent — delete buttons, validation errors.
  final Color error;

  /// Keyboard focus outline for interactive controls.
  final Color focusRing;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Radius shared by buttons, fields, rows, and segmented controls.
  final double controlRadius;

  /// Radius shared by cards, notices, and modal surfaces.
  final double panelRadius;

  // Preset instances for light mode and dark mode.
  static const AppTokens light = _lightTokens;
  static const AppTokens dark = _darkTokens;

  @override
  AppTokens copyWith({Color? bg, Color? surface, Color? elevated, Color? inputFill, Color? primary, Color? onPrimary, Color? selectedBg, Color? border, Color? muted, Color? success, Color? warning, Color? info, Color? error, Color? focusRing, Color? textPrimary, Color? textSecondary, Color? textTertiary, double? controlRadius, double? panelRadius}) =>
      AppTokens(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        elevated: elevated ?? this.elevated,
        inputFill: inputFill ?? this.inputFill,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        selectedBg: selectedBg ?? this.selectedBg,
        border: border ?? this.border,
        muted: muted ?? this.muted,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        error: error ?? this.error,
        focusRing: focusRing ?? this.focusRing,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        controlRadius: controlRadius ?? this.controlRadius,
        panelRadius: panelRadius ?? this.panelRadius,
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
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      error: Color.lerp(error, other.error, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      controlRadius: controlRadius + (other.controlRadius - controlRadius) * t,
      panelRadius: panelRadius + (other.panelRadius - panelRadius) * t,
    );
  }
}

/// Shortcut: `context.tokens.bg`, `context.tokens.textPrimary`, etc.
extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
