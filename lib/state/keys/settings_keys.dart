import 'package:flutter/material.dart';

import '../../ui/settings/models/broker_entry.dart';
import '../../ui/settings/models/language.dart';
import '../../ui/settings/settings_section.dart';
import '../persist.dart';
import '../state_key.dart';

abstract final class SettingsKeys {
  // Broker settings
  static final brokers = StateKey.fromJson<List<BrokerEntry>>('settings.brokers', defaultValue: const [], toJson: (list) => list.map((e) => e.toJson()).toList(), fromJson: (raw) => (raw as List).map((e) => BrokerEntry.fromJson(e as Map<String, dynamic>)).toList());

  // UI settings
  static final themeMode = StateKey.forEnum('settings.themeMode', ThemeMode.values, defaultValue: ThemeMode.system);
  static final showStatusBar = StateKey.boolean('settings.showStatusBar', defaultValue: true);
  static final showActivity = StateKey.boolean('settings.showActivity', defaultValue: true);
  static final persistLayout = StateKey.boolean('settings.persistLayout', defaultValue: true);
  static final language = StateKey.forKeyedEnum('settings.language', AppLanguage.values, defaultValue: AppLanguage.en);

  // UI state (not persisted)
  static final activeSettingsSection = StateKey.forEnum('ui.activeSettingsSection', SettingsSection.values, defaultValue: SettingsSection.brokers, persist: Persist.never);

  static final List<StateKey> all = [themeMode, showStatusBar, showActivity, persistLayout, language, brokers];
}
