/// Defines and validates application-wide subscription history limits.
abstract final class HistoryPolicyRules {
  static const int minimumRetention = 1;
  static const int minimumMaximumRetention = 50;
  static const int maximumMaximumRetention = 1000;
  static const int maximumRetentionStep = 50;
  static const int defaultRetention = 10;
  static const int defaultMaximumRetention = 50;
  static const bool defaultEnabled = true;

  /// Returns whether [retention] is valid for a subscription under [maximum].
  static bool isValidRetention(int retention, {required int maximum}) {
    return retention >= minimumRetention && retention <= maximum;
  }

  /// Returns whether [maximum] is a supported global history maximum.
  static bool isValidMaximum(int maximum) {
    return maximum >= minimumMaximumRetention &&
        maximum <= maximumMaximumRetention;
  }

  /// Validates a subscription retention value against [maximum].
  static void validateRetention(int retention, {required int maximum}) {
    if (!isValidRetention(retention, maximum: maximum)) {
      throw RangeError.range(retention, minimumRetention, maximum, 'retention');
    }
  }

  /// Validates an application-wide history maximum.
  static void validateMaximum(int maximum) {
    if (!isValidMaximum(maximum)) {
      throw RangeError.range(
        maximum,
        minimumMaximumRetention,
        maximumMaximumRetention,
        'maximum',
      );
    }
  }
}
