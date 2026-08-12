/// Defines the hard bounds for every live dashboard series.
abstract final class DashboardSeriesPolicy {
  static const int minimumSamples = 1;
  static const int defaultSamples = 500;
  static const int maximumSamples = 5000;

  /// The default-samples setting exposes 1 as a special first stop, followed
  /// by multiples of five through 1,000.
  static const int settingsMaximumSamples = 1000;
  static const int settingsStep = 5;
  static const int settingsSliderDivisions = settingsMaximumSamples ~/ settingsStep;

  static bool isValid(int value) => value >= minimumSamples && value <= maximumSamples;

  static int normalize(int? value) {
    if (value == null || value < minimumSamples) return defaultSamples;
    return value.clamp(minimumSamples, maximumSamples);
  }

  static int normalizeSetting(int? value) {
    if (value == null) return defaultSamples;
    if (value <= minimumSamples) return minimumSamples;
    final snapped = (value / settingsStep).round() * settingsStep;
    return snapped.clamp(settingsStep, settingsMaximumSamples);
  }

  static double settingSliderPosition(int samples) {
    final normalized = normalizeSetting(samples);
    return normalized == minimumSamples ? 0 : normalized / settingsStep;
  }

  static int samplesForSettingSlider(double position) {
    final stop = position.round().clamp(0, settingsSliderDivisions);
    return stop == 0 ? minimumSamples : stop * settingsStep;
  }

  static void validate(int value) {
    if (!isValid(value)) {
      throw ArgumentError.value(value, 'value', 'must be between $minimumSamples and $maximumSamples');
    }
  }
}
