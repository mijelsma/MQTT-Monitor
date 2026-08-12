import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/bootstrap/app_bootstrap.dart';
import 'package:mqtt_monitor/core/bootstrap/app_bootstrap_shell.dart';
import 'package:mqtt_monitor/core/bootstrap/app_lifetime.dart';

void main() {
  testWidgets('startup failure names the stage and can be retried', (tester) async {
    final bootstrap = _FailingBootstrap();

    await tester.pumpWidget(AppBootstrapShell(bootstrap: bootstrap));
    await tester.pumpAndSettle();

    expect(find.text('MQTT Monitor could not start'), findsOneWidget);
    expect(find.textContaining('preferences'), findsOneWidget);
    expect(bootstrap.attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(bootstrap.attempts, 2);
    expect(find.text('MQTT Monitor could not start'), findsOneWidget);
  });
}

class _FailingBootstrap implements AppBootstrap {
  int attempts = 0;

  @override
  Future<AppLifetime> initialize() {
    attempts += 1;
    return Future<AppLifetime>.error(const AppInitializationFailure('preferences', FormatException('bad data')));
  }
}
