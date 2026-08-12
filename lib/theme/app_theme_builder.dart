import 'package:flutter/material.dart';

import 'app_tokens/app_tokens.dart';

/// Applies runtime accent choices to the static light and dark themes.
abstract final class AppThemeBuilder {
  /// Returns [base] with accessible accent foreground and interaction colors.
  static ThemeData withAccent(ThemeData base, Color accent, Brightness brightness) {
    final baseTokens = base.extension<AppTokens>()!;
    final isLight = brightness == Brightness.light;
    final onAccent = _contrastRatio(accent, Colors.black) >= _contrastRatio(accent, Colors.white) ? Colors.black : Colors.white;
    final tokens = baseTokens.copyWith(
      primary: accent,
      onPrimary: onAccent,
      selectedBg: accent.withValues(alpha: isLight ? 0.08 : 0.14),
      focusRing: accent,
    );
    final scheme = base.colorScheme.copyWith(primary: accent, onPrimary: onAccent, primaryContainer: Color.lerp(accent, isLight ? Colors.white : Colors.black, isLight ? 0.85 : 0.45)!, onPrimaryContainer: isLight ? const Color(0xFF111111) : Colors.white, inversePrimary: Color.lerp(accent, Colors.white, 0.25)!);
    return base.copyWith(colorScheme: scheme, focusColor: accent.withValues(alpha: 0.18), hoverColor: accent.withValues(alpha: 0.06), splashColor: accent.withValues(alpha: 0.10), highlightColor: accent.withValues(alpha: 0.08), extensions: <ThemeExtension<dynamic>>[tokens]);
  }

  static double _contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
    final darker = firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
