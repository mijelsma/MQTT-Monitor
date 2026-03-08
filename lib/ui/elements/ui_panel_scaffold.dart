import 'package:flutter/material.dart';
import '../widgets/spacers.dart';

class UiPanelScaffold extends StatelessWidget {
  const UiPanelScaffold({super.key, required this.title, this.description, required this.children});

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final body = <Widget>[
      Text(title, style: theme.textTheme.headlineSmall),
      if (description != null) ...[const VSpacer(6), Text(description!, style: theme.textTheme.bodySmall)],
    ];

    for (final child in children) {
      body.add(const VSpacer(20));
      body.add(child);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
    );
  }
}
