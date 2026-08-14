import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/application/bootstrap/app_bootstrap.dart';
import 'package:mqtt_monitor/application/bootstrap/app_lifetime.dart';
import 'package:mqtt_monitor/core/logging/app_logger.dart';

void main() {
  test('initialization stages run sequentially before assembly', () async {
    final calls = <String>[];
    final initializer = StagedInitializer<String>(
      logger: LocalAppLogger(),
      stages: [
        AppInitializationStage('first', () async {
          calls.add('first:start');
          await Future<void>.delayed(Duration.zero);
          calls.add('first:end');
        }),
        AppInitializationStage('second', () => calls.add('second')),
      ],
      assemble: () {
        calls.add('assemble');
        return 'ready';
      },
    );

    expect(await initializer.initialize(), 'ready');
    expect(calls, ['first:start', 'first:end', 'second', 'assemble']);
  });

  test('failure identifies its stage and cleans partial ownership once', () async {
    final logger = LocalAppLogger();
    var cleanupCalls = 0;
    final initializer = StagedInitializer<void>(logger: logger, stages: [AppInitializationStage('preferences', () {}), AppInitializationStage('message pipeline', () => throw StateError('failed')), AppInitializationStage('unreachable', () => fail('must not run'))], assemble: () {}, onFailure: () => cleanupCalls += 1);

    await expectLater(initializer.initialize(), throwsA(isA<AppInitializationFailure>().having((failure) => failure.stage, 'stage', 'message pipeline').having((failure) => failure.cause, 'cause', isA<StateError>())));
    expect(cleanupCalls, 1);
    expect(logger.events.last.area, 'app.bootstrap');
    expect(logger.events.last.level, AppLogLevel.error);
  });

  test('shutdown is ordered, idempotent, and continues after failures', () async {
    final calls = <String>[];
    final logger = LocalAppLogger();
    final coordinator = AppShutdownCoordinator([
      AppShutdownTask('first', () async {
        calls.add('first:start');
        await Future<void>.delayed(Duration.zero);
        calls.add('first:end');
      }),
      AppShutdownTask('failing', () {
        calls.add('failing');
        throw StateError('cleanup failed');
      }),
      AppShutdownTask('last', () => calls.add('last')),
    ], logger);

    await Future.wait([coordinator.shutdown(), coordinator.shutdown()]);

    expect(calls, ['first:start', 'first:end', 'failing', 'last']);
    expect(logger.events.single.area, 'app.shutdown');
    expect(logger.events.single.message, contains('failing'));
  });

  test('cleanup failure does not replace the initialization failure', () async {
    final logger = LocalAppLogger();
    final initializer = StagedInitializer<void>(logger: logger, stages: [AppInitializationStage('storage', () => throw const FormatException('bad'))], assemble: () {}, onFailure: () => throw StateError('cleanup failed'));

    await expectLater(initializer.initialize(), throwsA(isA<AppInitializationFailure>().having((failure) => failure.stage, 'stage', 'storage').having((failure) => failure.cause, 'cause', isA<FormatException>())));
    expect(logger.events.last.level, AppLogLevel.warning);
    expect(logger.events.last.message, contains('cleanup'));
  });
}
