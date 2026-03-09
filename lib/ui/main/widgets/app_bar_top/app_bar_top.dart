import 'package:flutter/material.dart';
import 'package:mqtt_monitor/ui/widgets/spacers.dart';
import 'broker_selector.dart';
import 'settings_button.dart';

class AppBarTop extends StatelessWidget implements PreferredSizeWidget {
  const AppBarTop({super.key});

  static const double _toolbarHeight = 62;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: null,
      toolbarHeight: _toolbarHeight,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: Theme.of(context).dividerColor),
      ),
      actions: const [BrokerSelector(), HSpacer(8), SettingsButton(), HSpacer(8)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight + 0.5);
}
