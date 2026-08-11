import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/core/update/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final state = AppStateManager.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await state.initialize();
    await state.resetAll();
  });

  test('uses the stable feed by default', () {
    final service = AppUpdateService(state: state);
    addTearDown(service.dispose);

    expect(service.tracksBetaReleases, isFalse);
    expect(service.channel, AppUpdateService.stableChannel);
    expect(service.state, isA<UpdateIdle>());
    expect(service.isConfigured, isFalse);
  });

  test('is configured when a GitHub Releases URL is supplied', () {
    final service = AppUpdateService(
      state: state,
      githubReleasesUrl: Uri.parse(
        'https://api.github.com/repos/mijelsma/MQTT-Monitor/releases',
      ),
    );
    addTearDown(service.dispose);

    expect(service.isConfigured, isTrue);
  });

  test(
    'switching beta tracking persists and replaces the update channel',
    () async {
      final service = AppUpdateService(state: state);
      addTearDown(service.dispose);

      await service.setTracksBetaReleases(true);

      expect(state.read(SettingsKeys.trackBetaReleases), isTrue);
      expect(service.tracksBetaReleases, isTrue);
      expect(service.channel, AppUpdateService.betaChannel);

      await service.setTracksBetaReleases(false);

      expect(state.read(SettingsKeys.trackBetaReleases), isFalse);
      expect(service.channel, AppUpdateService.stableChannel);
    },
  );
}
