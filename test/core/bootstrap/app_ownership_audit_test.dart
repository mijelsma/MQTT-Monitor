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

  test('domain and model layers stay independent from feature UI', () {
    final domainSources = <File>[...Directory('lib/core').listSync(recursive: true).whereType<File>(), ...Directory('lib/models').listSync(recursive: true).whereType<File>()].where((file) => file.path.endsWith('.dart') && !file.path.contains('/core/bootstrap/'));

    for (final source in domainSources) {
      expect(source.readAsStringSync(), isNot(contains('/features/')), reason: source.path);
    }
  });

  test('models stay free of Flutter widget ownership', () {
    final modelSources = Directory('lib/models').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));

    for (final source in modelSources) {
      final contents = source.readAsStringSync();
      expect(contents, isNot(contains("package:flutter/material.dart")), reason: source.path);
      expect(contents, isNot(contains("package:flutter/widgets.dart")), reason: source.path);
    }
  });
}
