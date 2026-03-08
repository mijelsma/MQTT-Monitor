import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../widgets/info_row.dart';
import '../widgets/link_row.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';
import '../../widgets/spacers.dart';

// Divider indent for link rows: 14 (left padding) + 18 (icon) + 10 (gap) = 42
const _kLinkDividerIndent = 42.0;

class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.tokens.primary;
    final secondary = context.tokens.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('About', style: theme.textTheme.headlineSmall),

          // Spacer
          VSpacer(6),

          // App icon + summary
          Center(
            child: Column(
              children: [
                // Placeholder for app icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.aboutGradient),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.aboutGradient.first.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.broadcast_on_home_rounded, size: 38, color: Colors.white),
                ),

                // Spacer
                VSpacer(16),

                // App name + version
                Text('MQTT Monitor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),

                // Spacer
                VSpacer(4),

                // Version info
                Text('Version 1.0.0  ·  Build 1', style: TextStyle(fontSize: 13, color: secondary)),
              ],
            ),
          ),

          VSpacer(28),

          // Info rows
          SettingsGroup(
            children: [
              SettingsRow(
                child: InfoRow(label: 'Commit Hash', value: 'a1b2c3d'),
              ),
              SettingsRow(
                child: InfoRow(label: 'License', value: 'MIT'),
              ),
              SettingsRow(
                isLast: true,
                child: InfoRow(label: 'Author', value: 'Michel Jelsma'),
              ),
            ],
          ),
          VSpacer(20),

          // Links
          SettingsGroup(
            children: [
              SettingsRow(
                dividerIndent: _kLinkDividerIndent,
                child: LinkRow(label: 'Source Code', icon: Icons.code_rounded, accent: accent, onTap: () {}),
              ),
              SettingsRow(
                dividerIndent: _kLinkDividerIndent,
                child: LinkRow(label: 'Changelog', icon: Icons.history_rounded, accent: accent, onTap: () {}),
              ),
              SettingsRow(
                dividerIndent: _kLinkDividerIndent,
                child: LinkRow(label: 'Report an Issue', icon: Icons.bug_report_outlined, accent: AppColors.error500, onTap: () {}),
              ),
              SettingsRow(
                isLast: true,
                child: LinkRow(label: 'Support the Project', icon: Icons.favorite_border_rounded, accent: accent, onTap: () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
