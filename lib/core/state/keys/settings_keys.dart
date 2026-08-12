import 'package:flutter/material.dart';

import '../../../models/chart_type.dart';
import '../../../models/interpolation_mode.dart';
import '../../../models/language.dart';
import '../../../models/sidebar_panel_default.dart';
import '../../../models/startup_connection.dart';
import '../../history/history_policy_rules.dart';
import '../../dashboard/dashboard_series_policy.dart';
import '../state_key.dart';

/// Defines the keys used in the app state for managing settings and preferences.
abstract final class SettingsKeys {
  // UI panel
  static final themeMode = StateKey.forEnum('settings.themeMode', ThemeMode.values, defaultValue: ThemeMode.system);
  static final accentColor = StateKey.integer('settings.accentColor', defaultValue: 0xFF6366F1);
  static final showStatusBar = StateKey.boolean('settings.showStatusBar', defaultValue: true);
  static final rateIntervalMs = StateKey.integer('settings.rateIntervalMs', defaultValue: 1000);
  static final showActivity = StateKey.boolean('settings.showActivity', defaultValue: true);
  static final disableSelectionHighlight = StateKey.boolean('settings.disableSelectionHighlight', defaultValue: false);
  static final pulseRatePps = StateKey.integer('settings.pulseRatePps', defaultValue: 15);
  static final pulseFadeMs = StateKey.integer('settings.pulseFadeMs', defaultValue: 500);
  static final persistLayout = StateKey.boolean('settings.persistLayout', defaultValue: true);
  static final sidebarAnimationsEnabled = StateKey.boolean('settings.sidebarAnimationsEnabled', defaultValue: true);
  static final sidebarAnimationSpeed = StateKey.integer('settings.sidebarAnimationSpeed', defaultValue: 50);

  // Updates
  static final trackBetaReleases = StateKey.boolean('settings.trackBetaReleases');

  // Default sidebar panel states on startup (collapsed / expanded / lastStatus).
  static final defaultSidebarDetail = StateKey.forEnum('settings.defaultSidebarDetail', SidebarPanelDefault.values, defaultValue: SidebarPanelDefault.expanded);
  static final defaultSidebarHistory = StateKey.forEnum('settings.defaultSidebarHistory', SidebarPanelDefault.values, defaultValue: SidebarPanelDefault.collapsed);
  static final defaultSidebarPublish = StateKey.forEnum('settings.defaultSidebarPublish', SidebarPanelDefault.values, defaultValue: SidebarPanelDefault.expanded);
  static final defaultSidebarShortcuts = StateKey.forEnum('settings.defaultSidebarShortcuts', SidebarPanelDefault.values, defaultValue: SidebarPanelDefault.collapsed);

  // Connection
  static final startupConnection = StateKey.forEnum('settings.startupConnection', StartupConnection.values, defaultValue: StartupConnection.lastStatus);

  // Dashboard defaults
  static final defaultDotSize = StateKey.decimal('settings.defaultDotSize', defaultValue: 4.0);
  static final defaultCardColor = StateKey.integer('settings.defaultCardColor', defaultValue: 0xFF8B5CF6);
  static final defaultChartType = StateKey.forEnum('settings.defaultChartType', ChartType.values, defaultValue: ChartType.line);
  static final defaultInterpolation = StateKey.forEnum('settings.defaultInterpolation', InterpolationMode.values, defaultValue: InterpolationMode.curved);
  static final defaultMaxSamples = StateKey.integer('settings.defaultMaxSamples', defaultValue: DashboardSeriesPolicy.defaultSamples);

  // Language panel
  static final language = StateKey.forEnum('settings.language', AppLanguage.values, defaultValue: AppLanguage.en);

  // Subscription history
  static final newSubscriptionHistoryEnabled = StateKey.boolean('settings.newSubscriptionHistoryEnabled', defaultValue: HistoryPolicyRules.defaultEnabled);
  static final newSubscriptionHistoryRetention = StateKey.integer('settings.newSubscriptionHistoryRetention', defaultValue: HistoryPolicyRules.defaultRetention);
  static final maximumHistoryRetention = StateKey.integer('settings.maximumHistoryRetention', defaultValue: HistoryPolicyRules.defaultMaximumRetention);
  static final messageRateSampleSize = StateKey.integer('settings.messageRateSampleSize', defaultValue: 10);

  static final List<StateKey> all = [
    themeMode,
    accentColor,
    showStatusBar,
    showActivity,
    disableSelectionHighlight,
    pulseRatePps,
    pulseFadeMs,
    persistLayout,
    sidebarAnimationsEnabled,
    sidebarAnimationSpeed,
    trackBetaReleases,
    defaultSidebarDetail,
    defaultSidebarHistory,
    defaultSidebarPublish,
    defaultSidebarShortcuts,
    rateIntervalMs,
    startupConnection,
    defaultDotSize,
    defaultCardColor,
    defaultChartType,
    defaultInterpolation,
    defaultMaxSamples,
    language,
    newSubscriptionHistoryEnabled,
    newSubscriptionHistoryRetention,
    maximumHistoryRetention,
    messageRateSampleSize,
  ];
}
