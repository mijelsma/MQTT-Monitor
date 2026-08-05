import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../core/state/keys/dashboard_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/chart_type.dart';
import '../../models/dashboard_layout.dart';
import '../../models/interpolation_mode.dart';
import '../../models/language.dart';
import '../../models/mqtt_qos_default.dart';
import '../../models/startup_connection.dart';
import 'settings_section.dart';
import '../../models/environment_variable.dart';
import '../../models/publish_shortcut.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required AppStateManager state}) : _state = state {
    _state.load(DashboardKeys.layouts);
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

  // Dashboard defaults

  double get defaultDotSize => _state.read(SettingsKeys.defaultDotSize);
  void setDefaultDotSize(double value) => _state.write(SettingsKeys.defaultDotSize, value);

  Color get defaultCardColor => Color(_state.read(SettingsKeys.defaultCardColor));
  void setDefaultCardColor(Color value) => _state.write(SettingsKeys.defaultCardColor, value.toARGB32());

  ChartType get defaultChartType => _state.read(SettingsKeys.defaultChartType);
  void setDefaultChartType(ChartType value) => _state.write(SettingsKeys.defaultChartType, value);

  InterpolationMode get defaultInterpolation => _state.read(SettingsKeys.defaultInterpolation);
  void setDefaultInterpolation(InterpolationMode value) => _state.write(SettingsKeys.defaultInterpolation, value);

  int get defaultMaxSamples => _state.read(SettingsKeys.defaultMaxSamples);
  void setDefaultMaxSamples(int value) => _state.write(SettingsKeys.defaultMaxSamples, value);

  // History & monitoring

  int get defaultHistorySize => _state.read(SettingsKeys.defaultHistorySize);
  void setDefaultHistorySize(int value) => _state.write(SettingsKeys.defaultHistorySize, value);

  int get increasedHistorySize => _state.read(SettingsKeys.increasedHistorySize);
  void setIncreasedHistorySize(int value) => _state.write(SettingsKeys.increasedHistorySize, value);

  List<String> get increasedMonitoringTopics => _state.read(SettingsKeys.increasedMonitoringTopics);
  void clearIncreasedMonitoringTopics() => _state.write(SettingsKeys.increasedMonitoringTopics, <String>[]);
  void removeIncreasedMonitoringTopic(String topic) {
    final list = increasedMonitoringTopics.where((t) => t != topic).toList();
    _state.write(SettingsKeys.increasedMonitoringTopics, list);
  }

  int get messageRateSampleSize => _state.read(SettingsKeys.messageRateSampleSize);
  void setMessageRateSampleSize(int value) => _state.write(SettingsKeys.messageRateSampleSize, value);

  // ── Default QoS levels ───────────────────────────────────────────────

  MqttQosDefault get defaultPublishQos => _state.read(SettingsKeys.defaultPublishQos);
  void setDefaultPublishQos(MqttQosDefault value) => _state.write(SettingsKeys.defaultPublishQos, value);

  MqttQosDefault get defaultShortcutQos => _state.read(SettingsKeys.defaultShortcutQos);
  void setDefaultShortcutQos(MqttQosDefault value) => _state.write(SettingsKeys.defaultShortcutQos, value);

  MqttQosDefault get defaultSubscribeQos => _state.read(SettingsKeys.defaultSubscribeQos);
  void setDefaultSubscribeQos(MqttQosDefault value) => _state.write(SettingsKeys.defaultSubscribeQos, value);

  /// The shared most-recently-picked QoS. The "last used" option on the
  /// default-QoS pickers resolves to this value.
  int get lastUsedQos => _state.read(SettingsKeys.lastUsedQos);

  /// Records a new QoS value the user just picked, so the next
  /// `defaultXxxQos.lastUsed` resolution picks it up. Clamped to 0–2.
  void recordQos(int value) => _state.write(SettingsKeys.lastUsedQos, value.clamp(0, 2));

  /// Resolves a [MqttQosDefault] to an actual MQTT QoS value (0, 1, or 2),
  /// honoring the "last used" strategy when applicable.
  int resolveDefaultQos(MqttQosDefault strategy) => strategy.resolve(lastUsedQos);

  List<DashboardLayout> get layouts => _state.read(DashboardKeys.layouts);

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

  // ── Environment variables ─────────────────────────────────────────────

  List<EnvironmentVariable> get environmentVariables => _state.read(SettingsKeys.environmentVariables);

  void addEnvironmentVariable(EnvironmentVariable variable) {
    _state.write(SettingsKeys.environmentVariables, [...environmentVariables, variable]);
  }

  void updateEnvironmentVariable(String oldName, EnvironmentVariable updated) {
    final list = [...environmentVariables];
    final i = list.indexWhere((v) => v.name == oldName);
    if (i != -1) {
      list[i] = updated;
      // If name changed, migrate the stored value.
      if (oldName != updated.name) {
        final values = Map<String, String>.from(_state.read(SettingsKeys.environmentVariableValues));
        if (values.containsKey(oldName)) {
          values[updated.name] = values.remove(oldName)!;
          _state.write(SettingsKeys.environmentVariableValues, values);
        }
      }
    }
    _state.write(SettingsKeys.environmentVariables, list);
  }

  void deleteEnvironmentVariable(String name) {
    _state.write(SettingsKeys.environmentVariables, environmentVariables.where((v) => v.name != name).toList());
    final values = Map<String, String>.from(_state.read(SettingsKeys.environmentVariableValues));
    values.remove(name);
    _state.write(SettingsKeys.environmentVariableValues, values);
  }

  void reorderEnvironmentVariables(int oldIndex, int newIndex) {
    final list = [...environmentVariables];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _state.write(SettingsKeys.environmentVariables, list);
  }

  // ── Shortcuts ─────────────────────────────────────────────────────────

  List<PublishShortcut> get shortcuts => _state.read(SettingsKeys.shortcuts);

  void addShortcut(PublishShortcut shortcut) {
    _state.write(SettingsKeys.shortcuts, [...shortcuts, shortcut]);
  }

  void updateShortcut(int index, PublishShortcut updated) {
    final list = [...shortcuts];
    if (index >= 0 && index < list.length) list[index] = updated;
    _state.write(SettingsKeys.shortcuts, list);
  }

  void deleteShortcut(int index) {
    final list = [...shortcuts];
    if (index >= 0 && index < list.length) list.removeAt(index);
    _state.write(SettingsKeys.shortcuts, list);
  }

  void reorderShortcuts(int oldIndex, int newIndex) {
    final list = [...shortcuts];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _state.write(SettingsKeys.shortcuts, list);
  }

  // Theme

  ThemeMode get themeMode => _state.read(SettingsKeys.themeMode);
  void setThemeMode(ThemeMode m) => _state.write(SettingsKeys.themeMode, m);

  Color get accentColor => Color(_state.read(SettingsKeys.accentColor));
  void setAccentColor(Color value) => _state.write(SettingsKeys.accentColor, value.toARGB32());

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

  bool get sidebarAnimationsEnabled => _state.read(SettingsKeys.sidebarAnimationsEnabled);
  void setSidebarAnimationsEnabled(bool v) => _state.write(SettingsKeys.sidebarAnimationsEnabled, v);

  int get sidebarAnimationSpeed => _state.read(SettingsKeys.sidebarAnimationSpeed).clamp(0, 100).toInt();
  void setSidebarAnimationSpeed(int v) => _state.write(SettingsKeys.sidebarAnimationSpeed, v.clamp(0, 100).toInt());

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
