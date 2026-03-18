import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../core/state/keys/dashboard_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/dashboard_layout.dart';
import '../../models/language.dart';
import '../../models/startup_connection.dart';
import 'settings_section.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required AppStateManager state}) : _state = state {
    _state.addListener(_onStateChanged);
  }

  final AppStateManager _state;

  void _onStateChanged() => notifyListeners();

  //  Section navigation

  SettingsSection get activeSection => _state.read(AppKeys.activeSettingsSection);
  void selectSection(SettingsSection s) => _state.write(AppKeys.activeSettingsSection, s);

  //  Broker management

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

  // Dashboard layouts

  List<DashboardLayout> get layouts {
    _state.load(DashboardKeys.layouts);
    return _state.read(DashboardKeys.layouts);
  }

  void deleteLayout(String id) {
    final list = layouts.where((p) => p.id != id).toList();
    _state.write(DashboardKeys.layouts, list);
  }

  void reorderLayouts(int oldIndex, int newIndex) {
    final list = [...layouts];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _state.write(DashboardKeys.layouts, list);
  }

  void addLayout(DashboardLayout layout) {
    _state.write(DashboardKeys.layouts, [...layouts, layout]);
  }

  void updateLayout(DashboardLayout updated) {
    final list = [...layouts];
    final i = list.indexWhere((p) => p.id == updated.id);
    if (i != -1) list[i] = updated;
    _state.write(DashboardKeys.layouts, list);
  }

  // Theme

  ThemeMode get themeMode => _state.read(SettingsKeys.themeMode);
  void setThemeMode(ThemeMode m) => _state.write(SettingsKeys.themeMode, m);

  //  UI settings

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

  StartupConnection get startupConnection => _state.read(SettingsKeys.startupConnection);
  void setStartupConnection(StartupConnection v) => _state.write(SettingsKeys.startupConnection, v);

  //  Language

  AppLanguage get language => _state.read(SettingsKeys.language);
  void setLanguage(AppLanguage lang) => _state.write(SettingsKeys.language, lang);

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }
}
