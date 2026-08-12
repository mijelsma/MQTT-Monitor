import 'package:flutter/foundation.dart';

import '../../models/chart_type.dart';
import '../../models/interpolation_mode.dart';
import '../storage/preferences_store.dart';
import 'dashboard_series_policy.dart';

/// Owns persisted defaults used when creating dashboard cards.
class DashboardPreferencesRepository extends ChangeNotifier {
  DashboardPreferencesRepository(this._store);

  static const String schemaVersionKey = 'dashboardPreferences.schemaVersion';
  static const int currentSchemaVersion = 1;
  static const String dotSizeKey = 'settings.defaultDotSize';
  static const String cardColorKey = 'settings.defaultCardColor';
  static const String chartTypeKey = 'settings.defaultChartType';
  static const String interpolationKey = 'settings.defaultInterpolation';
  static const String maximumSamplesKey = 'settings.defaultMaxSamples';
  static const double defaultDotSize = 4;
  static const int defaultCardColor = 0xFF8B5CF6;
  static const ChartType defaultChartType = ChartType.line;
  static const InterpolationMode defaultInterpolation = InterpolationMode.curved;

  final PreferencesStore _store;

  double _dotSize = defaultDotSize;
  int _cardColor = defaultCardColor;
  ChartType _chartType = defaultChartType;
  InterpolationMode _interpolation = defaultInterpolation;
  int _maximumSamples = DashboardSeriesPolicy.defaultSamples;

  double get dotSize => _dotSize;
  int get cardColor => _cardColor;
  ChartType get chartType => _chartType;
  InterpolationMode get interpolation => _interpolation;
  int get maximumSamples => _maximumSamples;

  Future<void> initialize() async {
    await _ensureSchema();
    final dotSize = _store.get(dotSizeKey);
    _dotSize = dotSize is num && dotSize >= 0 && dotSize <= 10 ? dotSize.toDouble() : defaultDotSize;
    _cardColor = _store.get(cardColorKey) is int ? _store.get(cardColorKey)! as int : defaultCardColor;
    _chartType = _decodeEnum(_store.get(chartTypeKey), ChartType.values, defaultChartType);
    _interpolation = _decodeEnum(_store.get(interpolationKey), InterpolationMode.values, defaultInterpolation);
    final maximumSamples = _store.get(maximumSamplesKey);
    _maximumSamples = DashboardSeriesPolicy.normalizeSetting(maximumSamples is int ? maximumSamples : null);
    notifyListeners();
  }

  Future<void> setDotSize(double value) async {
    final next = value.clamp(0, 10).toDouble();
    if (_dotSize == next) return;
    _dotSize = next;
    notifyListeners();
    await _store.setDouble(dotSizeKey, next);
  }

  Future<void> setCardColor(int value) async {
    if (_cardColor == value) return;
    _cardColor = value;
    notifyListeners();
    await _store.setInt(cardColorKey, value);
  }

  Future<void> setChartType(ChartType value) async {
    if (_chartType == value) return;
    _chartType = value;
    notifyListeners();
    await _store.setString(chartTypeKey, value.name);
  }

  Future<void> setInterpolation(InterpolationMode value) async {
    if (_interpolation == value) return;
    _interpolation = value;
    notifyListeners();
    await _store.setString(interpolationKey, value.name);
  }

  Future<void> setMaximumSamples(int value) async {
    final next = DashboardSeriesPolicy.normalizeSetting(value);
    if (_maximumSamples == next) return;
    _maximumSamples = next;
    notifyListeners();
    await _store.setInt(maximumSamplesKey, next);
  }

  Future<void> resetAfterPreferencesClear() async {
    await _store.remove(schemaVersionKey);
    await _store.remove(dotSizeKey);
    await _store.remove(cardColorKey);
    await _store.remove(chartTypeKey);
    await _store.remove(interpolationKey);
    await _store.remove(maximumSamplesKey);
    _dotSize = defaultDotSize;
    _cardColor = defaultCardColor;
    _chartType = defaultChartType;
    _interpolation = defaultInterpolation;
    _maximumSamples = DashboardSeriesPolicy.defaultSamples;
    notifyListeners();
  }

  Future<void> _ensureSchema() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
    } else if (version != currentSchemaVersion) {
      throw StateError('Unsupported dashboard preferences schema version: $version');
    }
  }
}

T _decodeEnum<T extends Enum>(Object? raw, List<T> values, T fallback) {
  if (raw is! String) return fallback;
  return values.firstWhere((value) => value.name == raw, orElse: () => fallback);
}
