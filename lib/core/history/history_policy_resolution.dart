/// Describes the effective history behavior for one concrete topic.
class HistoryPolicyResolution {
  const HistoryPolicyResolution._({required this.matchesSubscription, required this.enabled, required this.retention});

  const HistoryPolicyResolution.unmatched() : this._(matchesSubscription: false, enabled: false, retention: 0);

  const HistoryPolicyResolution.disabled() : this._(matchesSubscription: true, enabled: false, retention: 0);

  const HistoryPolicyResolution.enabled(int retention) : this._(matchesSubscription: true, enabled: true, retention: retention);

  final bool matchesSubscription;
  final bool enabled;
  final int retention;
}
