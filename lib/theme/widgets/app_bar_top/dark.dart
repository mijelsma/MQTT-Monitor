import 'package:flutter/material.dart';
import '../../app_colors.dart';

const AppBarTheme appBarTopThemeDark = AppBarTheme(
  backgroundColor: AppColors.dark50,
  foregroundColor: AppColors.dark900,
  elevation: 0,
  scrolledUnderElevation: 1,
  centerTitle: false,
  titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.dark900,
  ),
  iconTheme: IconThemeData(color: AppColors.dark900),
  actionsIconTheme: IconThemeData(color: AppColors.dark900),
);
