import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_scheme/light.dart';
import 'widgets/app_bar/light.dart';
import 'widgets/card/light.dart';
import 'text/light.dart';

final ThemeData themeLight = ThemeData(
  useMaterial3: true,
  colorScheme: colorSchemeLight,
  scaffoldBackgroundColor: AppColors.neutral50,
  appBarTheme: appBarThemeLight,
  cardTheme: cardThemeLight,
  dividerColor: AppColors.neutral200,
  iconTheme: const IconThemeData(color: AppColors.primary500),
  textTheme: textThemeLight(),
);
