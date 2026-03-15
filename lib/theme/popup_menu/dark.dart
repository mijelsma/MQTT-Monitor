import 'package:flutter/material.dart';
import '../app_colors.dart';

const PopupMenuThemeData popupMenuThemeDark = PopupMenuThemeData(
  color: AppColors.dark50,
  surfaceTintColor: Colors.transparent,
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    side: BorderSide(color: Color(0xFF2E2E33), width: 0.5),
  ),
);
