import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_scheme/dark.dart';
import 'app_bar/dark.dart';
import 'bottom_app_bar/dark.dart';
import 'divider/dark.dart';
import 'icon/dark.dart';
import 'card/dark.dart';
import 'text/dark.dart';
import 'app_tokens.dart';

final ThemeData themeDark = ThemeData(
  useMaterial3: true,
  colorScheme: colorSchemeDark,
  scaffoldBackgroundColor: AppColors.dark0,
  appBarTheme: appBarThemeDark,
  cardTheme: cardThemeDark,
  dividerTheme: dividerThemeDark,
  iconTheme: iconThemeDark,
  bottomAppBarTheme: bottomAppBarThemeDark,
  textTheme: textThemeDark(),
  extensions: const [AppTokens.dark],
);
