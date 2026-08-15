import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_scheme/light.dart';
import 'app_bar/light.dart';
import 'bottom_app_bar/light.dart';
import 'divider/light.dart';
import 'icon/light.dart';
import 'card/light.dart';
import 'popup_menu/light.dart';
import 'text/light.dart';
import 'app_tokens/app_tokens.dart';
import 'ui_layout.dart';

final ThemeData themeLight = ThemeData(
  useMaterial3: true,
  colorScheme: colorSchemeLight,
  scaffoldBackgroundColor: AppColors.neutral50,
  appBarTheme: appBarThemeLight,
  cardTheme: cardThemeLight,
  popupMenuTheme: popupMenuThemeLight,
  dividerTheme: dividerThemeLight,
  iconTheme: iconThemeLight,
  bottomAppBarTheme: bottomAppBarThemeLight,
  textTheme: textThemeLight(),
  extensions: const [AppTokens.light, UiLayout.comfortable],
);
