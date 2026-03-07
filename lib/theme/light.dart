import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_scheme/light.dart';
import 'app_bar/light.dart';
import 'bottom_app_bar/light.dart';
import 'divider/light.dart';
import 'icon/light.dart';
import 'card/light.dart';
import 'text/light.dart';
import 'app_tokens.dart';

final ThemeData themeLight = ThemeData(
  useMaterial3: true,
  colorScheme: colorSchemeLight,
  scaffoldBackgroundColor: AppColors.neutral50,
  appBarTheme: appBarThemeLight,
  cardTheme: cardThemeLight,
  dividerTheme: dividerThemeLight,
  iconTheme: iconThemeLight,
  bottomAppBarTheme: bottomAppBarThemeLight,
  textTheme: textThemeLight(),
  extensions: const [AppTokens.light],
);
