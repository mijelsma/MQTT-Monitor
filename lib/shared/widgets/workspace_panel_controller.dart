import 'package:flutter/foundation.dart';

/// Owns collapsed and relative-size state for a collapsible panel workspace.
class WorkspacePanelController extends ChangeNotifier {
  /// Creates panel state with one collapsed value per panel.
  WorkspacePanelController({required List<bool> initialCollapsed, void Function(int index, bool collapsed)? onCollapsedChanged}) : assert(initialCollapsed.isNotEmpty), _collapsed = List<bool>.of(initialCollapsed), _ratios = List<double>.filled(initialCollapsed.length, 1), _onCollapsedChanged = onCollapsedChanged;

  final List<bool> _collapsed;
  final List<double> _ratios;
  final void Function(int index, bool collapsed)? _onCollapsedChanged;

  /// Number of panels managed by this controller.
  int get length => _collapsed.length;

  /// Whether the panel at [index] is collapsed.
  bool isCollapsed(int index) => _collapsed[index];

  /// The panel's relative size among expanded panels.
  double ratioAt(int index) => _ratios[index];

  /// Normalized content-area shares for all panels.
  List<double> get shares {
    var total = 0.0;
    for (var index = 0; index < length; index++) {
      if (!_collapsed[index]) total += _ratios[index];
    }
    if (total <= 0) return List<double>.filled(length, 0);
    return [
      for (var index = 0; index < length; index++)
        if (_collapsed[index]) 0 else _ratios[index] / total,
    ];
  }

  /// Collapses or expands one panel and notifies listeners.
  void toggle(int index) {
    final collapsed = !_collapsed[index];
    if (!collapsed) {
      final otherRatios = <double>[
        for (var other = 0; other < length; other++)
          if (other != index && !_collapsed[other]) _ratios[other],
      ];
      _ratios[index] = otherRatios.isEmpty ? 1 : otherRatios.reduce((left, right) => left + right) / otherRatios.length;
    }
    _collapsed[index] = collapsed;
    _onCollapsedChanged?.call(index, collapsed);
    notifyListeners();
  }

  /// Adjusts two adjacent expanded panels by a relative ratio delta.
  void resizePair(int first, int second, double deltaRatio) {
    assert(!_collapsed[first] && !_collapsed[second]);
    final pairTotal = _ratios[first] + _ratios[second];
    final firstRatio = (_ratios[first] + deltaRatio).clamp(pairTotal * 0.15, pairTotal * 0.85);
    if (firstRatio == _ratios[first]) return;
    _ratios[first] = firstRatio;
    _ratios[second] = pairTotal - firstRatio;
    notifyListeners();
  }
}
