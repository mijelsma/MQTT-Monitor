import 'package:flutter/foundation.dart';

import '../storage/preferences_store.dart';
import 'history_policy_rules.dart';

/// Owns persisted defaults and bounds for subscription message history.
class HistoryPreferencesRepository extends ChangeNotifier {
  HistoryPreferencesRepository(this._store);

  static const String schemaVersionKey = 'history.schemaVersion';
  static const int currentSchemaVersion = 1;
  static const String newSubscriptionEnabledKey = 'settings.newSubscriptionHistoryEnabled';
  static const String newSubscriptionRetentionKey = 'settings.newSubscriptionHistoryRetention';
  static const String maximumRetentionKey = 'settings.maximumHistoryRetention';
  static const String rateSampleSizeKey = 'settings.messageRateSampleSize';
  static const int defaultRateSampleSize = 10;

  final PreferencesStore _store;

  bool _newSubscriptionEnabled = HistoryPolicyRules.defaultEnabled;
  int _newSubscriptionRetention = HistoryPolicyRules.defaultRetention;
  int _maximumRetention = HistoryPolicyRules.defaultMaximumRetention;
  int _rateSampleSize = defaultRateSampleSize;

  bool get newSubscriptionEnabled => _newSubscriptionEnabled;
  int get newSubscriptionRetention => _newSubscriptionRetention;
  int get maximumRetention => _maximumRetention;
  int get rateSampleSize => _rateSampleSize;

  Future<void> initialize() async {
    await _ensureSchema();
    final maximum = _store.get(maximumRetentionKey);
    _maximumRetention = maximum is int && HistoryPolicyRules.isValidMaximum(maximum) ? maximum : HistoryPolicyRules.defaultMaximumRetention;

    final enabled = _store.get(newSubscriptionEnabledKey);
    _newSubscriptionEnabled = enabled is bool ? enabled : HistoryPolicyRules.defaultEnabled;

    final retention = _store.get(newSubscriptionRetentionKey);
    _newSubscriptionRetention = retention is int && HistoryPolicyRules.isValidRetention(retention, maximum: _maximumRetention) ? retention : HistoryPolicyRules.defaultRetention.clamp(HistoryPolicyRules.minimumRetention, _maximumRetention);

    final sampleSize = _store.get(rateSampleSizeKey);
    _rateSampleSize = sampleSize is int && sampleSize >= 2 && sampleSize <= 50 ? sampleSize : defaultRateSampleSize;
    notifyListeners();
  }

  Future<void> setNewSubscriptionEnabled(bool value) async {
    if (_newSubscriptionEnabled == value) return;
    _newSubscriptionEnabled = value;
    notifyListeners();
    await _store.setBool(newSubscriptionEnabledKey, value);
  }

  Future<void> setNewSubscriptionRetention(int value) async {
    HistoryPolicyRules.validateRetention(value, maximum: _maximumRetention);
    if (_newSubscriptionRetention == value) return;
    _newSubscriptionRetention = value;
    notifyListeners();
    await _store.setInt(newSubscriptionRetentionKey, value);
  }

  Future<void> setMaximumRetention(int value) async {
    HistoryPolicyRules.validateMaximum(value);
    if (_maximumRetention == value) return;
    _maximumRetention = value;
    if (_newSubscriptionRetention > value) {
      _newSubscriptionRetention = value;
      await _store.setInt(newSubscriptionRetentionKey, value);
    }
    notifyListeners();
    await _store.setInt(maximumRetentionKey, value);
  }

  Future<void> setRateSampleSize(int value) async {
    final next = value.clamp(2, 50);
    if (_rateSampleSize == next) return;
    _rateSampleSize = next;
    notifyListeners();
    await _store.setInt(rateSampleSizeKey, next);
  }

  Future<void> resetToDefaults() async {
    await _store.remove(newSubscriptionEnabledKey);
    await _store.remove(newSubscriptionRetentionKey);
    await _store.remove(maximumRetentionKey);
    await _store.remove(rateSampleSizeKey);
    _newSubscriptionEnabled = HistoryPolicyRules.defaultEnabled;
    _newSubscriptionRetention = HistoryPolicyRules.defaultRetention;
    _maximumRetention = HistoryPolicyRules.defaultMaximumRetention;
    _rateSampleSize = defaultRateSampleSize;
    notifyListeners();
  }

  Future<void> _ensureSchema() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
    } else if (version != currentSchemaVersion) {
      throw StateError('Unsupported history schema version: $version');
    }
  }
}
