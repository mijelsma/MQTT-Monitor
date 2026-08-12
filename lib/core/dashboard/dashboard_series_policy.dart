/// Defines the hard bounds for every live dashboard series.
abstract final class DashboardSeriesPolicy {
  static const int minimumSamples = 1;
  static const int defaultSamples = 500;
  static const int maximumSamples = 5000;

  static bool isValid(int value) => value >= minimumSamples && value <= maximumSamples;

  static int normalize(int? value) {
    if (value == null || value < minimumSamples) return defaultSamples;
    return value.clamp(minimumSamples, maximumSamples);
  }

  static void validate(int value) {
    if (!isValid(value)) {
      throw ArgumentError.value(value, 'value', 'must be between $minimumSamples and $maximumSamples');
    }
  }
}
