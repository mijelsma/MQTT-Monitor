import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/theme/app_theme.dart';
import 'package:mqtt_monitor/theme/app_theme_builder.dart';
import 'package:mqtt_monitor/theme/app_tokens/app_tokens.dart';
import 'package:mqtt_monitor/core/ui/ui_preferences_repository.dart';
import 'package:provider/provider.dart';

import '../support/test_dependencies.dart';

void main() {
  test('light and dark themes expose stable semantic tokens', () {
    final light = themeLight.extension<AppTokens>()!;
    final dark = themeDark.extension<AppTokens>()!;

    expect(light.success, isNot(light.warning));
    expect(light.info, isNot(light.error));
    expect(dark.success, isNot(light.success));
    expect(dark.warning, isNot(light.warning));
    expect(light.controlRadius, 10);
    expect(dark.panelRadius, 12);
  });

  test('runtime accent updates semantic interaction colors in both modes', () {
    const accents = [Color(0xFFFFD600), Color(0xFF6366F1), Color(0xFF2563EB), Color(0xFF312E81)];
    for (final accent in accents) {
      final light = AppThemeBuilder.withAccent(themeLight, accent, Brightness.light);
      final dark = AppThemeBuilder.withAccent(themeDark, accent, Brightness.dark);

      for (final theme in [light, dark]) {
        final tokens = theme.extension<AppTokens>()!;
        expect(theme.colorScheme.primary, accent);
        expect(tokens.primary, accent);
        expect(tokens.focusRing, accent);
        expect(tokens.selectedBg.a, greaterThan(0));
        expect(_contrastRatio(tokens.primary, tokens.onPrimary), greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets('theme selectors ignore unrelated UI preference changes', (tester) async {
    final dependencies = await TestDependencies.create();
    var builds = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: dependencies.uiPreferences,
        child: _ThemeSelectionProbe(onBuild: () => builds++),
      ),
    );
    expect(builds, 1);

    await dependencies.uiPreferences.setShowActivity(false);
    await tester.pump();
    expect(builds, 1);

    await dependencies.uiPreferences.setAccentColor(0xFF0EA5E9);
    await tester.pump();
    expect(builds, 2);

    await dependencies.uiPreferences.setThemeMode(ThemeMode.dark);
    await tester.pump();
    expect(builds, 3);
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker = firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

class _ThemeSelectionProbe extends StatelessWidget {
  const _ThemeSelectionProbe({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    context.select((UiPreferencesRepository preferences) => (preferences.themeMode, preferences.accentColor, preferences.language));
    onBuild();
    return const SizedBox.shrink();
  }
}
