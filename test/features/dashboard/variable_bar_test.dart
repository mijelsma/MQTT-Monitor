import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/publishing/models/environment_variable_model.dart';
import 'package:mqtt_monitor/core/publishing/models/environment_variable_option_model.dart';
import 'package:mqtt_monitor/features/dashboard/widgets/variable_bar.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';

void main() {
  testWidgets('variable picker options fill the dialog and center their text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: themeLight,
        home: Scaffold(
          body: Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 300,
                child: VariableBar(
                  variables: [
                    EnvironmentVariableModel(
                      name: 'REGION',
                      options: const [
                        EnvironmentVariableOptionModel(label: 'Europe', value: 'eu'),
                        EnvironmentVariableOptionModel(label: 'North America', value: 'us'),
                      ],
                    ),
                  ],
                  values: const {},
                  onChanged: (_, _) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('REGION'));
    await tester.pumpAndSettle();

    final option = find.ancestor(of: find.text('Europe'), matching: find.byType(InkWell)).first;
    expect(tester.getSize(option).width, greaterThan(300));
    expect(tester.widget<Text>(find.text('Europe')).textAlign, TextAlign.center);
    expect(tester.widget<Text>(find.text('eu')).textAlign, TextAlign.center);
  });
}
