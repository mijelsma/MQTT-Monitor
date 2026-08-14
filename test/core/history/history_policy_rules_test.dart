import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/history/history_policy_rules.dart';

void main() {
  test('subscription retention includes both configured boundaries', () {
    expect(HistoryPolicyRules.isValidRetention(1, maximum: 500), isTrue);
    expect(HistoryPolicyRules.isValidRetention(500, maximum: 500), isTrue);
    expect(HistoryPolicyRules.isValidRetention(0, maximum: 500), isFalse);
    expect(HistoryPolicyRules.isValidRetention(501, maximum: 500), isFalse);
  });

  test('global maximum is constrained from 50 through 1000', () {
    expect(HistoryPolicyRules.isValidMaximum(50), isTrue);
    expect(HistoryPolicyRules.isValidMaximum(1000), isTrue);
    expect(HistoryPolicyRules.isValidMaximum(49), isFalse);
    expect(HistoryPolicyRules.isValidMaximum(1001), isFalse);
    expect(() => HistoryPolicyRules.validateMaximum(49), throwsRangeError);
  });

  test('new history policies default to 10 under a maximum of 50', () {
    expect(HistoryPolicyRules.defaultRetention, 10);
    expect(HistoryPolicyRules.defaultMaximumRetention, 50);
    expect(HistoryPolicyRules.maximumRetentionStep, 50);
  });
}
