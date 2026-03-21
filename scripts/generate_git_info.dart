/// Generates `lib/generated/git_info.dart` and updates the `version` field
/// in `pubspec.yaml` — both derived from git tags.
///
/// Run before building:
///   dart run scripts/generate_git_info.dart
library;

import 'dart:io';

void main() {
  final describe = _run('git', ['describe', '--tags', '--dirty']);
  final commitHash = _run('git', ['rev-parse', '--short', 'HEAD']);
  final fullHash = _run('git', ['rev-parse', 'HEAD']);

  // Parse the base semver and commits-since-tag from describe output.
  // e.g. "v0.1.0-5-gabcdef-dirty" → version "0.1.0", build 5
  // e.g. "v0.1.0" (exactly on tag) → version "0.1.0", build 1
  final tagVersion = _parseTagVersion(describe);
  final buildNumber = _parseCommitsSinceTag(describe);
  final isDirty = describe.endsWith('-dirty');

  // ── 1. Generate git_info.dart ────────────────────────────────────────
  File('lib/generated/git_info.dart').writeAsStringSync('''// GENERATED FILE — DO NOT EDIT.
// Run: dart run scripts/generate_git_info.dart

class GitInfo {
  const GitInfo._();

  /// Full `git describe --tags --dirty` output (e.g. "v0.1.0-3-gabcdef-dirty").
  static const String describe = '$describe';

  /// Semantic version from the nearest tag (e.g. "0.1.0").
  static const String version = '$tagVersion';

  /// Build number (commits since last tag, or 1 if on the tag).
  static const int buildNumber = $buildNumber;

  /// Short commit hash (e.g. "abcdef0").
  static const String commitHash = '$commitHash';

  /// Full commit hash.
  static const String fullHash = '$fullHash';

  /// Whether the working tree had uncommitted changes at build time.
  static const bool dirty = $isDirty;
}
''');

  // ── 2. Update pubspec.yaml version field ─────────────────────────────
  final pubspec = File('pubspec.yaml');
  final content = pubspec.readAsStringSync();
  final updated = content.replaceFirst(RegExp(r'version:\s*\S+'), 'version: $tagVersion+$buildNumber');
  pubspec.writeAsStringSync(updated);

  stdout.writeln('Generated git_info.dart  (describe: $describe)');
  stdout.writeln('Updated pubspec.yaml     (version: $tagVersion+$buildNumber)');
}

/// Extracts "X.Y.Z" from a git describe string like "v0.1.0-3-gabcdef-dirty".
String _parseTagVersion(String describe) {
  final match = RegExp(r'^v?(\d+\.\d+\.\d+)').firstMatch(describe);
  return match?.group(1) ?? '0.0.0';
}

/// Extracts the commits-since-tag count from describe output.
/// "v0.1.0-5-gabcdef" → 5, "v0.1.0" (exactly on tag) → 1.
int _parseCommitsSinceTag(String describe) {
  final match = RegExp(r'^\D*\d+\.\d+\.\d+-(\d+)-g').firstMatch(describe);
  final count = match != null ? int.parse(match.group(1)!) : 0;
  return count > 0 ? count : 1;
}

String _run(String exe, List<String> args) {
  final result = Process.runSync(exe, args);
  if (result.exitCode != 0) {
    stderr.writeln('Command failed: $exe ${args.join(' ')}');
    stderr.writeln(result.stderr);
    exit(1);
  }
  return (result.stdout as String).trim();
}
