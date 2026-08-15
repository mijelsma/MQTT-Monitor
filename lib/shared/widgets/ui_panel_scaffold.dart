import 'package:flutter/material.dart';

import '../../theme/ui_layout.dart';
import 'spacers.dart';

class UiPanelScaffold extends StatelessWidget {
  const UiPanelScaffold({super.key, required this.title, this.description, this.descriptionStyle, required this.children});

  final String title;
  final String? description;
  final TextStyle? descriptionStyle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = context.uiLayout;

    final body = <Widget>[
      Text(title, style: theme.textTheme.headlineSmall),
      if (description != null) ...[const VSpacer(6), Text(description!, style: descriptionStyle ?? theme.textTheme.bodySmall)],
    ];

    for (final child in children) {
      body.add(VSpacer(layout.sectionGap));
      body.add(child);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(layout.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
    );
  }
}
