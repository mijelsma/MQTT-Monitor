import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/dashboard/dashboard_series_policy.dart';

void main() {
  test('settings slider uses 1 followed by multiples of five through 1000', () {
    expect(DashboardSeriesPolicy.samplesForSettingSlider(0), 1);
    expect(DashboardSeriesPolicy.samplesForSettingSlider(1), 5);
    expect(DashboardSeriesPolicy.samplesForSettingSlider(2), 10);
    expect(DashboardSeriesPolicy.samplesForSettingSlider(200), 1000);
  });

  test('settings values map back to their exact slider stops', () {
    expect(DashboardSeriesPolicy.settingSliderPosition(1), 0);
    expect(DashboardSeriesPolicy.settingSliderPosition(5), 1);
    expect(DashboardSeriesPolicy.settingSliderPosition(10), 2);
    expect(DashboardSeriesPolicy.settingSliderPosition(1000), 200);
  });

  test('settings normalization snaps to the nearest permitted value', () {
    expect(DashboardSeriesPolicy.normalizeSetting(0), 1);
    expect(DashboardSeriesPolicy.normalizeSetting(1), 1);
    expect(DashboardSeriesPolicy.normalizeSetting(2), 5);
    expect(DashboardSeriesPolicy.normalizeSetting(7), 5);
    expect(DashboardSeriesPolicy.normalizeSetting(8), 10);
    expect(DashboardSeriesPolicy.normalizeSetting(1001), 1000);
  });
}
