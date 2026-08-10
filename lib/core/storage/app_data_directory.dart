import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Uses one readable, consistent folder for data that must survive updates.
///
/// This only changes the application-support path. Other path-provider paths
/// (temporary files, downloads and caches) keep their platform defaults.
abstract final class AppDataDirectory {
  static const _folderName = 'MQTT-Monitor';

  static Future<void> configure() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    final directory = _directoryForCurrentPlatform();
    final originalProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _NamedSupportPathProvider(
      delegate: originalProvider,
      supportDirectory: directory,
    );

    final destination = Directory(directory);
    if (await destination.exists()) {
      return;
    }
    await destination.create(recursive: true);
    for (final sourcePath in _legacyDirectories()) {
      final source = Directory(sourcePath);
      if (await source.exists()) {
        await _copyMissingContents(source, destination);
      }
    }
  }

  static String _directoryForCurrentPlatform() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData == null || appData.isEmpty) {
        throw StateError('Windows APPDATA is not available.');
      }
      return path.join(appData, _folderName);
    }

    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('The home directory is not available.');
    }
    if (Platform.isMacOS) {
      return path.join(home, 'Library', 'Application Support', _folderName);
    }

    final dataHome = Platform.environment['XDG_DATA_HOME'];
    return path.join(
      dataHome == null || dataHome.isEmpty
          ? path.join(home, '.local', 'share')
          : dataHome,
      _folderName,
    );
  }

  static Iterable<String> _legacyDirectories() sync* {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        yield path.join(appData, 'com.example', 'mqtt_monitor');
      }
      return;
    }

    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return;
    if (Platform.isMacOS) {
      yield path.join(
        home,
        'Library',
        'Application Support',
        'com.example.mqttMonitor',
      );
      return;
    }

    final dataHome = Platform.environment['XDG_DATA_HOME'];
    yield path.join(
      dataHome == null || dataHome.isEmpty
          ? path.join(home, '.local', 'share')
          : dataHome,
      'com.example.mqtt_monitor',
    );
  }

  static Future<void> _copyMissingContents(
    Directory source,
    Directory destination,
  ) async {
    await for (final entity in source.list(followLinks: false)) {
      final targetPath = path.join(
        destination.path,
        path.basename(entity.path),
      );
      if (entity is Directory) {
        final target = Directory(targetPath);
        await target.create(recursive: true);
        await _copyMissingContents(entity, target);
      } else if (entity is File && !await File(targetPath).exists()) {
        await entity.copy(targetPath);
      }
    }
  }
}

class _NamedSupportPathProvider extends PathProviderPlatform {
  _NamedSupportPathProvider({
    required this.delegate,
    required this.supportDirectory,
  });

  final PathProviderPlatform delegate;
  final String supportDirectory;

  @override
  Future<String?> getTemporaryPath() => delegate.getTemporaryPath();

  @override
  Future<String?> getApplicationSupportPath() async {
    await Directory(supportDirectory).create(recursive: true);
    return supportDirectory;
  }

  @override
  Future<String?> getLibraryPath() => delegate.getLibraryPath();

  @override
  Future<String?> getApplicationDocumentsPath() =>
      delegate.getApplicationDocumentsPath();

  @override
  Future<String?> getApplicationCachePath() =>
      delegate.getApplicationCachePath();

  @override
  Future<String?> getExternalStoragePath() => delegate.getExternalStoragePath();

  @override
  Future<List<String>?> getExternalCachePaths() =>
      delegate.getExternalCachePaths();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) =>
      delegate.getExternalStoragePaths(type: type);

  @override
  Future<String?> getDownloadsPath() => delegate.getDownloadsPath();
}
