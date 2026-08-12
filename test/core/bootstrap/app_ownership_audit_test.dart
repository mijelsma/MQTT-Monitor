import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production code has no generic app-state singleton access', () {
    final dartSources = Directory('lib').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));

    for (final source in dartSources) {
      expect(source.readAsStringSync(), isNot(contains('AppStateManager')), reason: source.path);
    }
    final legacyDirectory = Directory('lib/core/state');
    if (legacyDirectory.existsSync()) {
      expect(legacyDirectory.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')), isEmpty);
    }
  });
}
