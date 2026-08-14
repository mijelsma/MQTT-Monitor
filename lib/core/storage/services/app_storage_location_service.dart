import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../app_data_directory.dart';

typedef StorageUriLauncher = Future<bool> Function(Uri uri);

/// Resolves and opens the app-owned storage locations on desktop platforms.
class AppStorageLocationService {
  AppStorageLocationService({required this.operatingSystem, required this.environment, StorageUriLauncher? launcher, this.bundleIdentifier = 'com.micheljelsma.mqttmonitor'}) : _launcher = launcher ?? _launchExternally;

  factory AppStorageLocationService.standard() => AppStorageLocationService(operatingSystem: Platform.operatingSystem, environment: Platform.environment);

  static const sharedPreferencesFileName = 'shared_preferences.json';
  static const diagnosticLogFileName = 'mqtt-monitor.log';

  final String operatingSystem;
  final Map<String, String> environment;
  final String bundleIdentifier;
  final StorageUriLauncher _launcher;
  path.Context get _path => path.Context(style: operatingSystem == 'windows' ? path.Style.windows : path.Style.posix);

  String get applicationDataDirectory => AppDataDirectory.resolve(operatingSystem: operatingSystem, environment: environment);

  String get settingsFilePath {
    if (operatingSystem == 'macos') {
      final home = environment['HOME'];
      if (home == null || home.isEmpty) throw StateError('The home directory is not available.');
      return _path.join(home, 'Library', 'Preferences', '$bundleIdentifier.plist');
    }
    return _path.join(applicationDataDirectory, sharedPreferencesFileName);
  }

  String get diagnosticLogFilePath => _path.join(applicationDataDirectory, 'logs', diagnosticLogFileName);

  Future<void> openSettingsDirectory() async {
    final directory = Directory(_path.dirname(settingsFilePath));
    await directory.create(recursive: true);
    await _open(Uri.directory(directory.path, windows: operatingSystem == 'windows'));
  }

  Future<void> openDiagnosticLog() async {
    final file = File(diagnosticLogFilePath);
    await file.parent.create(recursive: true);
    if (!await file.exists()) await file.create();
    await _open(Uri.file(file.path, windows: operatingSystem == 'windows'));
  }

  Future<void> _open(Uri uri) async {
    if (!await _launcher(uri)) throw StateError('The operating system could not open $uri.');
  }

  static Future<bool> _launchExternally(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}
