import 'package:flutter/material.dart';

import 'broker_selector.dart';
import 'settings_button.dart';

class AppBarTop extends StatelessWidget implements PreferredSizeWidget {
  const AppBarTop({super.key, required this.title});

  final String title;
  final double headerHeight = kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        const BrokerSelector(),
        Container(
          width: 2,
          height: IconTheme.of(context).size ?? 24.0,
          color: Theme.of(context).dividerTheme.color,
        ),
        const SettingsButton(),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(headerHeight);
}
