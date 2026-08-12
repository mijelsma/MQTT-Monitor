import 'package:flutter/material.dart';

import '../../models/language.dart';
import '../../models/sidebar_panel_default.dart';
import '../storage/preferences_store.dart';

/// Owns persisted preferences that affect application presentation.
class UiPreferencesRepository extends ChangeNotifier {
  UiPreferencesRepository(this._store);

  static const String schemaVersionKey = 'ui.schemaVersion';
  static const int currentSchemaVersion = 1;

  static const String themeModeKey = 'settings.themeMode';
  static const String accentColorKey = 'settings.accentColor';
  static const String showStatusBarKey = 'settings.showStatusBar';
  static const String showActivityKey = 'settings.showActivity';
  static const String disableSelectionHighlightKey = 'settings.disableSelectionHighlight';
  static const String pulseRatePpsKey = 'settings.pulseRatePps';
  static const String pulseFadeMsKey = 'settings.pulseFadeMs';
  static const String persistLayoutKey = 'settings.persistLayout';
  static const String sidebarAnimationsEnabledKey = 'settings.sidebarAnimationsEnabled';
  static const String sidebarAnimationSpeedKey = 'settings.sidebarAnimationSpeed';
  static const String defaultSidebarDetailKey = 'settings.defaultSidebarDetail';
  static const String defaultSidebarHistoryKey = 'settings.defaultSidebarHistory';
  static const String defaultSidebarPublishKey = 'settings.defaultSidebarPublish';
  static const String defaultSidebarShortcutsKey = 'settings.defaultSidebarShortcuts';
  static const String languageKey = 'settings.language';

  static const ThemeMode defaultThemeMode = ThemeMode.system;
  static const int defaultAccentColor = 0xFF6366F1;
  static const bool defaultShowStatusBar = true;
  static const bool defaultShowActivity = true;
  static const bool defaultDisableSelectionHighlight = false;
  static const int defaultPulseRatePps = 15;
  static const int defaultPulseFadeMs = 500;
  static const bool defaultPersistLayout = true;
  static const bool defaultSidebarAnimationsEnabled = true;
  static const int defaultSidebarAnimationSpeed = 50;
  static const SidebarPanelDefault defaultSidebarDetailValue = SidebarPanelDefault.expanded;
  static const SidebarPanelDefault defaultSidebarHistoryValue = SidebarPanelDefault.collapsed;
  static const SidebarPanelDefault defaultSidebarPublishValue = SidebarPanelDefault.expanded;
  static const SidebarPanelDefault defaultSidebarShortcutsValue = SidebarPanelDefault.collapsed;
  static const AppLanguage defaultLanguage = AppLanguage.en;

  final PreferencesStore _store;

  ThemeMode _themeMode = defaultThemeMode;
  int _accentColor = defaultAccentColor;
  bool _showStatusBar = defaultShowStatusBar;
  bool _showActivity = defaultShowActivity;
  bool _disableSelectionHighlight = defaultDisableSelectionHighlight;
  int _pulseRatePps = defaultPulseRatePps;
  int _pulseFadeMs = defaultPulseFadeMs;
  bool _persistLayout = defaultPersistLayout;
  bool _sidebarAnimationsEnabled = defaultSidebarAnimationsEnabled;
  int _sidebarAnimationSpeed = defaultSidebarAnimationSpeed;
  SidebarPanelDefault _defaultSidebarDetail = defaultSidebarDetailValue;
  SidebarPanelDefault _defaultSidebarHistory = defaultSidebarHistoryValue;
  SidebarPanelDefault _defaultSidebarPublish = defaultSidebarPublishValue;
  SidebarPanelDefault _defaultSidebarShortcuts = defaultSidebarShortcutsValue;
  AppLanguage _language = defaultLanguage;

  ThemeMode get themeMode => _themeMode;
  int get accentColor => _accentColor;
  bool get showStatusBar => _showStatusBar;
  bool get showActivity => _showActivity;
  bool get disableSelectionHighlight => _disableSelectionHighlight;
  int get pulseRatePps => _pulseRatePps;
  int get pulseFadeMs => _pulseFadeMs;
  bool get persistLayout => _persistLayout;
  bool get sidebarAnimationsEnabled => _sidebarAnimationsEnabled;
  int get sidebarAnimationSpeed => _sidebarAnimationSpeed;
  SidebarPanelDefault get defaultSidebarDetail => _defaultSidebarDetail;
  SidebarPanelDefault get defaultSidebarHistory => _defaultSidebarHistory;
  SidebarPanelDefault get defaultSidebarPublish => _defaultSidebarPublish;
  SidebarPanelDefault get defaultSidebarShortcuts => _defaultSidebarShortcuts;
  AppLanguage get language => _language;

  Future<void> initialize() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
    } else if (version != currentSchemaVersion) {
      throw StateError('Unsupported UI preferences schema version: $version');
    }

    _themeMode = _enumValue(themeModeKey, ThemeMode.values, defaultThemeMode);
    _accentColor = _value<int>(accentColorKey, defaultAccentColor);
    _showStatusBar = _value<bool>(showStatusBarKey, defaultShowStatusBar);
    _showActivity = _value<bool>(showActivityKey, defaultShowActivity);
    _disableSelectionHighlight = _value<bool>(disableSelectionHighlightKey, defaultDisableSelectionHighlight);
    _pulseRatePps = _boundedInt(pulseRatePpsKey, defaultPulseRatePps, minimum: 1, maximum: 30);
    _pulseFadeMs = _boundedInt(pulseFadeMsKey, defaultPulseFadeMs, minimum: 50, maximum: 2000);
    _persistLayout = _value<bool>(persistLayoutKey, defaultPersistLayout);
    _sidebarAnimationsEnabled = _value<bool>(sidebarAnimationsEnabledKey, defaultSidebarAnimationsEnabled);
    _sidebarAnimationSpeed = _boundedInt(sidebarAnimationSpeedKey, defaultSidebarAnimationSpeed, minimum: 0, maximum: 100);
    _defaultSidebarDetail = _enumValue(defaultSidebarDetailKey, SidebarPanelDefault.values, defaultSidebarDetailValue);
    _defaultSidebarHistory = _enumValue(defaultSidebarHistoryKey, SidebarPanelDefault.values, defaultSidebarHistoryValue);
    _defaultSidebarPublish = _enumValue(defaultSidebarPublishKey, SidebarPanelDefault.values, defaultSidebarPublishValue);
    _defaultSidebarShortcuts = _enumValue(defaultSidebarShortcutsKey, SidebarPanelDefault.values, defaultSidebarShortcutsValue);
    _language = _enumValue(languageKey, AppLanguage.values, defaultLanguage);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) => _setEnum(themeModeKey, value, (next) => _themeMode = next);

  Future<void> setAccentColor(int value) => _setInt(accentColorKey, value, (next) => _accentColor = next);

  Future<void> setShowStatusBar(bool value) => _setBool(showStatusBarKey, value, (next) => _showStatusBar = next);

  Future<void> setShowActivity(bool value) => _setBool(showActivityKey, value, (next) => _showActivity = next);

  Future<void> setDisableSelectionHighlight(bool value) => _setBool(disableSelectionHighlightKey, value, (next) => _disableSelectionHighlight = next);

  Future<void> setPulseRatePps(int value) => _setInt(pulseRatePpsKey, value.clamp(1, 30), (next) => _pulseRatePps = next);

  Future<void> setPulseFadeMs(int value) => _setInt(pulseFadeMsKey, value.clamp(50, 2000), (next) => _pulseFadeMs = next);

  Future<void> setPersistLayout(bool value) => _setBool(persistLayoutKey, value, (next) => _persistLayout = next);

  Future<void> setSidebarAnimationsEnabled(bool value) => _setBool(sidebarAnimationsEnabledKey, value, (next) => _sidebarAnimationsEnabled = next);

  Future<void> setSidebarAnimationSpeed(int value) => _setInt(sidebarAnimationSpeedKey, value.clamp(0, 100), (next) => _sidebarAnimationSpeed = next);

  Future<void> setDefaultSidebarDetail(SidebarPanelDefault value) => _setEnum(defaultSidebarDetailKey, value, (next) => _defaultSidebarDetail = next);

  Future<void> setDefaultSidebarHistory(SidebarPanelDefault value) => _setEnum(defaultSidebarHistoryKey, value, (next) => _defaultSidebarHistory = next);

  Future<void> setDefaultSidebarPublish(SidebarPanelDefault value) => _setEnum(defaultSidebarPublishKey, value, (next) => _defaultSidebarPublish = next);

  Future<void> setDefaultSidebarShortcuts(SidebarPanelDefault value) => _setEnum(defaultSidebarShortcutsKey, value, (next) => _defaultSidebarShortcuts = next);

  Future<void> setLanguage(AppLanguage value) => _setEnum(languageKey, value, (next) => _language = next);

  Future<void> resetAfterPreferencesClear() async {
    _themeMode = defaultThemeMode;
    _accentColor = defaultAccentColor;
    _showStatusBar = defaultShowStatusBar;
    _showActivity = defaultShowActivity;
    _disableSelectionHighlight = defaultDisableSelectionHighlight;
    _pulseRatePps = defaultPulseRatePps;
    _pulseFadeMs = defaultPulseFadeMs;
    _persistLayout = defaultPersistLayout;
    _sidebarAnimationsEnabled = defaultSidebarAnimationsEnabled;
    _sidebarAnimationSpeed = defaultSidebarAnimationSpeed;
    _defaultSidebarDetail = defaultSidebarDetailValue;
    _defaultSidebarHistory = defaultSidebarHistoryValue;
    _defaultSidebarPublish = defaultSidebarPublishValue;
    _defaultSidebarShortcuts = defaultSidebarShortcutsValue;
    _language = defaultLanguage;
    notifyListeners();
  }

  T _value<T>(String key, T fallback) {
    final raw = _store.get(key);
    return raw is T ? raw : fallback;
  }

  int _boundedInt(String key, int fallback, {required int minimum, required int maximum}) {
    final raw = _store.get(key);
    return raw is int && raw >= minimum && raw <= maximum ? raw : fallback;
  }

  T _enumValue<T extends Enum>(String key, List<T> values, T fallback) {
    final raw = _store.get(key);
    if (raw is! String) return fallback;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  Future<void> _setBool(String key, bool value, ValueChanged<bool> assign) async {
    assign(value);
    notifyListeners();
    await _store.setBool(key, value);
  }

  Future<void> _setInt(String key, int value, ValueChanged<int> assign) async {
    assign(value);
    notifyListeners();
    await _store.setInt(key, value);
  }

  Future<void> _setEnum<T extends Enum>(String key, T value, ValueChanged<T> assign) async {
    assign(value);
    notifyListeners();
    await _store.setString(key, value.name);
  }
}
