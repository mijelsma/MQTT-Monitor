import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/mqtt/publish_result.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';

/// Visual variant of a publish feedback indicator.
///
/// The [delivered] variant is the only one that renders a confident green
/// check, and it is reserved for MQTT 5 PUBACK/PUBREC with reason code 0
/// — see the build spec. Every other outcome renders a grey "sent"
/// indicator, a spinner, or a red ✕ so the badge never lies about
/// delivery.
enum PublishFeedbackKind {
  /// Local publish is in flight. Spinner.
  sending(Icons.refresh_rounded, AppColors.neutral400, isSpinner: true),

  /// MQTT 5 PUBACK/PUBREC returned reason code 0. Green check.
  delivered(Icons.check_circle_rounded, AppColors.success500),

  /// Publish was handed to the broker but the protocol cannot confirm
  /// delivery: QoS 0 (any protocol) or any MQTT 3.1.1 outcome. Grey check.
  acknowledged(Icons.check_rounded, AppColors.neutral400),

  /// Protocol reported a failure (MQTT 5 reason code >= 0x80 or local
  /// publish error). Red ✕ with the parsed reason.
  failed(Icons.cancel_rounded, AppColors.error500),

  /// The publish was accepted but no ack arrived within the timeout.
  timedOut(Icons.schedule_rounded, AppColors.warning500),

  /// Pre-flight: the client is not connected to a broker.
  offline(Icons.cloud_off_rounded, AppColors.warning500),

  /// Pre-flight: no topic entered.
  emptyTopic(Icons.warning_rounded, AppColors.warning500),

  /// Pre-flight: the JSON payload did not parse.
  invalidJson(Icons.warning_rounded, AppColors.error400);

  const PublishFeedbackKind(this.icon, this.color, {this.isSpinner = false});

  /// The static icon to render. Ignored when [isSpinner] is true; the
  /// renderer swaps in an indeterminate [CircularProgressIndicator] of
  /// the same color.
  final IconData icon;
  final Color color;
  final bool isSpinner;

  /// True if this feedback kind represents the protocol genuinely
  /// confirming delivery.
  bool get isConfirmed => this == delivered;
}

/// A small icon + label badge used for transient publish feedback.
///
/// When [detail] is supplied it is rendered as a second line under the
/// label, used to show the parsed broker reason for failures.
class FeedbackBadge extends StatelessWidget {
  const FeedbackBadge({super.key, required this.kind, required this.label, this.detail});

  final PublishFeedbackKind kind;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final iconColor = kind.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: kind.isSpinner
              ? CircularProgressIndicator(strokeWidth: 1.6, valueColor: AlwaysStoppedAnimation<Color>(iconColor))
              : Icon(kind.icon, size: 11, color: iconColor),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kind.color),
        ),
        if (detail != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '— ${detail!}',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: kind.color.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Wraps [PublishResult] into the [PublishFeedbackKind] + label + detail
/// that the UI renders. Centralized so the publish panel and shortcut
/// panel stay in sync.
({PublishFeedbackKind kind, String label, String? detail}) feedbackForResult(
  BuildContext context,
  PublishResult result,
) {
  final s = S.of(context);
  switch (result.kind) {
    case PublishResultKind.delivered:
      return (kind: PublishFeedbackKind.delivered, label: s.publishDelivered, detail: result.reasonString);
    case PublishResultKind.failed:
      return (kind: PublishFeedbackKind.failed, label: s.publishFailed, detail: result.reason);
    case PublishResultKind.noConfirmation:
      return (kind: PublishFeedbackKind.acknowledged, label: s.publishAcknowledged, detail: result.reason);
    case PublishResultKind.timedOut:
      return (kind: PublishFeedbackKind.timedOut, label: s.publishTimedOut, detail: result.reason);
  }
}

/// Mixin that provides an auto-dismissing feedback mechanism.
///
/// Call [showFeedback] with a feedback kind; after 4 seconds the
/// [feedback] value is cleared automatically. Override [onFeedbackChanged]
/// if you need extra behaviour when feedback updates.
mixin FeedbackMixin<T extends StatefulWidget> on State<T> {
  PublishFeedbackKind? _feedback;
  String? _feedbackDetail;
  Timer? _feedbackTimer;

  PublishFeedbackKind? get feedback => _feedback;
  String? get feedbackDetail => _feedbackDetail;

  void showFeedback(PublishFeedbackKind kind, {String? detail, Duration? autoDismiss}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedback = kind;
      _feedbackDetail = detail;
    });
    final duration = autoDismiss ?? const Duration(seconds: 4);
    _feedbackTimer = Timer(duration, () {
      if (mounted) setState(_clearFeedback);
    });
  }

  void clearFeedback() {
    _feedbackTimer?.cancel();
    if (mounted) setState(_clearFeedback);
  }

  void _clearFeedback() {
    _feedback = null;
    _feedbackDetail = null;
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }
}
