import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:mqtt_monitor/core/update/update_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<UpdatePreferencesRepository> create(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final store = await SharedPreferencesStore.load();
    final repository = UpdatePreferencesRepository(store);
    await repository.initialize();
    return repository;
  }

  test('uses stable defaults and writes the version 1 schema', () async {
    final repository = await create({});
    final preferences = await SharedPreferences.getInstance();

    expect(repository.tracksBetaReleases, isFalse);
    expect(
      preferences.getInt(UpdatePreferencesRepository.schemaVersionKey),
      UpdatePreferencesRepository.currentSchemaVersion,
    );
  });

  test('preserves and updates the existing beta preference key', () async {
    final repository = await create({
      UpdatePreferencesRepository.trackBetaReleasesKey: true,
    });
    final preferences = await SharedPreferences.getInstance();

    expect(repository.tracksBetaReleases, isTrue);

    await repository.setTracksBetaReleases(false);

    expect(repository.tracksBetaReleases, isFalse);
    expect(
      preferences.getBool(UpdatePreferencesRepository.trackBetaReleasesKey),
      isFalse,
    );
  });

  test('rejects unsupported schemas and malformed preferences', () async {
    SharedPreferences.setMockInitialValues({
      UpdatePreferencesRepository.schemaVersionKey: 2,
    });
    var store = await SharedPreferencesStore.load();
    var repository = UpdatePreferencesRepository(store);
    await expectLater(repository.initialize(), throwsStateError);

    SharedPreferences.setMockInitialValues({
      UpdatePreferencesRepository.trackBetaReleasesKey: 'yes',
    });
    store = await SharedPreferencesStore.load();
    repository = UpdatePreferencesRepository(store);
    await expectLater(repository.initialize(), throwsFormatException);
  });

  test('reset restores stable tracking without retaining old values', () async {
    final repository = await create({
      UpdatePreferencesRepository.trackBetaReleasesKey: true,
    });
    final preferences = await SharedPreferences.getInstance();

    await repository.resetAfterPreferencesClear();

    expect(repository.tracksBetaReleases, isFalse);
    expect(
      preferences.containsKey(UpdatePreferencesRepository.trackBetaReleasesKey),
      isFalse,
    );
  });
}
