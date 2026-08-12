import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_value_extractor.dart';

void main() {
  final extractor = DashboardValueExtractor();

  test('parses plain values, units, JSON objects, and array paths', () {
    expect(DashboardValueExtractor.numericValue('23.5'), 23.5);
    expect(DashboardValueExtractor.numericValue('-4.25 °C'), -4.25);

    final decoded = extractor.decode('{"sensor":{"values":[1,"2.5"]}}');
    expect(extractor.extract(decoded, 'sensor.values[0]'), 1);
    expect(extractor.extract(decoded, 'sensor.values.[1]'), 2.5);

    final nested = extractor.decode('{"my_array":[[110,32.69,-22.52]]}');
    expect(extractor.extract(nested, 'my_array.[0].[0]'), 110);
    expect(extractor.extract(nested, 'my_array.[0].[1]'), 32.69);
    expect(extractor.extract(nested, 'my_array.[0].[2]'), -22.52);
  });

  test('supports root JSON numbers and strings without accepting other shapes', () {
    expect(extractor.extract(extractor.decode('42'), null), 42);
    expect(extractor.extract(extractor.decode('"12%"'), null), 12);
    expect(extractor.extract(extractor.decode('true'), null), isNull);
    expect(extractor.extract(extractor.decode('{"value":true}'), 'value'), isNull);
  });

  test('rejects missing, out-of-range, malformed paths and malformed JSON', () {
    final decoded = extractor.decode('{"values":[1]}');
    expect(extractor.extract(decoded, 'missing'), isNull);
    expect(extractor.extract(decoded, 'values[2]'), isNull);
    expect(() => extractor.extract(decoded, 'values[x]'), throwsFormatException);
    expect(() => extractor.decode('{broken'), throwsFormatException);
  });
}
