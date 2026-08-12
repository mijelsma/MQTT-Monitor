import 'dart:collection';

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
}

/// Keeps a bounded, local-only diagnostic history with secret redaction.
class LocalAppLogger implements AppLogger {
  LocalAppLogger({this.maximumEntries = 200, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final int maximumEntries;
  final DateTime Function() _clock;
  final ListQueue<AppDiagnosticEvent> _events = ListQueue();

  List<AppDiagnosticEvent> get events => List.unmodifiable(_events);

  @override
  void log(AppLogLevel level, String area, String message, {Object? error, Iterable<String> sensitiveValues = const []}) {
    var redacted = error == null ? message : '$message (${error.runtimeType})';
    redacted = _redactPatterns(redacted);
    for (final value in sensitiveValues.where((value) => value.isNotEmpty)) {
      redacted = redacted.replaceAll(value, '[REDACTED]');
    }
    _events.addLast(AppDiagnosticEvent(timestamp: _clock(), level: level, area: area, message: redacted));
    while (_events.length > maximumEntries) {
      _events.removeFirst();
    }
  }
}

String _redactPatterns(String value) {
  return value.replaceAllMapped(RegExp(r'\b(password|passwd|token|secret|authorization|private[_ -]?key)\b\s*[:=]\s*([^\s,;]+)', caseSensitive: false), (match) => '${match.group(1)}=[REDACTED]');
}
