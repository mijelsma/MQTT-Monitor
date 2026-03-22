import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The kind of publish feedback to show.
enum PublishFeedbackKind {
  success(Icons.check_circle_rounded, AppColors.success500),
  failed(Icons.error_rounded, AppColors.error500),
  offline(Icons.cloud_off_rounded, AppColors.warning500),
  emptyTopic(Icons.warning_rounded, AppColors.warning500),
  invalidJson(Icons.warning_rounded, AppColors.error400);

  const PublishFeedbackKind(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// A tiny icon + label badge used for transient publish feedback.
///
/// Pair with [FeedbackMixin] to auto-dismiss after a timeout.
class FeedbackBadge extends StatelessWidget {
  const FeedbackBadge({super.key, required this.kind, required this.label});

  final PublishFeedbackKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(kind.icon, size: 11, color: kind.color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kind.color),
        ),
      ],
    );
  }
}

/// Mixin that provides an auto-dismissing feedback mechanism.
///
/// Call [showFeedback] with a feedback kind; after 2 seconds the
/// [feedback] value is cleared automatically. Override [onFeedbackChanged]
/// if you need extra behaviour when feedback updates.
mixin FeedbackMixin<T extends StatefulWidget> on State<T> {
  PublishFeedbackKind? _feedback;
  Timer? _feedbackTimer;

  PublishFeedbackKind? get feedback => _feedback;

  void showFeedback(PublishFeedbackKind kind) {
    _feedbackTimer?.cancel();
    setState(() => _feedback = kind);
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }
}
