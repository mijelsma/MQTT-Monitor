import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/keys/app_keys.dart';
import '../../../generated/l10n.dart';
import '../../../models/publish_shortcut.dart';
import '../../../shared/widgets/feedback_badge.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../dashboard/widgets/variable_bar.dart';
import '../../settings/settings_screen.dart';
import '../../settings/settings_section.dart';
import '../monitor_viewmodel.dart';

/// Panel listing publish shortcuts relevant to the active broker.
///
/// Each shortcut can be executed with a single tap, sending the
/// pre-configured message to the topic.
class ShortcutsPanel extends StatelessWidget {
  const ShortcutsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<MonitorViewModel>();
    final shortcuts = vm.availableShortcuts;

    if (shortcuts.isEmpty) return const _EmptyState();

    return Container(
      color: tokens.bg,
      child: Column(
        children: [
          VariableBar(variables: vm.environmentVariables, values: vm.variableValues, onChanged: vm.setVariableValue),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              itemCount: shortcuts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) => _ShortcutCard(shortcut: shortcuts[index]),
            ),
          ),
          _SettingsLink(onTap: () => _openSettings(context)),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    context.read<AppStateManager>().write(AppKeys.activeSettingsSection, SettingsSection.shortcuts);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}

class _ShortcutCard extends StatefulWidget {
  const _ShortcutCard({required this.shortcut});

  final PublishShortcut shortcut;

  @override
  State<_ShortcutCard> createState() => _ShortcutCardState();
}

class _ShortcutCardState extends State<_ShortcutCard> with FeedbackMixin<_ShortcutCard> {
  bool _hovering = false;

  Future<void> _execute() async {
    final vm = context.read<MonitorViewModel>();

    if (!vm.isConnected) {
      showFeedback(PublishFeedbackKind.offline);
      return;
    }

    final resolvedTopic = vm.resolveShortcutTopic(widget.shortcut.topic);
    final shortcut = widget.shortcut;

    // Optimistic "sending" state — never a checkmark before the broker
    // has had a chance to confirm.
    showFeedback(PublishFeedbackKind.sending, autoDismiss: const Duration(minutes: 1));

    final future = vm.publish(resolvedTopic, shortcut.payload, qos: shortcut.qos, retain: shortcut.retain);
    if (future == null) {
      showFeedback(PublishFeedbackKind.failed, detail: 'Client not connected.');
      return;
    }
    final result = await future;
    if (!mounted) return;
    final info = feedbackForResult(context, result);
    showFeedback(
      info.kind,
      detail: info.detail,
      autoDismiss: result.isUnconfirmed ? const Duration(minutes: 1) : const Duration(seconds: 4),
    );
  }

  Widget _feedbackLabel(BuildContext context) {
    final s = S.of(context);
    final label = switch (feedback!) {
      PublishFeedbackKind.sending => s.publishSending,
      PublishFeedbackKind.delivered => s.publishDelivered,
      PublishFeedbackKind.acknowledged => s.publishAcknowledged,
      PublishFeedbackKind.failed => s.publishFailed,
      PublishFeedbackKind.timedOut => s.publishTimedOut,
      PublishFeedbackKind.offline => s.publishOffline,
      PublishFeedbackKind.emptyTopic => s.publishNoTopic,
      PublishFeedbackKind.invalidJson => s.publishBadJson,
    };
    return FeedbackBadge(kind: feedback!, label: label, detail: feedbackDetail);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final sc = widget.shortcut;
    final color = sc.displayColor;
    final hasFeedback = feedback != null;
    final resolvedTopic = context.watch<MonitorViewModel>().resolveShortcutTopic(sc.topic);
    final topicHasVariables = resolvedTopic != sc.topic;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _execute,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovering ? tokens.elevated : tokens.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hovering ? color.withValues(alpha: 0.25) : tokens.border, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                // Rounded colored accent bar
                Container(
                  width: 3.5,
                  height: 28,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),

                // Name + topic
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sc.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        resolvedTopic,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: topicHasVariables ? tokens.primary.withValues(alpha: 0.75) : tokens.muted, fontFamily: 'SF Mono, Menlo, monospace', letterSpacing: -0.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Trailing: feedback or indicators
                if (hasFeedback)
                  _feedbackLabel(context)
                else ...[
                  if (sc.retain)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.push_pin_rounded, size: 10, color: AppColors.warning500.withValues(alpha: 0.55)),
                    ),
                  QosChip(qos: sc.qos, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  void _openSettings(BuildContext context) {
    context.read<AppStateManager>().write(AppKeys.activeSettingsSection, SettingsSection.shortcuts);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: UiEmptyState.compact(icon: Icons.bolt_rounded, title: S.of(context).sidebarShortcutsEmpty, iconColor: AppColors.warning500.withValues(alpha: 0.5), iconBackgroundColor: AppColors.warning500.withValues(alpha: 0.06)),
        ),
        _SettingsLink(onTap: () => _openSettings(context)),
      ],
    );
  }
}

class _SettingsLink extends StatefulWidget {
  const _SettingsLink({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SettingsLink> createState() => _SettingsLinkState();
}

class _SettingsLinkState extends State<_SettingsLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: tokens.border, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, size: 12, color: _hovering ? tokens.primary : tokens.muted),
              const SizedBox(width: 5),
              Text(
                S.of(context).sidebarShortcutsManage,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: _hovering ? tokens.primary : tokens.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
