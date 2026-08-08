import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary colors
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary300 = Color(0xFFA5B4FC);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF3730A3);
  static const Color primary900 = Color(0xFF312E81);

  // Secondary colors
  static const Color secondary50 = Color(0xFFECFEFF);
  static const Color secondary100 = Color(0xFFCFFAFE);
  static const Color secondary200 = Color(0xFFA5F3FC);
  static const Color secondary300 = Color(0xFF67E8F9);
  static const Color secondary400 = Color(0xFF22D3EE);
  static const Color secondary500 = Color(0xFF06B6D4);
  static const Color secondary600 = Color(0xFF0891B2);
  static const Color secondary700 = Color(0xFF0E7490);
  static const Color secondary800 = Color(0xFF155E75);
  static const Color secondary900 = Color(0xFF164E63);

  // Success scale
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success100 = Color(0xFFDCFCE7);
  static const Color success200 = Color(0xFFBBF7D0);
  static const Color success300 = Color(0xFF86EFAC);
  static const Color success400 = Color(0xFF4ADE80);
  static const Color success500 = Color(0xFF22C55E);
  static const Color success600 = Color(0xFF16A34A);
  static const Color success700 = Color(0xFF15803D);

  // Warning scale
  static const Color warning50 = Color(0xFFFFFBEB);
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning200 = Color(0xFFFDE68A);
  static const Color warning300 = Color(0xFFFCD34D);
  static const Color warning400 = Color(0xFFFBBF24);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);

  // Error scale
  static const Color error50 = Color(0xFFFEF2F2);
  static const Color error100 = Color(0xFFFEE2E2);
  static const Color error200 = Color(0xFFFECACA);
  static const Color error300 = Color(0xFFFCA5A5);
  static const Color error400 = Color(0xFFF87171);
  static const Color error500 = Color(0xFFEF4444);
  static const Color error600 = Color(0xFFDC2626);
  static const Color error700 = Color(0xFFB91C1C);

  // Info scale
  static const Color info50 = Color(0xFFEFF6FF);
  static const Color info100 = Color(0xFFDBEAFE);
  static const Color info200 = Color(0xFFBFDBFE);
  static const Color info300 = Color(0xFF93C5FD);
  static const Color info400 = Color(0xFF60A5FA);
  static const Color info500 = Color(0xFF3B82F6);
  static const Color info600 = Color(0xFF2563EB);
  static const Color info700 = Color(0xFF1D4ED8);

  // Neutral scale (light-mode greys)
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF4F4F5);
  static const Color neutral200 = Color(0xFFE4E4E7);
  static const Color neutral300 = Color(0xFFD4D4D8);
  static const Color neutral400 = Color(0xFFA1A1AA);
  static const Color neutral500 = Color(0xFF71717A);
  static const Color neutral600 = Color(0xFF52525B);
  static const Color neutral700 = Color(0xFF3F3F46);
  static const Color neutral800 = Color(0xFF27272A);
  static const Color neutral900 = Color(0xFF18181B);

  static const Color dark0 = Color(0xFF09090B);
  static const Color dark50 = Color(0xFF18181B);
  static const Color dark100 = Color(0xFF27272A);
  static const Color dark200 = Color(0xFF3F3F46);
  static const Color dark300 = Color(0xFF52525B);
  static const Color dark400 = Color(0xFF71717A);
  static const Color dark500 = Color(0xFFA1A1AA);
  static const Color dark600 = Color(0xFFD4D4D8);
  static const Color dark700 = Color(0xFFE4E4E7);
  static const Color dark800 = Color(0xFFF4F4F5);
  static const Color dark900 = Color(0xFFFAFAFA);

  static const List<Color> brokerGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)];

  /// Predefined broker icon color options.
  static const List<Color> brokerColorOptions = [
    Color(0xFF6366F1), // Indigo (default)
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFF22C55E), // Green
    Color(0xFF10B981), // Emerald
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0EA5E9), // Sky
    Color(0xFF3B82F6), // Blue
  ];

  /// Returns the index of [color] in [brokerColorOptions], or 0 if not found.
  static int colorIndex(Color color) {
    final idx = brokerColorOptions.indexWhere((o) => o.toARGB32() == color.toARGB32());
    return idx < 0 ? 0 : idx;
  }

  /// Returns a two-stop gradient for a broker given its [colorIndex].
  static List<Color> brokerGradientFor(int? colorIndex) {
    final base = brokerColorOptions[(colorIndex ?? 0).clamp(0, brokerColorOptions.length - 1)];
    final light = Color.lerp(base, Colors.white, 0.25)!;
    return [base, light];
  }

  static const List<Color> subscriptionsGradient = [Color(0xFF0EA5E9), Color(0xFF6366F1)];
  static const List<Color> messagesGradient = [Color(0xFF10B981), Color(0xFF0EA5E9)];
  static const List<Color> languageGradient = [Color(0xFF0EA5E9), Color(0xFF06B6D4)];
  static const List<Color> uiGradient = [Color(0xFFF59E0B), Color(0xFFEF4444)];
  static const List<Color> aboutGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> dashboardGradient = [Color(0xFFEC4899), Color(0xFFF43F5E)];
  static const List<Color> variablesGradient = [Color(0xFF8B5CF6), Color(0xFFA78BFA)];
  static const List<Color> shortcutsGradient = [Color(0xFFF59E0B), Color(0xFFF97316)];
  static const List<Color> monitoringGradient = [Color(0xFF06B6D4), Color(0xFF10B981)];
  static const List<Color> advancedGradient = [Color(0xFFEF4444), Color(0xFFDC2626)];
}
