import 'package:flutter/widgets.dart';

/// Describes one selectable value in a compact inline segmented row.
class UiInlineSegmentOption<T> {
  const UiInlineSegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final Widget? icon;
}
