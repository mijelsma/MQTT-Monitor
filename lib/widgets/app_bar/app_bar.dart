import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, required this.title});

  final String title;
  final double headerHeight = kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        PopupMenuButton<int>(
          onSelected: (value) => {},
          itemBuilder: (context) {
            return [
              const PopupMenuItem(value: 0, child: Text("Option 1")),
              const PopupMenuItem(value: 1, child: Text("Option 2")),
            ];
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Select Broker"),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        Container(
          width: 2,
          height: IconTheme.of(context).size ?? 50.0,
          color: Theme.of(context).dividerTheme.color,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: "Settings",
          onPressed: () {},
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(headerHeight);
}
