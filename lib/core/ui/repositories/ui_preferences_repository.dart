import 'package:flutter/material.dart';

import '../../../core/ui/models/app_language_model.dart';
import '../../../core/ui/models/sidebar_panel_default_model.dart';
import '../../../core/ui/models/ui_density_model.dart';
import '../models/search_defaults.dart';
import '../../storage/preferences_store.dart';

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
  static const String defaultSearchMatchModeKey = 'settings.defaultSearchMatchMode';
  static const String defaultSearchScopeKey = 'settings.defaultSearchScope';
  static const String jsonInlineArrayMaxItemsKey = 'settings.jsonInlineArrayMaxItems';
  static const String languageKey = 'settings.language';
  static const String densityKey = 'settings.density';
  static const String showTopicPayloadPreviewKey = 'settings.showTopicPayloadPreview';
  static const String showTopicBadgesKey = 'settings.showTopicBadges';

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
  static const SidebarPanelDefaultModel defaultSidebarDetailValue = SidebarPanelDefaultModel.expanded;
  static const SidebarPanelDefaultModel defaultSidebarHistoryValue = SidebarPanelDefaultModel.collapsed;
  static const SidebarPanelDefaultModel defaultSidebarPublishValue = SidebarPanelDefaultModel.collapsed;
  static const SidebarPanelDefaultModel defaultSidebarShortcutsValue = SidebarPanelDefaultModel.collapsed;
  static const AppLanguageModel defaultLanguage = AppLanguageModel.en;
  static const SearchMatchMode defaultSearchMatchModeValue = SearchMatchMode.any;
  static const SearchScope defaultSearchScopeValue = SearchScope.all;
  static const int defaultJsonInlineArrayMaxItems = 1;
  static const UiDensityModel defaultDensity = UiDensityModel.comfortable;
  static const bool defaultShowTopicPayloadPreview = true;
  static const bool defaultShowTopicBadges = true;

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
  SidebarPanelDefaultModel _defaultSidebarDetail = defaultSidebarDetailValue;
  SidebarPanelDefaultModel _defaultSidebarHistory = defaultSidebarHistoryValue;
  SidebarPanelDefaultModel _defaultSidebarPublish = defaultSidebarPublishValue;
  SidebarPanelDefaultModel _defaultSidebarShortcuts = defaultSidebarShortcutsValue;
  AppLanguageModel _language = defaultLanguage;
  SearchMatchMode _defaultSearchMatchMode = defaultSearchMatchModeValue;
  SearchScope _defaultSearchScope = defaultSearchScopeValue;
  int _jsonInlineArrayMaxItems = defaultJsonInlineArrayMaxItems;
  UiDensityModel _density = defaultDensity;
  bool _showTopicPayloadPreview = defaultShowTopicPayloadPreview;
  bool _showTopicBadges = defaultShowTopicBadges;

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
  SidebarPanelDefaultModel get defaultSidebarDetail => _defaultSidebarDetail;
  SidebarPanelDefaultModel get defaultSidebarHistory => _defaultSidebarHistory;
  SidebarPanelDefaultModel get defaultSidebarPublish => _defaultSidebarPublish;
  SidebarPanelDefaultModel get defaultSidebarShortcuts => _defaultSidebarShortcuts;
  AppLanguageModel get language => _language;
  SearchMatchMode get defaultSearchMatchMode => _defaultSearchMatchMode;
  SearchScope get defaultSearchScope => _defaultSearchScope;
  int get jsonInlineArrayMaxItems => _jsonInlineArrayMaxItems;
  UiDensityModel get density => _density;
  bool get showTopicPayloadPreview => _showTopicPayloadPreview;
  bool get showTopicBadges => _showTopicBadges;

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
    _defaultSidebarDetail = _enumValue(defaultSidebarDetailKey, SidebarPanelDefaultModel.values, defaultSidebarDetailValue);
    _defaultSidebarHistory = _enumValue(defaultSidebarHistoryKey, SidebarPanelDefaultModel.values, defaultSidebarHistoryValue);
    _defaultSidebarPublish = _enumValue(defaultSidebarPublishKey, SidebarPanelDefaultModel.values, defaultSidebarPublishValue);
    _defaultSidebarShortcuts = _enumValue(defaultSidebarShortcutsKey, SidebarPanelDefaultModel.values, defaultSidebarShortcutsValue);
    _language = _enumValue(languageKey, AppLanguageModel.values, defaultLanguage);
    _defaultSearchMatchMode = _enumValue(defaultSearchMatchModeKey, SearchMatchMode.values, defaultSearchMatchModeValue);
    _defaultSearchScope = _enumValue(defaultSearchScopeKey, SearchScope.values, defaultSearchScopeValue);
    _jsonInlineArrayMaxItems = _boundedInt(jsonInlineArrayMaxItemsKey, defaultJsonInlineArrayMaxItems, minimum: 1, maximum: 10);
    _density = _enumValue(densityKey, UiDensityModel.values, defaultDensity);
    _showTopicPayloadPreview = _value<bool>(showTopicPayloadPreviewKey, defaultShowTopicPayloadPreview);
    _showTopicBadges = _value<bool>(showTopicBadgesKey, defaultShowTopicBadges);
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

  Future<void> setDefaultSidebarDetail(SidebarPanelDefaultModel value) => _setEnum(defaultSidebarDetailKey, value, (next) => _defaultSidebarDetail = next);

  Future<void> setDefaultSidebarHistory(SidebarPanelDefaultModel value) => _setEnum(defaultSidebarHistoryKey, value, (next) => _defaultSidebarHistory = next);

  Future<void> setDefaultSidebarPublish(SidebarPanelDefaultModel value) => _setEnum(defaultSidebarPublishKey, value, (next) => _defaultSidebarPublish = next);

  Future<void> setDefaultSidebarShortcuts(SidebarPanelDefaultModel value) => _setEnum(defaultSidebarShortcutsKey, value, (next) => _defaultSidebarShortcuts = next);

  Future<void> setLanguage(AppLanguageModel value) => _setEnum(languageKey, value, (next) => _language = next);

  Future<void> setDefaultSearchMatchMode(SearchMatchMode value) => _setEnum(defaultSearchMatchModeKey, value, (next) => _defaultSearchMatchMode = next);

  Future<void> setDefaultSearchScope(SearchScope value) => _setEnum(defaultSearchScopeKey, value, (next) => _defaultSearchScope = next);

  Future<void> setJsonInlineArrayMaxItems(int value) => _setInt(jsonInlineArrayMaxItemsKey, value.clamp(1, 10), (next) => _jsonInlineArrayMaxItems = next);

  Future<void> setDensity(UiDensityModel value) => _setEnum(densityKey, value, (next) => _density = next);

  Future<void> setShowTopicPayloadPreview(bool value) => _setBool(showTopicPayloadPreviewKey, value, (next) => _showTopicPayloadPreview = next);

  Future<void> setShowTopicBadges(bool value) => _setBool(showTopicBadgesKey, value, (next) => _showTopicBadges = next);

  Future<void> resetToDefaults() async {
    for (final key in const [
      themeModeKey,
      accentColorKey,
      showStatusBarKey,
      showActivityKey,
      disableSelectionHighlightKey,
      pulseRatePpsKey,
      pulseFadeMsKey,
      persistLayoutKey,
      sidebarAnimationsEnabledKey,
      sidebarAnimationSpeedKey,
      defaultSidebarDetailKey,
      defaultSidebarHistoryKey,
      defaultSidebarPublishKey,
      defaultSidebarShortcutsKey,
      defaultSearchMatchModeKey,
      defaultSearchScopeKey,
      jsonInlineArrayMaxItemsKey,
      languageKey,
      densityKey,
      showTopicPayloadPreviewKey,
      showTopicBadgesKey,
    ]) {
      await _store.remove(key);
    }
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
    _defaultSearchMatchMode = defaultSearchMatchModeValue;
    _defaultSearchScope = defaultSearchScopeValue;
    _jsonInlineArrayMaxItems = defaultJsonInlineArrayMaxItems;
    _density = defaultDensity;
    _showTopicPayloadPreview = defaultShowTopicPayloadPreview;
    _showTopicBadges = defaultShowTopicBadges;
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
