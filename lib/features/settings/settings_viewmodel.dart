import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/language.dart';
import 'settings_section.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required AppStateManager state}) : _state = state {
    _state.addListener(_onStateChanged);
  }

  final AppStateManager _state;

  void _onStateChanged() => notifyListeners();

  // ── Section navigation ───────────────────────────────────────────────

  SettingsSection get activeSection => _state.read(AppKeys.activeSettingsSection);
  void selectSection(SettingsSection s) => _state.write(AppKeys.activeSettingsSection, s);

  // ── Broker management ────────────────────────────────────────────────

  List<BrokerEntry> get brokers => _state.read(SettingsKeys.brokers);

  void addBroker(BrokerEntry entry) {
    _state.write(SettingsKeys.brokers, [...brokers, entry]);
    _state.write(AppKeys.activeBrokerId, entry.id);
  }

  void updateBroker(BrokerEntry updated) {
    final list = [...brokers];
    final i = list.indexWhere((b) => b.id == updated.id);
    if (i != -1) list[i] = updated;
    _state.write(SettingsKeys.brokers, list);
  }

  void deleteBroker(String id) {
    _state.write(SettingsKeys.brokers, brokers.where((b) => b.id != id).toList());
  }

  void reorderBrokers(int oldIndex, int newIndex) {
    final list = [...brokers];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _state.write(SettingsKeys.brokers, list);
  }

  // ── Theme ────────────────────────────────────────────────────────────

  ThemeMode get themeMode => _state.read(SettingsKeys.themeMode);
  void setThemeMode(ThemeMode m) => _state.write(SettingsKeys.themeMode, m);

  // ── UI settings ──────────────────────────────────────────────────────

  bool get showStatusBar => _state.read(SettingsKeys.showStatusBar);
  void setShowStatusBar(bool v) => _state.write(SettingsKeys.showStatusBar, v);

  bool get showActivity => _state.read(SettingsKeys.showActivity);
  void setShowActivity(bool v) => _state.write(SettingsKeys.showActivity, v);

  int get pulseRatePps => _state.read(SettingsKeys.pulseRatePps);
  void setPulseRatePps(int v) => _state.write(SettingsKeys.pulseRatePps, v);

  int get pulseFadeMs => _state.read(SettingsKeys.pulseFadeMs);
  void setPulseFadeMs(int v) => _state.write(SettingsKeys.pulseFadeMs, v);

  bool get persistLayout => _state.read(SettingsKeys.persistLayout);
  void setPersistLayout(bool v) => _state.write(SettingsKeys.persistLayout, v);

  int get rateIntervalMs => _state.read(SettingsKeys.rateIntervalMs);
  void setRateIntervalMs(int v) => _state.write(SettingsKeys.rateIntervalMs, v);

  // ── Language ─────────────────────────────────────────────────────────

  AppLanguage get language => _state.read(SettingsKeys.language);
  void setLanguage(AppLanguage lang) => _state.write(SettingsKeys.language, lang);

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }
}
