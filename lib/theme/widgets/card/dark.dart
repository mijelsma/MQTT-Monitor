import 'package:flutter/material.dart';
import '../../app_colors.dart';

const CardThemeData cardThemeDark = CardThemeData(
  color: AppColors.dark100,
  surfaceTintColor: Colors.transparent,
  elevation: 1,
  margin: EdgeInsets.all(8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);
