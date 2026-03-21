import 'package:flutter/material.dart';

import '../../../models/broker_entry.dart';
import '../../../models/chart_type.dart';
import '../../../models/interpolation_mode.dart';
import '../../../models/language.dart';
import '../../../models/startup_connection.dart';
import '../state_key.dart';
import '../../../models/environment_variable.dart';

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

  // Environment variables
  static final environmentVariables = StateKey.fromJson<List<EnvironmentVariable>>('settings.environmentVariables', defaultValue: const [], toJson: (list) => list.map((e) => e.toJson()).toList(), fromJson: (raw) => (raw as List).map((e) => EnvironmentVariable.fromJson(e as Map<String, dynamic>)).toList());
  static final environmentVariableValues = StateKey.fromJson<Map<String, String>>('settings.environmentVariableValues', defaultValue: const {}, toJson: (map) => map, fromJson: (raw) => Map<String, String>.from(raw as Map));

  // Connection
  static final startupConnection = StateKey.forEnum('settings.startupConnection', StartupConnection.values, defaultValue: StartupConnection.lastStatus);

  // Dashboard defaults
  static final defaultDotSize = StateKey.decimal('settings.defaultDotSize', defaultValue: 4.0);
  static final defaultCardColor = StateKey.integer('settings.defaultCardColor', defaultValue: 0xFF8B5CF6);
  static final defaultChartType = StateKey.forEnum('settings.defaultChartType', ChartType.values, defaultValue: ChartType.line);
  static final defaultInterpolation = StateKey.forEnum('settings.defaultInterpolation', InterpolationMode.values, defaultValue: InterpolationMode.curved);
  static final defaultMaxSamples = StateKey.integer('settings.defaultMaxSamples', defaultValue: 0);

  // Language panel
  static final language = StateKey.forEnum('settings.language', AppLanguage.values, defaultValue: AppLanguage.en);

  // History & monitoring
  static final defaultHistorySize = StateKey.integer('settings.defaultHistorySize', defaultValue: 50);
  static final increasedHistorySize = StateKey.integer('settings.increasedHistorySize', defaultValue: 500);
  static final increasedMonitoringTopics = StateKey.fromJson<List<String>>('settings.increasedMonitoringTopics', defaultValue: const [], toJson: (list) => list, fromJson: (raw) => (raw as List).cast<String>());
  static final messageRateSampleSize = StateKey.integer('settings.messageRateSampleSize', defaultValue: 10);

  static final List<StateKey> all = [
    themeMode,
    showStatusBar,
    showActivity,
    pulseRatePps,
    pulseFadeMs,
    persistLayout,
    rateIntervalMs,
    startupConnection,
    defaultDotSize,
    defaultCardColor,
    defaultChartType,
    defaultInterpolation,
    defaultMaxSamples,
    language,
    brokers,
    environmentVariables,
    environmentVariableValues,
    defaultHistorySize,
    increasedHistorySize,
    increasedMonitoringTopics,
    messageRateSampleSize,
  ];
}
