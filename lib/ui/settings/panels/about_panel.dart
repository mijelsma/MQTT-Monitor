import 'package:flutter/material.dart';
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

    return UiPanelScaffold(
      title: 'About',
      children: [
        appBranding,

        // Info rows
        UiSection(
          label: 'Details',
          children: [
            const UiInfoRow(label: 'Commit Hash', value: 'a1b2c3d'),
            const UiInfoRow(label: 'License', value: 'MIT'),
            const UiInfoRow(label: 'Author', value: 'Michel Jelsma'),
          ],
        ),

        // Links
        UiSection(
          label: 'Resources',
          children: [
            UiLinkRow(label: 'Source Code', icon: Icons.code_rounded, accent: accent, onTap: () {}),
            UiLinkRow(label: 'Changelog', icon: Icons.history_rounded, accent: accent, onTap: () {}),
            UiLinkRow(label: 'Report an Issue', icon: Icons.bug_report_outlined, accent: AppColors.error500, onTap: () {}),
            UiLinkRow(label: 'Support the Project', icon: Icons.favorite_border_rounded, accent: accent, onTap: () {}),
          ],
        ),
      ],
    );
  }
}
