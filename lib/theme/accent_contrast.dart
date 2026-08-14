import 'package:flutter/material.dart';

const double _minimumTextContrast = 4.5;

/// Keeps an accent-filled control readable with white text and icons.
///
/// Dark accents are returned unchanged. Brighter accents are darkened by the
/// smallest practical amount needed to reach the normal-text contrast target.
Color accentFillForWhiteForeground(Color accent) {
  if (_contrastRatio(accent, Colors.white) >= _minimumTextContrast) {
    return accent;
  }

  var lowerBlend = 0.0;
  var upperBlend = 1.0;
  var result = Colors.black;
  for (var i = 0; i < 12; i++) {
    final blend = (lowerBlend + upperBlend) / 2;
    final candidate = Color.lerp(accent, Colors.black, blend)!;
    if (_contrastRatio(candidate, Colors.white) >= _minimumTextContrast) {
      result = candidate;
      upperBlend = blend;
    } else {
      lowerBlend = blend;
    }
  }
  return result;
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker = firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
