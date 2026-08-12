import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:mqtt_monitor/core/update/app_update_controller.dart';
import 'package:mqtt_monitor/core/update/app_update_lifecycle.dart';
import 'package:mqtt_monitor/core/update/app_update_service.dart';
import 'package:mqtt_monitor/core/update/github_release_source.dart';
import 'package:mqtt_monitor/core/update/update_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('starts the lifetime-owned updater after child build', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferencesStore.load();
    final preferences = UpdatePreferencesRepository(store);
    await preferences.initialize();

    var childBuilt = false;
    final source = _LifecycleReleaseSource(() {
      expect(childBuilt, isTrue);
    });
    final controllers = _LifecycleControllerFactory();
    final service = AppUpdateService(preferences: preferences, releaseSource: source, controllerFactory: controllers);

    await tester.pumpWidget(
      AppUpdateLifecycle(
        service: service,
        child: Builder(
          builder: (context) {
            childBuilt = true;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    expect(source.calls, 1);
    expect(source.closed, isFalse);

    await tester.pumpWidget(const SizedBox());

    expect(source.closed, isFalse);
    service.dispose();
    expect(source.closed, isTrue);
    expect(controllers.created, isNotEmpty);
    expect(controllers.created.every((controller) => controller.disposed), isTrue);
  });
}

class _LifecycleReleaseSource implements AppUpdateReleaseSource {
  _LifecycleReleaseSource(this.onFindLatest);

  final VoidCallback onFindLatest;
  int calls = 0;
  bool closed = false;

  @override
  Future<GitHubReleaseSelection?> findLatest({required bool includePrereleases}) async {
    calls += 1;
    onFindLatest();
    return null;
  }

  @override
  void close() => closed = true;
}

class _LifecycleControllerFactory implements AppUpdateControllerFactory {
  final List<_LifecycleController> created = [];

  @override
  AppUpdateController create({required Uri? appArchiveUrl, required String channel, required bool allowUnsignedMacOSUpdates}) {
    final controller = _LifecycleController();
    created.add(controller);
    return controller;
  }
}

class _LifecycleController implements AppUpdateController {
  bool disposed = false;

  @override
  UpdateState get state => const UpdateIdle();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<ManualUpdateCheckResult> checkForUpdates() async => const ManualUpdateCheckUpToDate();

  @override
  Future<void> downloadUpdate() async {}

  @override
  Future<void> restartApp() async {}

  @override
  void dispose() => disposed = true;
}
