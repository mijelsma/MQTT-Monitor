import 'package:flutter/material.dart';

import '../../../models/broker_entry.dart';
import '../../../models/language.dart';
import '../state_key.dart';

/// Defines the keys used in the app state for managing settings and preferences.
abstract final class SettingsKeys {
  // Brokers panel
  static final brokers = StateKey.fromJson<List<BrokerEntry>>('settings.brokers', defaultValue: const [], toJson: (list) => list.map((e) => e.toJson()).toList(), fromJson: (raw) => (raw as List).map((e) => BrokerEntry.fromJson(e as Map<String, dynamic>)).toList());

  // UI panel
  static final themeMode = StateKey.forEnum('settings.themeMode', ThemeMode.values, defaultValue: ThemeMode.system);
  static final showStatusBar = StateKey.boolean('settings.showStatusBar', defaultValue: true);
  static final rateIntervalMs = StateKey.integer('settings.rateIntervalMs', defaultValue: 1000);
  static final showActivity = StateKey.boolean('settings.showActivity', defaultValue: true);
  static final pulseRatePps = StateKey.integer('settings.pulseRatePps', defaultValue: 15);
  static final pulseFadeMs = StateKey.integer('settings.pulseFadeMs', defaultValue: 500);
  static final persistLayout = StateKey.boolean('settings.persistLayout', defaultValue: true);

  // Language panel
  static final language = StateKey.forEnum('settings.language', AppLanguage.values, defaultValue: AppLanguage.en);

  static final List<StateKey> all = [themeMode, showStatusBar, showActivity, pulseRatePps, pulseFadeMs, persistLayout, rateIntervalMs, language, brokers];
}
