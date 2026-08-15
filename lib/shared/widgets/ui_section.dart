import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../../theme/ui_layout.dart';
import 'spacers.dart';
import 'ui_surface.dart';

class UiSection extends StatelessWidget {
  const UiSection({super.key, required this.label, required this.children, this.sortable = false, this.onReorder});

  final String label;
  final List<Widget> children;
  final bool sortable;
  final ReorderCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final layout = context.uiLayout;

    Widget content;
    if (sortable) {
      content = ReorderableListView.builder(
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        proxyDecorator: (child, _, _) => Material(color: Colors.transparent, child: child),
        onReorder: onReorder ?? (_, _) {},
        itemCount: children.length,
        itemBuilder: (_, i) => children[i],
      );
    } else {
      final items = <Widget>[];
      for (int i = 0; i < children.length; i++) {
        items.add(children[i]);
        if (i < children.length - 1) {
          items.add(Divider(height: 0.5, thickness: 0.5, color: tokens.border, indent: 0, endIndent: 0));
        }
      }
      content = Column(mainAxisSize: MainAxisSize.min, children: items);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: tokens.textSecondary),
          ),
        ),
        VSpacer(layout.isCompact ? 6 : 8),
        UiSurface(child: content),
      ],
    );
  }
}
