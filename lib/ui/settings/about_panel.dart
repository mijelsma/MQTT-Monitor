import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import 'widgets/info_row.dart';
import 'widgets/link_row.dart';

class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = context.tokens.surface;
    final separatorColor = context.tokens.border;
    final accent = isDark ? AppColors.primary400 : AppColors.primary500;
    final secondary = context.tokens.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('About', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),

          // App icon + summary
          Center(
            child: Column(
              children: [

                // Placeholder for app icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.aboutGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.aboutGradient.first.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.broadcast_on_home_rounded, size: 38, color: Colors.white),
                ),

                // Spacer
                const SizedBox(height: 16),
                
                // App name + version
                Text('MQTT Monitor',style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),

                // Spacer
                const SizedBox(height: 4),

                // Version info
                Text('Version 1.0.0  ·  Build 1', style: TextStyle(fontSize: 13, color: secondary)),
              ],
            ),
          ),
         
          // Spacer
          const SizedBox(height: 28),

          // Info rows
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: separatorColor, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoRow(label: 'Commit Hash', value: 'a1b2c3d', isLast: false, separatorColor: separatorColor),
                InfoRow(label: 'License', value: 'MIT', isLast: false, separatorColor: separatorColor),
                InfoRow(label: 'Author', value: 'Michel Jelsma', isLast: true, separatorColor: separatorColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Links ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: separatorColor, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinkRow(
                  label: 'Source Code',
                  icon: Icons.code_rounded,
                  accent: accent,
                  isLast: false,
                  separatorColor: separatorColor,
                  onTap: () {},
                ),
                LinkRow(
                  label: 'Changelog',
                  icon: Icons.history_rounded,
                  accent: accent,
                  isLast: false,
                  separatorColor: separatorColor,
                  onTap: () {},
                ),
                LinkRow(
                  label: 'Report an Issue',
                  icon: Icons.bug_report_outlined,
                  accent: AppColors.error500,
                  isLast: false,
                  separatorColor: separatorColor,
                  onTap: () {},
                ),
                LinkRow(
                  label: 'Support the Project',
                  icon: Icons.favorite_border_rounded,
                  accent: accent,
                  isLast: true,
                  separatorColor: separatorColor,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
