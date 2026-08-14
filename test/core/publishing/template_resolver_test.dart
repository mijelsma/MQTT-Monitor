import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/publishing/template_resolver.dart';

void main() {
  const resolver = TemplateResolver();

  test('resolves repeated valid placeholders from one value map', () {
    final result = resolver.resolve(r'sensors/${SITE}/${DEVICE}/${DEVICE}', {
      'SITE': 'north',
      'DEVICE': '42',
    });

    expect(result.value, 'sensors/north/42/42');
    expect(result.missingVariables, isEmpty);
  });

  test('reports each missing or empty variable once', () {
    final result = resolver.resolve(r'${SITE}/${DEVICE}/${SITE}', {
      'SITE': '',
      'OTHER': 'ignored',
    });

    expect(result.value, r'${SITE}/${DEVICE}/${SITE}');
    expect(result.missingVariables, ['SITE', 'DEVICE']);
  });

  test('rejects malformed placeholders and variable names', () {
    expect(resolver.validateTemplate(r'sensor/${BAD-NAME}'), isNotNull);
    expect(resolver.validateTemplate(r'sensor/${OPEN'), isNotNull);
    expect(resolver.validateTemplate('sensor/stray}'), isNotNull);
    expect(resolver.isValidVariableName('SITE_2'), isTrue);
    expect(resolver.isValidVariableName('2_SITE'), isFalse);
  });
}
