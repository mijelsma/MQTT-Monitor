import 'dart:collection';
import 'dart:convert';
import 'dart:io';

enum AppLogLevel { debug, info, warning, error }

class AppDiagnosticEvent {
  const AppDiagnosticEvent({required this.timestamp, required this.level, required this.area, required this.message});

  final DateTime timestamp;
  final AppLogLevel level;
  final String area;
  final String message;
}

abstract interface class AppLogger {
  void log(AppLogLevel level, String area, String message, {Object? error, Iterable<String> sensitiveValues = const []});

  Future<void> flush();
}

/// Keeps bounded in-memory diagnostics and optionally persists a redacted log.
class LocalAppLogger implements AppLogger {
  LocalAppLogger({this.maximumEntries = 200, this.logFilePath, this.maximumLogFileBytes = 5 * 1024 * 1024, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final int maximumEntries;
  final String? logFilePath;
  final int maximumLogFileBytes;
  final DateTime Function() _clock;
  final ListQueue<AppDiagnosticEvent> _events = ListQueue();
  Future<void> _pendingWrite = Future.value();

  List<AppDiagnosticEvent> get events => List.unmodifiable(_events);

  @override
  void log(AppLogLevel level, String area, String message, {Object? error, Iterable<String> sensitiveValues = const []}) {
    var redacted = error == null ? message : '$message (${error.runtimeType})';
    redacted = _redactPatterns(redacted);
    for (final value in sensitiveValues.where((value) => value.isNotEmpty)) {
      redacted = redacted.replaceAll(value, '[REDACTED]');
    }
    final event = AppDiagnosticEvent(timestamp: _clock(), level: level, area: area, message: redacted);
    _events.addLast(event);
    while (_events.length > maximumEntries) {
      _events.removeFirst();
    }
    if (logFilePath case final filePath?) {
      _pendingWrite = _pendingWrite.then((_) => _append(File(filePath), event)).catchError((_) {});
    }
  }

  @override
  Future<void> flush() => _pendingWrite;

  Future<void> _append(File file, AppDiagnosticEvent event) async {
    await file.parent.create(recursive: true);
    final line = '${event.timestamp.toUtc().toIso8601String()} [${event.level.name.toUpperCase()}] [${event.area}] ${event.message}\n';
    final lineBytes = utf8.encode(line).length;
    if (await file.exists() && await file.length() + lineBytes > maximumLogFileBytes) {
      final previous = File('${file.path}.previous');
      if (await previous.exists()) await previous.delete();
      await file.rename(previous.path);
    }
    await file.writeAsString(line, mode: FileMode.append);
  }
}

String _redactPatterns(String value) {
  return value.replaceAllMapped(RegExp(r'\b(password|passwd|token|secret|authorization|private[_ -]?key)\b\s*[:=]\s*([^\s,;]+)', caseSensitive: false), (match) => '${match.group(1)}=[REDACTED]');
}
