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
}
