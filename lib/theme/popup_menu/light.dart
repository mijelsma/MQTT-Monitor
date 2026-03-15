import 'package:flutter/material.dart';
import '../app_colors.dart';

const PopupMenuThemeData popupMenuThemeLight = PopupMenuThemeData(
  color: AppColors.neutral0,
  surfaceTintColor: Colors.transparent,
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    side: BorderSide(color: AppColors.neutral200, width: 0.5),
  ),
);
