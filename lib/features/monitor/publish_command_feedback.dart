import 'package:flutter/widgets.dart';

import '../../core/publishing/publish_command_failure.dart';
import '../../generated/l10n.dart';
import '../../shared/widgets/feedback_badge.dart';

/// Maps publish-domain failures to localized monitor feedback.
({PublishFeedbackKind kind, String? detail}) feedbackForCommandFailure(BuildContext context, PublishCommandFailure failure, String? detail) {
  final strings = S.of(context);
  return switch (failure) {
    PublishCommandFailure.emptyTopic => (kind: PublishFeedbackKind.emptyTopic, detail: null),
    PublishCommandFailure.invalidJson => (kind: PublishFeedbackKind.invalidJson, detail: null),
    PublishCommandFailure.offline => (kind: PublishFeedbackKind.offline, detail: null),
    PublishCommandFailure.invalidTopic => (kind: PublishFeedbackKind.failed, detail: strings.publishInvalidTopic),
    PublishCommandFailure.invalidTemplate => (kind: PublishFeedbackKind.failed, detail: strings.publishInvalidTemplate),
    PublishCommandFailure.missingVariables => (kind: PublishFeedbackKind.failed, detail: detail == null || detail.isEmpty ? strings.publishMissingVariables : '${strings.publishMissingVariables}: $detail'),
    PublishCommandFailure.invalidQos => (kind: PublishFeedbackKind.failed, detail: strings.publishInvalidQos),
  };
}
