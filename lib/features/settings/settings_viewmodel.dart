import 'package:flutter/material.dart';

import '../../core/broker/broker_repository.dart';
import '../../core/broker/broker_repository_failure.dart';
import '../../core/dashboard/dashboard_repository.dart';
import '../../core/dashboard/dashboard_preferences_repository.dart';
import '../../core/history/history_policy_rules.dart';
import '../../core/history/history_preferences_repository.dart';
import '../../core/history/message_history_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/mqtt/connection_preferences_repository.dart';
import '../../core/mqtt/session/mqtt_session_controller.dart';
import '../../core/publishing/shortcut_repository.dart';
import '../../core/publishing/qos_preferences_repository.dart';
import '../../core/publishing/variable_repository.dart';
import '../../core/ui/ui_preferences_repository.dart';
import '../../core/ui/workspace_layout_repository.dart';
import '../../core/update/update_preferences_repository.dart';
import '../../models/broker_entry.dart';
import '../../models/chart_type.dart';
import '../../models/dashboard_layout.dart';
import '../../models/interpolation_mode.dart';
import '../../models/language.dart';
import '../../models/mqtt_qos_default.dart';
import '../../models/mqtt_protocol_version.dart';
import '../../models/sidebar_panel_default.dart';
import '../../models/startup_connection.dart';
import 'settings_section.dart';
import 'settings_navigation_controller.dart';
import 'settings_reset_section.dart';
import '../../models/environment_variable.dart';
import '../../models/publish_shortcut.dart';

/// Coordinates settings navigation and delegates data to its owning stores.
class SettingsViewModel extends ChangeNotifier {
  /// Creates the settings controller and observes app and broker state.
  SettingsViewModel({
    required SettingsNavigationController navigation,
    required ConnectionPreferencesRepository connectionPreferences,
    required DashboardPreferencesRepository dashboardPreferences,
    required HistoryPreferencesRepository historyPreferences,
    required WorkspaceLayoutRepository workspaceLayout,
    required AppLogger logger,
    required BrokerRepository brokerRepository,
    required ShortcutRepository shortcutRepository,
    required VariableRepository variableRepository,
    required QosPreferencesRepository qosPreferences,
    required UiPreferencesRepository uiPreferences,
    required UpdatePreferencesRepository updatePreferences,
    MqttSessionController? mqttSession,
    DashboardRepository? dashboardRepository,
    MessageHistoryService? historyService,
  }) : _navigation = navigation,
       _connectionPreferences = connectionPreferences,
       _dashboardPreferences = dashboardPreferences,
       _historyPreferences = historyPreferences,
       _workspaceLayout = workspaceLayout,
       _logger = logger,
       _brokers = brokerRepository,
       _shortcuts = shortcutRepository,
       _variables = variableRepository,
       _qosPreferences = qosPreferences,
       _uiPreferences = uiPreferences,
       _updatePreferences = updatePreferences,
       _mqttSession = mqttSession,
       _dashboard = dashboardRepository,
       _historyService = historyService {
    _navigation.addListener(_onStateChanged);
    _connectionPreferences.addListener(_onStateChanged);
    _dashboardPreferences.addListener(_onStateChanged);
    _historyPreferences.addListener(_onStateChanged);
    _workspaceLayout.addListener(_onStateChanged);
    _brokers.addListener(_onStateChanged);
    _dashboard?.addListener(_onStateChanged);
    _shortcuts.addListener(_onStateChanged);
    _variables.addListener(_onStateChanged);
    _qosPreferences.addListener(_onStateChanged);
    _uiPreferences.addListener(_onStateChanged);
  }

  final SettingsNavigationController _navigation;
  final ConnectionPreferencesRepository _connectionPreferences;
  final DashboardPreferencesRepository _dashboardPreferences;
  final HistoryPreferencesRepository _historyPreferences;
  final WorkspaceLayoutRepository _workspaceLayout;
  final AppLogger _logger;
  final BrokerRepository _brokers;
  final ShortcutRepository _shortcuts;
  final VariableRepository _variables;
  final QosPreferencesRepository _qosPreferences;
  final UiPreferencesRepository _uiPreferences;
  final UpdatePreferencesRepository _updatePreferences;
  final MqttSessionController? _mqttSession;
  final DashboardRepository? _dashboard;
  final MessageHistoryService? _historyService;

  /// Notifies settings consumers after either observed owner changes.
  void _onStateChanged() => notifyListeners();

  SettingsSection get activeSection => _navigation.section;
  void selectSection(SettingsSection s) => _navigation.select(s);

  /// Returns the ordered broker profiles owned by the repository.
  List<BrokerEntry> get brokers => _brokers.brokers;

  /// Returns the recoverable broker persistence failure, if any.
  BrokerRepositoryFailure? get brokerFailure => _brokers.failure;

  /// Retries loading broker profiles after a recoverable failure.
  Future<void> retryBrokerLoad() => _brokers.retry();

  /// Adds [entry] and makes it the active broker.
  Future<void> addBroker(BrokerEntry entry) => _brokers.add(entry);

  /// Persists the updated broker profile.
  Future<void> updateBroker(BrokerEntry updated) => _brokers.update(updated);

  /// Deletes the broker identified by [id].
  Future<void> deleteBroker(String id) => _brokers.delete(id);

  /// Moves a broker using UI reorder indices.
  Future<void> reorderBrokers(int oldIndex, int newIndex) => _brokers.reorder(oldIndex, newIndex);

  // Dashboard layouts

  // Dashboard defaults

  double get defaultDotSize => _dashboardPreferences.dotSize;
  void setDefaultDotSize(double value) => _dashboardPreferences.setDotSize(value);

  Color get defaultCardColor => Color(_dashboardPreferences.cardColor);
  void setDefaultCardColor(Color value) => _dashboardPreferences.setCardColor(value.toARGB32());

  ChartType get defaultChartType => _dashboardPreferences.chartType;
  void setDefaultChartType(ChartType value) => _dashboardPreferences.setChartType(value);

  InterpolationMode get defaultInterpolation => _dashboardPreferences.interpolation;
  void setDefaultInterpolation(InterpolationMode value) => _dashboardPreferences.setInterpolation(value);

  int get defaultMaxSamples => _dashboardPreferences.maximumSamples;
  void setDefaultMaxSamples(int value) => _dashboardPreferences.setMaximumSamples(value);

  // Subscription history

  bool get newSubscriptionHistoryEnabled => _historyPreferences.newSubscriptionEnabled;

  Future<void> setNewSubscriptionHistoryEnabled(bool value) {
    return _historyPreferences.setNewSubscriptionEnabled(value);
  }

  int get maximumHistoryRetention {
    return _historyPreferences.maximumRetention;
  }

  int get newSubscriptionHistoryRetention {
    return _historyPreferences.newSubscriptionRetention;
  }

  Future<void> setNewSubscriptionHistoryRetention(int value) {
    HistoryPolicyRules.validateRetention(value, maximum: maximumHistoryRetention);
    return _historyPreferences.setNewSubscriptionRetention(value);
  }

  /// Reports values that would be destructively clamped by [maximum].
  ({int subscriptions, int defaultPolicy, int liveBuffers}) previewMaximumHistoryRetention(int maximum) {
    HistoryPolicyRules.validateMaximum(maximum);
    final subscriptions = _brokers.brokers.expand((broker) => broker.subscriptions).where((subscription) => subscription.history.retention > maximum).length;
    return (subscriptions: subscriptions, defaultPolicy: newSubscriptionHistoryRetention > maximum ? 1 : 0, liveBuffers: _historyService?.countBuffersAbove(maximum) ?? 0);
  }

  /// Applies a confirmed maximum after clamping broker-owned policies first.
  Future<bool> applyMaximumHistoryRetention(int maximum) async {
    HistoryPolicyRules.validateMaximum(maximum);
    if (!await _brokers.clampSubscriptionHistory(maximum)) return false;
    await _historyPreferences.setMaximumRetention(maximum);
    _historyService?.trimToMaximum(maximum);
    return true;
  }

  /// Restores only the selected application data groups to defaults.
  Future<({bool succeeded, int cleanupFailures})> resetSettingsToDefaults(Set<SettingsResetSection> sections) async {
    if (sections.isEmpty) return (succeeded: true, cleanupFailures: 0);
    final selectedSection = activeSection;
    var cleanupFailures = 0;

    try {
      if (sections.contains(SettingsResetSection.dashboards)) {
        await _dashboard?.resetToDefaults();
        await _dashboardPreferences.resetToDefaults();
      }
      if (sections.contains(SettingsResetSection.variables)) {
        await _variables.resetToDefaults();
      }
      if (sections.contains(SettingsResetSection.shortcuts)) {
        await _shortcuts.resetToDefaults();
      }
      if (sections.contains(SettingsResetSection.history)) {
        await _historyPreferences.resetToDefaults();
        _historyService?.clear();
      }
      if (sections.contains(SettingsResetSection.connection)) {
        await _connectionPreferences.resetToDefaults();
        await _mqttSession?.resetConnectionIntentToDefault();
      }
      if (sections.contains(SettingsResetSection.publishing)) {
        await _qosPreferences.resetToDefaults();
      }
      if (sections.contains(SettingsResetSection.userInterface)) {
        await _uiPreferences.resetToDefaults();
        await _workspaceLayout.resetToDefaults();
      }
      if (sections.contains(SettingsResetSection.updates)) {
        await _updatePreferences.resetToDefaults();
      }
      if (sections.contains(SettingsResetSection.brokers)) {
        final brokerReset = await _brokers.resetToDefaults();
        if (!brokerReset.succeeded) return brokerReset;
        cleanupFailures += brokerReset.cleanupFailures;
      }

      _workspaceLayout.setPersistenceEnabled(_uiPreferences.persistLayout);
      _navigation.select(selectedSection);
      return (succeeded: true, cleanupFailures: cleanupFailures);
    } on Object catch (error) {
      _logger.log(AppLogLevel.error, 'settings.reset', 'Resetting application settings failed.', error: error);
      return (succeeded: false, cleanupFailures: cleanupFailures);
    }
  }

  int get messageRateSampleSize => _historyPreferences.rateSampleSize;
  void setMessageRateSampleSize(int value) => _historyPreferences.setRateSampleSize(value);

  // ── Default QoS levels ───────────────────────────────────────────────

  MqttQosDefault get defaultPublishQos => _qosPreferences.defaultPublish;
  void setDefaultPublishQos(MqttQosDefault value) => _qosPreferences.setDefaultPublish(value);

  MqttQosDefault get defaultShortcutQos => _qosPreferences.defaultShortcut;
  void setDefaultShortcutQos(MqttQosDefault value) => _qosPreferences.setDefaultShortcut(value);

  MqttQosDefault get defaultSubscribeQos => _qosPreferences.defaultSubscribe;
  void setDefaultSubscribeQos(MqttQosDefault value) => _qosPreferences.setDefaultSubscribe(value);

  /// The shared most-recently-picked QoS. The "last used" option on the
  /// default-QoS pickers resolves to this value.
  int get lastUsedQos => _qosPreferences.lastUsed;

  /// Records a new QoS value the user just picked, so the next
  /// `defaultXxxQos.lastUsed` resolution picks it up. Clamped to 0–2.
  void recordQos(int value) => _qosPreferences.record(value);

  /// Resolves a [MqttQosDefault] to an actual MQTT QoS value (0, 1, or 2),
  /// honoring the "last used" strategy when applicable.
  int resolveDefaultQos(MqttQosDefault strategy) => _qosPreferences.resolve(strategy);

  List<DashboardLayout> get layouts => _dashboard?.layouts ?? const [];

  void deleteLayout(String id) {
    final list = layouts.where((p) => p.id != id).toList();
    _dashboard?.setLayouts(list);
  }

  void reorderLayouts(int oldIndex, int newIndex) {
    final list = [...layouts];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _dashboard?.setLayouts(list);
  }

  void addLayout(DashboardLayout layout) {
    _dashboard?.setLayouts([...layouts, layout]);
  }

  void updateLayout(DashboardLayout updated) {
    final list = [...layouts];
    final i = list.indexWhere((p) => p.id == updated.id);
    if (i != -1) list[i] = updated;
    _dashboard?.setLayouts(list);
  }

  // ── Environment variables ─────────────────────────────────────────────

  List<EnvironmentVariable> get environmentVariables => _variables.variables;

  Future<void> addEnvironmentVariable(EnvironmentVariable variable) => _variables.add(variable);

  Future<void> updateEnvironmentVariable(String oldName, EnvironmentVariable updated) => _variables.update(oldName, updated);

  Future<void> deleteEnvironmentVariable(String name) => _variables.delete(name);

  Future<void> reorderEnvironmentVariables(int oldIndex, int newIndex) => _variables.reorder(oldIndex, newIndex);

  // ── Shortcuts ─────────────────────────────────────────────────────────

  List<PublishShortcut> get shortcuts => _shortcuts.shortcuts;

  Future<void> addShortcut(PublishShortcut shortcut) => _shortcuts.add(shortcut);

  Future<void> updateShortcut(PublishShortcut updated) => _shortcuts.update(updated);

  Future<void> deleteShortcut(String id) => _shortcuts.delete(id);

  Future<void> reorderShortcuts(int oldIndex, int newIndex) => _shortcuts.reorder(oldIndex, newIndex);

  // Theme

  ThemeMode get themeMode => _uiPreferences.themeMode;
  void setThemeMode(ThemeMode m) => _uiPreferences.setThemeMode(m);

  Color get accentColor => Color(_uiPreferences.accentColor);
  void setAccentColor(Color value) => _uiPreferences.setAccentColor(value.toARGB32());

  //  UI settings

  bool get showStatusBar => _uiPreferences.showStatusBar;
  void setShowStatusBar(bool v) => _uiPreferences.setShowStatusBar(v);

  bool get showActivity => _uiPreferences.showActivity;
  void setShowActivity(bool v) => _uiPreferences.setShowActivity(v);

  bool get disableSelectionHighlight => _uiPreferences.disableSelectionHighlight;
  void setDisableSelectionHighlight(bool v) => _uiPreferences.setDisableSelectionHighlight(v);

  int get pulseRatePps => _uiPreferences.pulseRatePps;
  void setPulseRatePps(int v) => _uiPreferences.setPulseRatePps(v);

  int get pulseFadeMs => _uiPreferences.pulseFadeMs;
  void setPulseFadeMs(int v) => _uiPreferences.setPulseFadeMs(v);

  bool get persistLayout => _uiPreferences.persistLayout;
  void setPersistLayout(bool v) {
    _workspaceLayout.setPersistenceEnabled(v);
    _uiPreferences.setPersistLayout(v);
  }

  bool get sidebarAnimationsEnabled => _uiPreferences.sidebarAnimationsEnabled;
  void setSidebarAnimationsEnabled(bool v) => _uiPreferences.setSidebarAnimationsEnabled(v);

  int get sidebarAnimationSpeed => _uiPreferences.sidebarAnimationSpeed;
  void setSidebarAnimationSpeed(int v) => _uiPreferences.setSidebarAnimationSpeed(v);

  // ── Sidebar panel default states ──────────────────────────────────────

  SidebarPanelDefault get defaultSidebarDetail => _uiPreferences.defaultSidebarDetail;
  void setDefaultSidebarDetail(SidebarPanelDefault v) => _uiPreferences.setDefaultSidebarDetail(v);

  SidebarPanelDefault get defaultSidebarHistory => _uiPreferences.defaultSidebarHistory;
  void setDefaultSidebarHistory(SidebarPanelDefault v) => _uiPreferences.setDefaultSidebarHistory(v);

  SidebarPanelDefault get defaultSidebarPublish => _uiPreferences.defaultSidebarPublish;
  void setDefaultSidebarPublish(SidebarPanelDefault v) => _uiPreferences.setDefaultSidebarPublish(v);

  SidebarPanelDefault get defaultSidebarShortcuts => _uiPreferences.defaultSidebarShortcuts;
  void setDefaultSidebarShortcuts(SidebarPanelDefault v) => _uiPreferences.setDefaultSidebarShortcuts(v);

  int get rateIntervalMs => _connectionPreferences.rateIntervalMs;
  void setRateIntervalMs(int v) => _connectionPreferences.setRateIntervalMs(v);

  StartupConnection get startupConnection => _connectionPreferences.startupConnection;
  void setStartupConnection(StartupConnection v) => _connectionPreferences.setStartupConnection(v);

  MqttProtocolVersion get defaultBrokerProtocol => _connectionPreferences.brokerProtocol;
  void setDefaultBrokerProtocol(MqttProtocolVersion value) => _connectionPreferences.setBrokerProtocol(value);

  //  Language

  AppLanguage get language => _uiPreferences.language;
  void setLanguage(AppLanguage lang) => _uiPreferences.setLanguage(lang);

  /// Releases navigation and repository listeners.
  @override
  void dispose() {
    _navigation.removeListener(_onStateChanged);
    _connectionPreferences.removeListener(_onStateChanged);
    _dashboardPreferences.removeListener(_onStateChanged);
    _historyPreferences.removeListener(_onStateChanged);
    _workspaceLayout.removeListener(_onStateChanged);
    _brokers.removeListener(_onStateChanged);
    _dashboard?.removeListener(_onStateChanged);
    _shortcuts.removeListener(_onStateChanged);
    _variables.removeListener(_onStateChanged);
    _qosPreferences.removeListener(_onStateChanged);
    _uiPreferences.removeListener(_onStateChanged);
    super.dispose();
  }
}
