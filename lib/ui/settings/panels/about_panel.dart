import 'package:flutter/material.dart';
import '../../../generated/l10n.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../elements/ui_info_row.dart';
import '../../elements/ui_link_row.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';
import '../../widgets/spacers.dart';

class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.tokens.primary;
    final secondary = context.tokens.textSecondary;

    // App icon + branding — used as the first child of the scaffold.
    final appBranding = Center(
      child: Column(
        children: [
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
          const VSpacer(16),
          Text('MQTT Monitor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const VSpacer(4),
          Text('Version 1.0.0  ·  Build 1', style: TextStyle(fontSize: 13, color: secondary)),
        ],
      ),
    );

    final s = S.of(context);

    return UiPanelScaffold(
      title: s.aboutPanelTitle,
      children: [
        appBranding,

        // Info rows
        UiSection(
          label: s.aboutPanelSectionDetails,
          children: [
            UiInfoRow(label: s.aboutPanelCommitHash, value: 'a1b2c3d'),
            UiInfoRow(label: s.aboutPanelLicense, value: 'MIT'),
            UiInfoRow(label: s.aboutPanelAuthor, value: 'Michel Jelsma'),
          ],
        ),

        // Links
        UiSection(
          label: s.aboutPanelSectionResources,
          children: [
            UiLinkRow(label: s.aboutPanelSourceCode, icon: Icons.code_rounded, accent: accent, onTap: () {}),
            UiLinkRow(label: s.aboutPanelChangelog, icon: Icons.history_rounded, accent: accent, onTap: () {}),
            UiLinkRow(label: s.aboutPanelReportIssue, icon: Icons.bug_report_outlined, accent: AppColors.error500, onTap: () {}),
            UiLinkRow(label: s.aboutPanelSupportProject, icon: Icons.favorite_border_rounded, accent: accent, onTap: () {}),
          ],
        ),
      ],
    );
  }
}
