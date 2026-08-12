import 'package:flutter/material.dart';

/// Describes one selectable value in a full-width segmented row.
class UiSegmentOption<T> {
  const UiSegmentOption({required this.value, required this.label, this.icon, this.description});

  final T value;
  final String label;
  final IconData? icon;
  final String? description;
}
