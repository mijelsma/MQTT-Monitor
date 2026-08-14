import 'package:flutter/foundation.dart';

import '../settings_section.dart';

/// Owns the current, non-persisted Settings destination.
class SettingsNavigationController extends ChangeNotifier {
  SettingsSection _section = SettingsSection.brokers;

  SettingsSection get section => _section;

  void select(SettingsSection value) {
    if (_section == value) return;
    _section = value;
    notifyListeners();
  }
}
