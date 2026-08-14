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

  test('core stays independent from feature and application layers', () {
    final domainSources = Directory('lib/core').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));

    for (final source in domainSources) {
      final contents = source.readAsStringSync();
      expect(contents, isNot(contains('/features/')), reason: source.path);
      expect(contents, isNot(contains('/application/')), reason: source.path);
    }
  });

  test('domain models stay owned by core capabilities and widget-free', () {
    final modelSources = Directory('lib/core').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart') && file.path.contains('/models/'));

    for (final source in modelSources) {
      final contents = source.readAsStringSync();
      expect(contents, isNot(contains("package:flutter/material.dart")), reason: source.path);
      expect(contents, isNot(contains("package:flutter/widgets.dart")), reason: source.path);
    }

    final legacyModels = Directory('lib/models');
    if (legacyModels.existsSync()) {
      expect(legacyModels.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')), isEmpty);
    }
  });

  test('architectural role filenames match their primary declarations', () {
    const folderSuffixes = {'/models/': '_model.dart', '/interfaces/': '_interface.dart', '/repositories/': '_repository.dart', '/services/': '_service.dart', '/controllers/': '_controller.dart', '/view_models/': '_view_model.dart'};
    final roleDeclaration = RegExp(r'^(?:abstract interface class|abstract class|class|enum) ([A-Z]\w*(?:Model|Interface|Repository|Service|Controller|ViewModel))\b', multiLine: true);
    final dartSources = Directory('lib').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));

    for (final source in dartSources) {
      final path = source.path;
      final fileName = source.uri.pathSegments.last;
      for (final rule in folderSuffixes.entries) {
        if (path.contains(rule.key)) {
          expect(fileName, endsWith(rule.value), reason: path);
        }
      }

      final declarations = roleDeclaration.allMatches(source.readAsStringSync()).map((match) => match.group(1)!).toList(growable: false);
      if (declarations.isEmpty) continue;
      final expectedName = _pascalCase(fileName.substring(0, fileName.length - '.dart'.length));
      expect(declarations, contains(expectedName), reason: '$path should declare $expectedName');
    }
  });
}

String _pascalCase(String value) => value.split('_').map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join();
