import 'dart:async';

import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:mqtt_monitor/core/update/controllers/app_update_controller.dart';
import 'package:mqtt_monitor/core/update/services/app_update_service.dart';
import 'package:mqtt_monitor/core/update/github_release_source.dart';
import 'package:mqtt_monitor/core/update/repositories/update_preferences_repository.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late UpdatePreferencesRepository preferences;
  late _FakeControllerFactory controllers;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferencesStore.load();
    preferences = UpdatePreferencesRepository(store);
    await preferences.initialize();
    controllers = _FakeControllerFactory();
  });

  test('uses the stable feed and stays idle when unconfigured', () {
    final service = AppUpdateService(preferences: preferences, controllerFactory: controllers);
    addTearDown(service.dispose);

    expect(service.tracksBetaReleases, isFalse);
    expect(service.channel, AppUpdateService.stableChannel);
    expect(service.state, isA<UpdateIdle>());
    expect(service.isConfigured, isFalse);
    expect(controllers.created.single.channel, AppUpdateService.stableChannel);
  });

  test('is configured when a release source is supplied', () {
    final source = _FakeReleaseSource((_) async => null);
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);
    addTearDown(service.dispose);

    expect(service.isConfigured, isTrue);
  });

  test('is configured when a GitHub Releases URL is supplied', () {
    final service = AppUpdateService(preferences: preferences, githubReleasesUrl: Uri.parse('https://api.github.com/repos/mijelsma/MQTT-Monitor/releases'), controllerFactory: controllers);
    addTearDown(service.dispose);

    expect(service.isConfigured, isTrue);
  });

  test('switching beta tracking persists and replaces the channel', () async {
    final service = AppUpdateService(preferences: preferences, controllerFactory: controllers);
    addTearDown(service.dispose);

    await service.setTracksBetaReleases(true);

    expect(preferences.tracksBetaReleases, isTrue);
    expect(service.tracksBetaReleases, isTrue);
    expect(service.channel, AppUpdateService.betaChannel);
    expect(controllers.created, hasLength(2));
    expect(controllers.created.first.disposed, isTrue);
    expect(controllers.created.last.channel, AppUpdateService.betaChannel);

    await service.setTracksBetaReleases(false);

    expect(preferences.tracksBetaReleases, isFalse);
    expect(service.channel, AppUpdateService.stableChannel);
    expect(controllers.created, hasLength(3));
    expect(controllers.created.last.channel, AppUpdateService.stableChannel);
  });

  test('changing a configured channel immediately restarts discovery', () async {
    final source = _FakeReleaseSource((_) async => null);
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);
    addTearDown(service.dispose);

    await service.setTracksBetaReleases(true);

    expect(source.includePrereleases, [true]);
  });

  test('reports an up-to-date release discovery result', () async {
    final source = _FakeReleaseSource((_) async => null);
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);
    addTearDown(service.dispose);

    final result = await service.checkForUpdates();

    expect(result, isA<ManualUpdateCheckUpToDate>());
    expect(service.state, isA<UpdateIdle>());
    expect(service.selectedRelease, isNull);
    expect(source.includePrereleases, [false]);
  });

  test('surfaces release discovery failures as updater state', () async {
    final failure = StateError('release discovery failed');
    final source = _FakeReleaseSource((_) async => throw failure);
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);
    addTearDown(service.dispose);

    final result = await service.checkForUpdates();

    expect(result, isA<ManualUpdateCheckFailed>());
    expect(service.state, isA<UpdateFailed>());
    expect((service.state as UpdateFailed).error, same(failure));
  });

  test('uses the selected archive and delegates check download and restart', () async {
    final selection = _selection('v1.2.3-beta.1', channel: AppUpdateService.betaChannel);
    final source = _FakeReleaseSource((_) async => selection);
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);
    addTearDown(service.dispose);

    final result = await service.checkForUpdates();
    await service.downloadUpdate();
    await service.restartApp();

    final selectedController = controllers.created.last;
    expect(result, isA<ManualUpdateCheckUpToDate>());
    expect(service.selectedRelease, same(selection.release));
    expect(selectedController.appArchiveUrl, selection.archiveUrl);
    expect(selectedController.channel, AppUpdateService.betaChannel);
    expect(selectedController.checkCalls, 1);
    expect(selectedController.downloadCalls, 1);
    expect(selectedController.restartCalls, 1);
  });

  test('a newer discovery epoch prevents stale results from winning', () async {
    final first = Completer<GitHubReleaseSelection?>();
    final second = Completer<GitHubReleaseSelection?>();
    var calls = 0;
    final source = _FakeReleaseSource((_) {
      calls += 1;
      return calls == 1 ? first.future : second.future;
    });
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);
    addTearDown(service.dispose);

    final staleCheck = service.checkForUpdates();
    final currentCheck = service.checkForUpdates();
    first.complete(_selection('v9.0.0', channel: AppUpdateService.stableChannel));
    second.complete(null);

    expect(await staleCheck, isNull);
    expect(await currentCheck, isA<ManualUpdateCheckUpToDate>());
    expect(service.selectedRelease, isNull);
    expect(controllers.created, hasLength(2));
  });

  test('forwards controller state and disposes owned collaborators', () async {
    final source = _FakeReleaseSource((_) async => null);
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);
    var notifications = 0;
    service.addListener(() => notifications += 1);

    controllers.created.single.emit(const UpdateChecking());

    expect(service.state, isA<UpdateChecking>());
    expect(notifications, 1);

    service.dispose();

    expect(source.closed, isTrue);
    expect(controllers.created.single.disposed, isTrue);
  });
}

GitHubReleaseSelection _selection(String tag, {required String channel}) {
  final archiveUrl = Uri.parse('https://example.test/$tag/app-archive.json');
  final release = GitHubRelease(
    tagName: tag,
    name: tag,
    body: '',
    htmlUrl: Uri.parse('https://example.test/releases/$tag'),
    prerelease: channel == AppUpdateService.betaChannel,
    draft: false,
    publishedAt: DateTime.utc(2026, 8, 13),
    assets: [GitHubReleaseAsset(name: GitHubReleaseSource.archiveAssetName, downloadUrl: archiveUrl, state: 'uploaded', size: 1, digest: null)],
  );
  return GitHubReleaseSelection(release: release, version: Version.parse(tag.substring(1)), channel: channel, archiveUrl: archiveUrl);
}

class _FakeReleaseSource implements AppUpdateReleaseSource {
  _FakeReleaseSource(this._findLatest);

  final Future<GitHubReleaseSelection?> Function(bool includePrereleases) _findLatest;
  final List<bool> includePrereleases = [];
  bool closed = false;

  @override
  Future<GitHubReleaseSelection?> findLatest({required bool includePrereleases}) {
    this.includePrereleases.add(includePrereleases);
    return _findLatest(includePrereleases);
  }

  @override
  void close() => closed = true;
}

class _FakeControllerFactory implements AppUpdateControllerFactory {
  final List<_FakeController> created = [];

  @override
  AppUpdateController create({required Uri? appArchiveUrl, required String channel, required bool allowUnsignedMacOSUpdates}) {
    final controller = _FakeController(appArchiveUrl: appArchiveUrl, channel: channel, allowUnsignedMacOSUpdates: allowUnsignedMacOSUpdates);
    created.add(controller);
    return controller;
  }
}

class _FakeController implements AppUpdateController {
  _FakeController({required this.appArchiveUrl, required this.channel, required this.allowUnsignedMacOSUpdates});

  final Uri? appArchiveUrl;
  final String channel;
  final bool allowUnsignedMacOSUpdates;
  final List<VoidCallback> _listeners = [];

  UpdateState _state = const UpdateIdle();
  int checkCalls = 0;
  int downloadCalls = 0;
  int restartCalls = 0;
  bool disposed = false;

  @override
  UpdateState get state => _state;

  void emit(UpdateState state) {
    _state = state;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  Future<ManualUpdateCheckResult> checkForUpdates() async {
    checkCalls += 1;
    return const ManualUpdateCheckUpToDate();
  }

  @override
  Future<void> downloadUpdate() async => downloadCalls += 1;

  @override
  Future<void> restartApp() async => restartCalls += 1;

  @override
  void dispose() => disposed = true;
}
