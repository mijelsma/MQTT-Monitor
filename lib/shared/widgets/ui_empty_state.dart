import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'spacers.dart';

/// A reusable empty-state placeholder with an icon, title, and message.
///
/// Use the default constructor for settings-panel style (large icon, no
/// background circle). Use [UiEmptyState.compact] for inline sidebar /
/// panel style (smaller icon inside a tinted circle, scrollable).
class UiEmptyState extends StatelessWidget {
  const UiEmptyState({super.key, required this.icon, required this.title, required this.message}) : iconColor = null, iconBackgroundColor = null, _compact = false;

  /// Compact variant used inside sidebar panels (detail, history, shortcuts).
  ///
  /// Wraps content in a [SingleChildScrollView] and renders the icon inside
  /// a circular tinted background.
  const UiEmptyState.compact({super.key, required this.icon, required this.title, this.message, this.iconColor, this.iconBackgroundColor}) : _compact = true;

  final IconData icon;
  final String title;
  final String? message;

  /// Override the icon color (compact only). Defaults to [AppTokens.muted].
  final Color? iconColor;

  /// Override the circle background color (compact only). Defaults to primary @ 5% alpha.
  final Color? iconBackgroundColor;

  final bool _compact;

  @override
  Widget build(BuildContext context) {
    if (_compact) return _buildCompact(context);
    return _buildDefault(context);
  }

  Widget _buildDefault(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: context.tokens.textTertiary),
            const VSpacer(12),
            Text(title, style: theme.textTheme.bodyMedium),
            if (message != null) ...[const VSpacer(4), Text(message!, style: theme.textTheme.bodySmall)],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final tokens = context.tokens;
    final resolvedIconColor = iconColor ?? tokens.muted;
    final resolvedBgColor = iconBackgroundColor ?? tokens.primary.withValues(alpha: 0.05);

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: resolvedBgColor, shape: BoxShape.circle),
                child: Icon(icon, size: 24, color: resolvedIconColor),
              ),
              const VSpacer(12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: tokens.textTertiary),
              ),
              if (message != null) ...[
                const VSpacer(4),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: tokens.muted, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
