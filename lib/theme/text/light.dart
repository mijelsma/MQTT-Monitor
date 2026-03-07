import 'package:flutter/material.dart';

TextTheme textThemeLight() => _build(Colors.black, const Color(0xFF636366));

TextTheme _build(Color base, Color secondary) => TextTheme(
  displayLarge: TextStyle(color: base, fontWeight: FontWeight.w300, letterSpacing: -1.5),
  displayMedium: TextStyle(color: base, fontWeight: FontWeight.w300, letterSpacing: -0.5),
  displaySmall: TextStyle(color: base, letterSpacing: 0),
  headlineLarge: TextStyle(color: base, fontWeight: FontWeight.w600, letterSpacing: -0.5),
  headlineMedium: TextStyle(color: base, fontWeight: FontWeight.w600, letterSpacing: -0.4),
  headlineSmall: TextStyle(color: base, fontWeight: FontWeight.w600, letterSpacing: -0.3),
  titleLarge: TextStyle(color: base, fontWeight: FontWeight.w600, letterSpacing: -0.4),
  titleMedium: TextStyle(color: base, fontWeight: FontWeight.w500, letterSpacing: -0.2),
  titleSmall: TextStyle(color: base, fontWeight: FontWeight.w500, letterSpacing: -0.1),
  bodyLarge: TextStyle(color: base, letterSpacing: -0.2),
  bodyMedium: TextStyle(color: base, letterSpacing: -0.1),
  bodySmall: TextStyle(color: secondary, letterSpacing: 0),
  labelLarge: TextStyle(color: base, fontWeight: FontWeight.w600, letterSpacing: -0.1),
  labelMedium: TextStyle(color: secondary),
  labelSmall: TextStyle(color: secondary),
);
