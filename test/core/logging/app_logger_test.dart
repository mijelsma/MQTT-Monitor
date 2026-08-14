import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/logging/app_logger.dart';

void main() {
  test('redacts recognized and explicitly supplied secrets', () {
    final logger = LocalAppLogger();

    logger.log(AppLogLevel.error, 'mqtt.session', 'password=hunter2 token:abc123 broker-password', error: ArgumentError('private_key=hidden'), sensitiveValues: const ['broker-password']);

    final message = logger.events.single.message;
    expect(message, contains('password=[REDACTED]'));
    expect(message, contains('token=[REDACTED]'));
    expect(message, contains('[REDACTED]'));
    expect(message, isNot(contains('hunter2')));
    expect(message, isNot(contains('abc123')));
    expect(message, isNot(contains('broker-password')));
    expect(message, isNot(contains('hidden')));
    expect(message, contains('ArgumentError'));
  });

  test('keeps only the configured number of local diagnostic events', () {
    final logger = LocalAppLogger(maximumEntries: 2);

    logger.log(AppLogLevel.debug, 'test', 'first');
    logger.log(AppLogLevel.info, 'test', 'second');
    logger.log(AppLogLevel.warning, 'test', 'third');

    expect(logger.events.map((event) => event.message), ['second', 'third']);
  });

  test('persists only redacted diagnostics when file logging is enabled', () async {
    final directory = await Directory.systemTemp.createTemp('mqtt-monitor-log-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/mqtt-monitor.log');
    final logger = LocalAppLogger(logFilePath: file.path, clock: () => DateTime.utc(2026, 8, 14, 12));

    logger.log(AppLogLevel.error, 'mqtt.session', 'password=hunter2', sensitiveValues: const ['hunter2']);
    await logger.flush();

    final contents = await file.readAsString();
    expect(contents, contains('2026-08-14T12:00:00.000Z [ERROR] [mqtt.session]'));
    expect(contents, contains('password=[REDACTED]'));
    expect(contents, isNot(contains('hunter2')));
  });

  test('rotates a full diagnostic log instead of growing without bounds', () async {
    final directory = await Directory.systemTemp.createTemp('mqtt-monitor-log-rotation-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/mqtt-monitor.log');
    final logger = LocalAppLogger(logFilePath: file.path, maximumLogFileBytes: 80);

    logger.log(AppLogLevel.info, 'test', 'first entry that fills most of the deliberately tiny test log');
    logger.log(AppLogLevel.info, 'test', 'second entry starts a new log');
    await logger.flush();

    expect(await File('${file.path}.previous').exists(), isTrue);
    expect(await file.readAsString(), contains('second entry'));
  });
}
