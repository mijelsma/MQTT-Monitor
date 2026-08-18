import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:mqtt_monitor/core/ui/repositories/ui_preferences_repository.dart';
import 'package:mqtt_monitor/core/ui/models/app_language_model.dart';
import 'package:mqtt_monitor/core/ui/models/sidebar_panel_default_model.dart';
import 'package:mqtt_monitor/core/ui/models/ui_density_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('version 1 defaults match the existing UI behavior', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferencesStore.load();
    final repository = UiPreferencesRepository(store);

    await repository.initialize();

    expect(repository.themeMode, ThemeMode.system);
    expect(repository.accentColor, 0xFF6366F1);
    expect(repository.showStatusBar, isTrue);
    expect(repository.showActivity, isTrue);
    expect(repository.disableSelectionHighlight, isFalse);
    expect(repository.pulseRatePps, 15);
    expect(repository.pulseFadeMs, 500);
    expect(repository.persistLayout, isTrue);
    expect(repository.sidebarAnimationsEnabled, isTrue);
    expect(repository.sidebarAnimationSpeed, 50);
    expect(repository.defaultSidebarDetail, SidebarPanelDefaultModel.expanded);
    expect(repository.defaultSidebarHistory, SidebarPanelDefaultModel.collapsed);
    expect(repository.defaultSidebarPublish, SidebarPanelDefaultModel.collapsed);
    expect(repository.defaultSidebarShortcuts, SidebarPanelDefaultModel.collapsed);
    expect(repository.language, AppLanguageModel.en);
    expect(repository.density, UiDensityModel.comfortable);
    expect(repository.showTopicPayloadPreview, isTrue);
    expect(repository.showTopicBadges, isTrue);
    expect(repository.richPayloadFormattingLimitBytes, 32 * 1024);
    expect(store.get(UiPreferencesRepository.schemaVersionKey), UiPreferencesRepository.currentSchemaVersion);
  });

  test('all UI preferences retain their existing keys and round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferencesStore.load();
    final repository = UiPreferencesRepository(store);
    await repository.initialize();

    await repository.setThemeMode(ThemeMode.dark);
    await repository.setAccentColor(0xFF0EA5E9);
    await repository.setShowStatusBar(false);
    await repository.setShowActivity(false);
    await repository.setDisableSelectionHighlight(true);
    await repository.setPulseRatePps(1);
    await repository.setPulseFadeMs(50);
    await repository.setPersistLayout(false);
    await repository.setSidebarAnimationsEnabled(false);
    await repository.setSidebarAnimationSpeed(80);
    await repository.setDefaultSidebarDetail(SidebarPanelDefaultModel.collapsed);
    await repository.setDefaultSidebarHistory(SidebarPanelDefaultModel.expanded);
    await repository.setDefaultSidebarPublish(SidebarPanelDefaultModel.lastStatus);
    await repository.setDefaultSidebarShortcuts(SidebarPanelDefaultModel.lastStatus);
    await repository.setLanguage(AppLanguageModel.nl);
    await repository.setDensity(UiDensityModel.compact);
    await repository.setShowTopicPayloadPreview(false);
    await repository.setShowTopicBadges(false);
    await repository.setRichPayloadFormattingLimitBytes(128 * 1024);

    final restored = UiPreferencesRepository(store);
    await restored.initialize();

    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.accentColor, 0xFF0EA5E9);
    expect(restored.showStatusBar, isFalse);
    expect(restored.showActivity, isFalse);
    expect(restored.disableSelectionHighlight, isTrue);
    expect(restored.pulseRatePps, 1);
    expect(restored.pulseFadeMs, 50);
    expect(restored.persistLayout, isFalse);
    expect(restored.sidebarAnimationsEnabled, isFalse);
    expect(restored.sidebarAnimationSpeed, 80);
    expect(restored.defaultSidebarDetail, SidebarPanelDefaultModel.collapsed);
    expect(restored.defaultSidebarHistory, SidebarPanelDefaultModel.expanded);
    expect(restored.defaultSidebarPublish, SidebarPanelDefaultModel.lastStatus);
    expect(restored.defaultSidebarShortcuts, SidebarPanelDefaultModel.lastStatus);
    expect(restored.language, AppLanguageModel.nl);
    expect(restored.density, UiDensityModel.compact);
    expect(restored.showTopicPayloadPreview, isFalse);
    expect(restored.showTopicBadges, isFalse);
    expect(restored.richPayloadFormattingLimitBytes, 128 * 1024);
    expect(store.get(UiPreferencesRepository.themeModeKey), 'dark');
    expect(store.get(UiPreferencesRepository.languageKey), 'nl');
    expect(store.get(UiPreferencesRepository.persistLayoutKey), isFalse);
  });

  test('bounded animation settings reject out-of-range stored values', () async {
    SharedPreferences.setMockInitialValues({UiPreferencesRepository.schemaVersionKey: 1, UiPreferencesRepository.pulseRatePpsKey: 200, UiPreferencesRepository.pulseFadeMsKey: -1, UiPreferencesRepository.sidebarAnimationSpeedKey: 101});
    final repository = UiPreferencesRepository(await SharedPreferencesStore.load());

    await repository.initialize();

    expect(repository.pulseRatePps, 15);
    expect(repository.pulseFadeMs, 500);
    expect(repository.sidebarAnimationSpeed, 50);
  });
}
