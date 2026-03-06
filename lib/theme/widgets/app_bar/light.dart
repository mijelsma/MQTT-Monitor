import 'package:flutter/material.dart';
import '../../app_colors.dart';

const AppBarTheme appBarThemeLight = AppBarTheme(
  backgroundColor: AppColors.primary500,
  foregroundColor: AppColors.neutral0,
  elevation: 0,
  scrolledUnderElevation: 1,
  centerTitle: false,
  titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.neutral0,
  ),
  iconTheme: IconThemeData(color: AppColors.neutral0),
  actionsIconTheme: IconThemeData(color: AppColors.neutral0),
);
