import 'package:flutter/material.dart';
import '../app_colors.dart';

const AppBarTheme appBarThemeDark = AppBarTheme(
  backgroundColor: AppColors.dark0,
  foregroundColor: AppColors.neutral50,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: false,
  titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.neutral50),
  iconTheme: IconThemeData(color: AppColors.primary400),
  actionsIconTheme: IconThemeData(color: AppColors.primary400),
);
