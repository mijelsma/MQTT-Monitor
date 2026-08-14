import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/storage/services/app_storage_location_service.dart';

void main() {
  group('storage paths', () {
    test('resolves the Windows settings and log files from APPDATA', () {
      final service = AppStorageLocationService(operatingSystem: 'windows', environment: const {'APPDATA': r'C:\Users\Michel\AppData\Roaming'});

      expect(service.settingsFilePath, r'C:\Users\Michel\AppData\Roaming\MQTT-Monitor\shared_preferences.json');
      expect(service.diagnosticLogFilePath, r'C:\Users\Michel\AppData\Roaming\MQTT-Monitor\logs\mqtt-monitor.log');
    });

    test('resolves the Linux settings and log files from XDG_DATA_HOME', () {
      final service = AppStorageLocationService(operatingSystem: 'linux', environment: const {'HOME': '/home/michel', 'XDG_DATA_HOME': '/profile/data'});

      expect(service.settingsFilePath, '/profile/data/MQTT-Monitor/shared_preferences.json');
      expect(service.diagnosticLogFilePath, '/profile/data/MQTT-Monitor/logs/mqtt-monitor.log');
    });

    test('resolves sandbox-aware macOS preferences from the runtime home', () {
      final service = AppStorageLocationService(operatingSystem: 'macos', environment: const {'HOME': '/sandbox/home'}, bundleIdentifier: 'com.example.monitor');

      expect(service.settingsFilePath, '/sandbox/home/Library/Preferences/com.example.monitor.plist');
      expect(service.diagnosticLogFilePath, '/sandbox/home/Library/Application Support/MQTT-Monitor/logs/mqtt-monitor.log');
    });
  });

  test('opens the settings directory and creates the log before opening it', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp('mqtt-monitor-storage-test-');
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final opened = <Uri>[];
    final service = AppStorageLocationService(
      operatingSystem: 'linux',
      environment: {'HOME': temporaryDirectory.path, 'XDG_DATA_HOME': temporaryDirectory.path},
      launcher: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    await service.openSettingsDirectory();
    await service.openDiagnosticLog();

    expect(opened, [Uri.directory('${temporaryDirectory.path}/MQTT-Monitor'), Uri.file(service.diagnosticLogFilePath)]);
    expect(File(service.diagnosticLogFilePath).existsSync(), isTrue);
  });

  test('reports when the operating system cannot open a location', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp('mqtt-monitor-storage-failure-test-');
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final service = AppStorageLocationService(operatingSystem: 'linux', environment: {'HOME': temporaryDirectory.path}, launcher: (_) async => false);

    await expectLater(service.openSettingsDirectory(), throwsStateError);
  });
}
