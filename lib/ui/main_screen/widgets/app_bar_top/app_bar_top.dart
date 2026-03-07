import 'package:flutter/material.dart';
import 'broker_selector.dart';
import 'settings_button.dart';

class AppBarTop extends StatelessWidget implements PreferredSizeWidget {
  const AppBarTop({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: Theme.of(context).dividerColor),
      ),
      actions: const [BrokerSelector(), SettingsButton(), SizedBox(width: 8)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);
}
