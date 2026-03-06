import 'package:flutter/material.dart';
import '../app_colors.dart';

TextTheme textThemeDark() => _build(AppColors.dark900);

TextTheme _build(Color base) => TextTheme(
  displayLarge: TextStyle(color: base),
  displayMedium: TextStyle(color: base),
  displaySmall: TextStyle(color: base),
  headlineLarge: TextStyle(color: base, fontWeight: FontWeight.bold),
  headlineMedium: TextStyle(color: base, fontWeight: FontWeight.bold),
  headlineSmall: TextStyle(color: base, fontWeight: FontWeight.w600),
  titleLarge: TextStyle(color: base, fontWeight: FontWeight.w600),
  titleMedium: TextStyle(color: base),
  titleSmall: TextStyle(color: base),
  bodyLarge: TextStyle(color: base),
  bodyMedium: TextStyle(color: base),
  bodySmall: TextStyle(color: base),
  labelLarge: TextStyle(color: base, fontWeight: FontWeight.w600),
  labelMedium: TextStyle(color: base),
  labelSmall: TextStyle(color: base),
);
