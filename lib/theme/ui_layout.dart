import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Shared layout metrics for the application's two supported display densities.
@immutable
class UiLayout extends ThemeExtension<UiLayout> {
  const UiLayout({required this.isCompact, required this.pagePadding, required this.sectionGap, required this.rowVerticalPadding, required this.controlVerticalPadding, required this.toolbarButtonPadding});

  final bool isCompact;
  final double pagePadding;
  final double sectionGap;
  final double rowVerticalPadding;
  final double controlVerticalPadding;
  final EdgeInsets toolbarButtonPadding;

  static const comfortable = UiLayout(isCompact: false, pagePadding: 30, sectionGap: 20, rowVerticalPadding: 11, controlVerticalPadding: 10, toolbarButtonPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8));

  static const compact = UiLayout(isCompact: true, pagePadding: 22, sectionGap: 16, rowVerticalPadding: 7, controlVerticalPadding: 8, toolbarButtonPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7));

  @override
  UiLayout copyWith({bool? isCompact, double? pagePadding, double? sectionGap, double? rowVerticalPadding, double? controlVerticalPadding, EdgeInsets? toolbarButtonPadding}) => UiLayout(
    isCompact: isCompact ?? this.isCompact,
    pagePadding: pagePadding ?? this.pagePadding,
    sectionGap: sectionGap ?? this.sectionGap,
    rowVerticalPadding: rowVerticalPadding ?? this.rowVerticalPadding,
    controlVerticalPadding: controlVerticalPadding ?? this.controlVerticalPadding,
    toolbarButtonPadding: toolbarButtonPadding ?? this.toolbarButtonPadding,
  );

  @override
  UiLayout lerp(UiLayout? other, double t) {
    if (other == null) return this;
    return UiLayout(
      isCompact: t < 0.5 ? isCompact : other.isCompact,
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t)!,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t)!,
      rowVerticalPadding: lerpDouble(rowVerticalPadding, other.rowVerticalPadding, t)!,
      controlVerticalPadding: lerpDouble(controlVerticalPadding, other.controlVerticalPadding, t)!,
      toolbarButtonPadding: EdgeInsets.lerp(toolbarButtonPadding, other.toolbarButtonPadding, t)!,
    );
  }
}

extension UiLayoutContext on BuildContext {
  /// Falls back to comfortable density for isolated widgets and host apps that
  /// have not opted into the application theme extension.
  UiLayout get uiLayout => Theme.of(this).extension<UiLayout>() ?? UiLayout.comfortable;
}
