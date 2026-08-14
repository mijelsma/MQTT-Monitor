import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Uses one readable, consistent folder for data that must survive updates.
///
/// This only changes the application-support path. Other path-provider paths
/// (temporary files, downloads and caches) keep their platform defaults.
abstract final class AppDataDirectory {
  static const folderName = 'MQTT-Monitor';
  static const supportedOperatingSystems = {'windows', 'macos', 'linux'};

  static Future<void> configure() async {
    if (!supportedOperatingSystems.contains(Platform.operatingSystem)) {
      return;
    }

    final directory = resolve(operatingSystem: Platform.operatingSystem, environment: Platform.environment);
    final destination = Directory(directory);
    await destination.create(recursive: true);
    final originalProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _NamedSupportPathProvider(delegate: originalProvider, supportDirectory: directory);
  }

  /// Resolves the app-owned support directory for a desktop environment.
  static String resolve({required String operatingSystem, required Map<String, String> environment}) {
    if (operatingSystem == 'windows') {
      final appData = environment['APPDATA'];
      if (appData == null || appData.isEmpty) {
        throw StateError('Windows APPDATA is not available.');
      }
      return path.Context(style: path.Style.windows).join(appData, folderName);
    }

    if (operatingSystem != 'macos' && operatingSystem != 'linux') {
      throw UnsupportedError('Application data is not configured for $operatingSystem.');
    }

    final home = environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('The home directory is not available.');
    }
    if (operatingSystem == 'macos') {
      return path.join(home, 'Library', 'Application Support', folderName);
    }

    final dataHome = environment['XDG_DATA_HOME'];
    return path.join(dataHome == null || dataHome.isEmpty ? path.join(home, '.local', 'share') : dataHome, folderName);
  }
}

class _NamedSupportPathProvider extends PathProviderPlatform {
  _NamedSupportPathProvider({required this.delegate, required this.supportDirectory});

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
  Future<String?> getApplicationDocumentsPath() => delegate.getApplicationDocumentsPath();

  @override
  Future<String?> getApplicationCachePath() => delegate.getApplicationCachePath();

  @override
  Future<String?> getExternalStoragePath() => delegate.getExternalStoragePath();

  @override
  Future<List<String>?> getExternalCachePaths() => delegate.getExternalCachePaths();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) => delegate.getExternalStoragePaths(type: type);

  @override
  Future<String?> getDownloadsPath() => delegate.getDownloadsPath();
}
