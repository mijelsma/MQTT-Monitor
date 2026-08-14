import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('declared application icon is bundled and non-empty', () async {
    final data = await rootBundle.load('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png');

    expect(data.lengthInBytes, greaterThan(0));
  });
}
