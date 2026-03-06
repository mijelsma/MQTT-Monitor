import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_scheme/dark.dart';
import 'widgets/app_bar/dark.dart';
import 'widgets/card/dark.dart';
import 'text/dark.dart';

final ThemeData themeDark = ThemeData(
  useMaterial3: true,
  colorScheme: colorSchemeDark,
  scaffoldBackgroundColor: AppColors.dark0,
  appBarTheme: appBarThemeDark,
  cardTheme: cardThemeDark,
  dividerTheme: const DividerThemeData(color: AppColors.dark200),
  iconTheme: const IconThemeData(color: AppColors.primary300),
  textTheme: textThemeDark(),
);
