import '../../../models/chart_type.dart';
import '../../../models/interpolation_mode.dart';
import '../../../models/startup_connection.dart';
import '../../history/history_policy_rules.dart';
import '../../dashboard/dashboard_series_policy.dart';
import '../state_key.dart';

/// Defines the keys used in the app state for managing settings and preferences.
abstract final class SettingsKeys {
  static final rateIntervalMs = StateKey.integer('settings.rateIntervalMs', defaultValue: 1000);

  // Updates
  static final trackBetaReleases = StateKey.boolean('settings.trackBetaReleases');

  // Connection
  static final startupConnection = StateKey.forEnum('settings.startupConnection', StartupConnection.values, defaultValue: StartupConnection.lastStatus);

  // Dashboard defaults
  static final defaultDotSize = StateKey.decimal('settings.defaultDotSize', defaultValue: 4.0);
  static final defaultCardColor = StateKey.integer('settings.defaultCardColor', defaultValue: 0xFF8B5CF6);
  static final defaultChartType = StateKey.forEnum('settings.defaultChartType', ChartType.values, defaultValue: ChartType.line);
  static final defaultInterpolation = StateKey.forEnum('settings.defaultInterpolation', InterpolationMode.values, defaultValue: InterpolationMode.curved);
  static final defaultMaxSamples = StateKey.integer('settings.defaultMaxSamples', defaultValue: DashboardSeriesPolicy.defaultSamples);

  // Subscription history
  static final newSubscriptionHistoryEnabled = StateKey.boolean('settings.newSubscriptionHistoryEnabled', defaultValue: HistoryPolicyRules.defaultEnabled);
  static final newSubscriptionHistoryRetention = StateKey.integer('settings.newSubscriptionHistoryRetention', defaultValue: HistoryPolicyRules.defaultRetention);
  static final maximumHistoryRetention = StateKey.integer('settings.maximumHistoryRetention', defaultValue: HistoryPolicyRules.defaultMaximumRetention);
  static final messageRateSampleSize = StateKey.integer('settings.messageRateSampleSize', defaultValue: 10);

  static final List<StateKey> all = [trackBetaReleases, rateIntervalMs, startupConnection, defaultDotSize, defaultCardColor, defaultChartType, defaultInterpolation, defaultMaxSamples, newSubscriptionHistoryEnabled, newSubscriptionHistoryRetention, maximumHistoryRetention, messageRateSampleSize];
}
