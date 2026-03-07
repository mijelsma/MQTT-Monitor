import 'package:flutter/material.dart';
import '../app_colors.dart';

const AppBarTheme appBarThemeLight = AppBarTheme(
  backgroundColor: AppColors.neutral0,
  foregroundColor: Color(0xFF0F0F11),
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: false,
  titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: Color(0xFF0F0F11)),
  iconTheme: IconThemeData(color: AppColors.primary500),
  actionsIconTheme: IconThemeData(color: AppColors.primary500),
);
