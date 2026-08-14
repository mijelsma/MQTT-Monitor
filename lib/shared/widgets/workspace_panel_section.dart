import 'package:flutter/widgets.dart';

/// Describes one header and body in a collapsible panel workspace.
class WorkspacePanelSection {
  /// Creates a panel section.
  const WorkspacePanelSection({
    required this.title,
    required this.icon,
    required this.body,
    required this.toggleKey,
    required this.contentKey,
  });

  /// User-facing panel title.
  final String title;

  /// Icon shown beside [title].
  final IconData icon;

  /// Panel content, kept mounted while collapsed.
  final Widget body;

  /// Stable key for the interactive header.
  final Key toggleKey;

  /// Stable key for the visible content clip.
  final Key contentKey;
}
