import 'package:flutter/material.dart';

import '../../ui/settings/models/broker_entry.dart';
import '../../ui/settings/models/language.dart';
import '../state_key.dart';

abstract final class SettingsKeys {
  static final themeMode = StateKey.forEnum('settings.themeMode', ThemeMode.values, defaultValue: ThemeMode.system);
  static final showStatusBar = StateKey.boolean('settings.showStatusBar', defaultValue: true);
  static final showActivity = StateKey.boolean('settings.showActivity', defaultValue: true);
  static final persistLayout = StateKey.boolean('settings.persistLayout', defaultValue: true);
  static final language = StateKey.forKeyedEnum('settings.language', AppLanguage.values, defaultValue: AppLanguage.en);

  static final brokers = StateKey.fromJson<List<BrokerEntry>>('settings.brokers', defaultValue: const [], toJson: (list) => list.map((e) => e.toJson()).toList(), fromJson: (raw) => (raw as List).map((e) => BrokerEntry.fromJson(e as Map<String, dynamic>)).toList());

  static final List<StateKey> all = [themeMode, showStatusBar, showActivity, persistLayout, language, brokers];
}
