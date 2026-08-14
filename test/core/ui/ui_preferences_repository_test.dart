import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:mqtt_monitor/core/ui/ui_preferences_repository.dart';
import 'package:mqtt_monitor/models/language.dart';
import 'package:mqtt_monitor/models/sidebar_panel_default.dart';
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
    expect(repository.defaultSidebarDetail, SidebarPanelDefault.expanded);
    expect(repository.defaultSidebarHistory, SidebarPanelDefault.collapsed);
    expect(repository.defaultSidebarPublish, SidebarPanelDefault.collapsed);
    expect(repository.defaultSidebarShortcuts, SidebarPanelDefault.collapsed);
    expect(repository.language, AppLanguage.en);
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
    await repository.setDefaultSidebarDetail(SidebarPanelDefault.collapsed);
    await repository.setDefaultSidebarHistory(SidebarPanelDefault.expanded);
    await repository.setDefaultSidebarPublish(SidebarPanelDefault.lastStatus);
    await repository.setDefaultSidebarShortcuts(SidebarPanelDefault.lastStatus);
    await repository.setLanguage(AppLanguage.nl);

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
    expect(restored.defaultSidebarDetail, SidebarPanelDefault.collapsed);
    expect(restored.defaultSidebarHistory, SidebarPanelDefault.expanded);
    expect(restored.defaultSidebarPublish, SidebarPanelDefault.lastStatus);
    expect(restored.defaultSidebarShortcuts, SidebarPanelDefault.lastStatus);
    expect(restored.language, AppLanguage.nl);
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
