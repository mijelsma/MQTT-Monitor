import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Resolved semantic colour tokens for the current theme.
///
/// Registered on [ThemeData] via `extensions: const [AppTokens.light]` /
/// `extensions: const [AppTokens.dark]` and accessed with `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.muted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  /// Scaffold / page background.
  final Color bg;

  /// Card / panel background (one step above [bg]).
  final Color surface;

  /// Slightly raised surface — input fills, nested containers.
  final Color elevated;

  /// Dividers and border strokes.
  final Color border;

  /// Placeholder icons / muted decorative elements.
  final Color muted;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ── Preset instances ──────────────────────────────────────────────────────

  static const AppTokens light = AppTokens(
    bg: AppColors.neutral50,
    surface: AppColors.neutral0,
    elevated: AppColors.neutral100,
    border: AppColors.neutral200,
    muted: AppColors.neutral400,
    textPrimary: Color(0xFF0F0F11),
    textSecondary: AppColors.neutral500,
    textTertiary: AppColors.neutral400,
  );

  static const AppTokens dark = AppTokens(
    bg: AppColors.dark0,
    surface: AppColors.dark50,
    elevated: AppColors.dark100,
    border: Color(0xFF2E2E33),
    muted: AppColors.neutral500,
    textPrimary: AppColors.neutral50,
    textSecondary: AppColors.neutral400,
    textTertiary: AppColors.neutral600,
  );

  // ── ThemeExtension boilerplate ────────────────────────────────────────────

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? elevated,
    Color? border,
    Color? muted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) => AppTokens(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    elevated: elevated ?? this.elevated,
    border: border ?? this.border,
    muted: muted ?? this.muted,
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
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
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
