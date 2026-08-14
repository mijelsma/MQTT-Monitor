import 'package:flutter/foundation.dart';

import '../../storage/preferences_store.dart';

/// Owns persisted preferences that select the desktop update channel.
class UpdatePreferencesRepository extends ChangeNotifier {
  UpdatePreferencesRepository(this._store);

  static const String schemaVersionKey = 'updates.schemaVersion';
  static const int currentSchemaVersion = 1;
  static const String trackBetaReleasesKey = 'settings.trackBetaReleases';
  static const bool defaultTrackBetaReleases = false;

  final PreferencesStore _store;

  bool _tracksBetaReleases = defaultTrackBetaReleases;

  bool get tracksBetaReleases => _tracksBetaReleases;

  Future<void> initialize() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
    } else if (version != currentSchemaVersion) {
      throw StateError('Unsupported update preferences schema version: $version');
    }

    final storedPreference = _store.get(trackBetaReleasesKey);
    if (storedPreference != null && storedPreference is! bool) {
      throw const FormatException('Beta update tracking must be a boolean.');
    }
    _tracksBetaReleases = storedPreference as bool? ?? defaultTrackBetaReleases;
    notifyListeners();
  }

  Future<void> setTracksBetaReleases(bool value) async {
    if (_tracksBetaReleases == value) return;
    _tracksBetaReleases = value;
    notifyListeners();
    await _store.setBool(trackBetaReleasesKey, value);
  }

  Future<void> resetToDefaults() async {
    await _store.remove(trackBetaReleasesKey);
    _tracksBetaReleases = defaultTrackBetaReleases;
    notifyListeners();
  }
}
