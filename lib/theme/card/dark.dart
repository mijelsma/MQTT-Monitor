import 'package:flutter/material.dart';
import '../app_colors.dart';

const CardThemeData cardThemeDark = CardThemeData(
  color: AppColors.dark50,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    side: BorderSide(color: Color(0xFF2E2E33), width: 0.5),
  ),
);
