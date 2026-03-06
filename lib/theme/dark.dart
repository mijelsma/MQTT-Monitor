import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_scheme/dark.dart';
import 'widgets/app_bar_top/dark.dart';
import 'widgets/card/dark.dart';
import 'widgets/app_bar_bottom/dark.dart';
import 'text/dark.dart';

final ThemeData themeDark = ThemeData(
  useMaterial3: true,
  colorScheme: colorSchemeDark,
  scaffoldBackgroundColor: AppColors.dark0,
  appBarTheme: appBarTopThemeDark,
  cardTheme: cardThemeDark,
  dividerTheme: const DividerThemeData(color: AppColors.dark200),
  iconTheme: const IconThemeData(color: AppColors.primary300),
  bottomAppBarTheme: appBarBottomThemeDark,
  textTheme: textThemeDark(),
);
