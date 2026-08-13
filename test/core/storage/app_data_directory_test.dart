import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/storage/app_data_directory.dart';

void main() {
  group('desktop application-support path', () {
    test('uses roaming AppData on Windows', () {
      expect(AppDataDirectory.resolve(operatingSystem: 'windows', environment: const {'APPDATA': r'C:\Users\Michel\AppData\Roaming'}), r'C:\Users\Michel\AppData\Roaming\MQTT-Monitor');
    });

    test('uses Application Support on macOS', () {
      expect(AppDataDirectory.resolve(operatingSystem: 'macos', environment: const {'HOME': '/Users/michel'}), '/Users/michel/Library/Application Support/MQTT-Monitor');
    });

    test('uses XDG_DATA_HOME on Linux when configured', () {
      expect(AppDataDirectory.resolve(operatingSystem: 'linux', environment: const {'HOME': '/home/michel', 'XDG_DATA_HOME': '/mnt/profile/data'}), '/mnt/profile/data/MQTT-Monitor');
    });

    test('falls back to the standard Linux data directory', () {
      expect(AppDataDirectory.resolve(operatingSystem: 'linux', environment: const {'HOME': '/home/michel'}), '/home/michel/.local/share/MQTT-Monitor');
    });

    test('fails explicitly when required environment data is unavailable', () {
      expect(() => AppDataDirectory.resolve(operatingSystem: 'windows', environment: const {}), throwsStateError);
      expect(() => AppDataDirectory.resolve(operatingSystem: 'linux', environment: const {}), throwsStateError);
    });

    test('rejects platforms outside the supported desktop matrix', () {
      expect(() => AppDataDirectory.resolve(operatingSystem: 'android', environment: const {}), throwsUnsupportedError);
    });
  });
}
