import 'package:flutter/material.dart';

class BrokerSelector extends StatelessWidget {
  const BrokerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
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
          children: [Text("Select Broker"), const Icon(Icons.arrow_drop_down)],
        ),
      ),
    );
  }
}
