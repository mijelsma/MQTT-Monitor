import 'dart:async';

import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/update/services/app_update_service.dart';
import '../../../generated/git_info.dart';
import '../../../generated/l10n.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../../shared/widgets/ui_info_row.dart';
import '../../../shared/widgets/ui_link_row.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../widgets/github_release_notes_sheet.dart';

class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final tokens = context.tokens;
    final accent = tokens.primary;
    final secondary = tokens.textSecondary;
    final updater = context.watch<AppUpdateService>();

    final appBranding = Center(
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png', fit: BoxFit.cover),
            ),
          ),
          const VSpacer(16),
          Text('MQTT Monitor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const VSpacer(4),
          Text('Version ${GitInfo.version}', style: TextStyle(fontSize: 13, color: secondary)),
        ],
      ),
    );

    return UiPanelScaffold(
      title: s.aboutPanelTitle,
      children: [
        appBranding,
        UiSection(
          label: s.aboutPanelSectionDetails,
          children: [
            UiInfoRow(label: s.aboutPanelVersionDetail, value: GitInfo.describe),
            UiInfoRow(label: s.aboutPanelCommitHash, value: GitInfo.commitHash),
            UiInfoRow(label: s.aboutPanelLicense, value: 'AGPL-3.0'),
            UiInfoRow(label: s.aboutPanelAuthor, value: 'Michel Jelsma'),
          ],
        ),
        UiSection(
          label: 'Updates',
          children: [
            UiSwitchRow(label: 'Track beta releases', subtitle: 'Receive pre-release updates. Turn this off to return to stable releases.', value: updater.tracksBetaReleases, onChanged: (value) => unawaited(updater.setTracksBetaReleases(value))),
            _UpdateRow(service: updater),
            if (updater.selectedRelease case final release?) UiLinkRow(label: 'What’s new in ${release.versionLabel}', icon: Icons.new_releases_outlined, accent: accent, onTap: () => showGitHubReleaseNotesSheet(context, release)),
          ],
        ),
        UiSection(
          label: s.aboutPanelSectionResources,
          children: [
            UiLinkRow(label: s.aboutPanelSourceCode, icon: Icons.code_rounded, accent: accent, onTap: () => _openUrl('https://github.com/mijelsma/mqtt-monitor')),
            UiLinkRow(label: s.aboutPanelChangelog, icon: Icons.history_rounded, accent: accent, onTap: () => _openUrl('https://github.com/mijelsma/mqtt-monitor/releases')),
            UiLinkRow(label: s.aboutPanelReportIssue, icon: Icons.bug_report_outlined, accent: tokens.error, onTap: () => _openUrl('https://github.com/mijelsma/mqtt-monitor/issues')),
            UiLinkRow(label: s.aboutPanelSupportProject, icon: Icons.favorite_border_rounded, accent: accent, onTap: () => _openUrl('https://ko-fi.com/micheljelsma')),
          ],
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.service});

  final AppUpdateService service;

  @override
  Widget build(BuildContext context) {
    final state = service.state;
    final accent = context.tokens.primary;

    if (!service.isConfigured && state is UpdateIdle) {
      return const _UpdateActionRow(icon: Icons.cloud_off_outlined, title: 'Updates are not configured', subtitle: 'This development build has no update feed');
    }

    return switch (state) {
      UpdateChecking() => const _UpdateActionRow(icon: Icons.sync_rounded, title: 'Checking for updates…', subtitle: 'Contacting the update service', busy: true),
      UpdateAvailable(:final descriptor) => _UpdateActionRow(icon: Icons.system_update_rounded, iconColor: accent, title: 'Version ${descriptor.version} is available', subtitle: 'Download and verify the update before installing it', actionLabel: 'Download', onTap: _download),
      UpdateFreshInstallRequired(:final descriptor) => _UpdateActionRow(icon: Icons.open_in_new_rounded, title: 'Version ${descriptor.version} is available', subtitle: 'This release needs a fresh download', actionLabel: 'View release', onTap: () => _openUrl(service.releasePageUrl.toString())),
      UpdateBlockedBySupportPolicy(:final descriptor) => _UpdateActionRow(icon: Icons.warning_amber_rounded, iconColor: context.tokens.error, title: 'Version ${descriptor.version} is required', subtitle: 'This version is no longer supported', actionLabel: 'View release', onTap: () => _openUrl(service.releasePageUrl.toString())),
      UpdateDownloading(:final receivedBytes, :final totalBytes) => _UpdateActionRow(icon: Icons.downloading_rounded, title: 'Downloading update', subtitle: '${_formatBytes(receivedBytes)} of ${_formatBytes(totalBytes)}', progress: totalBytes == 0 ? null : receivedBytes / totalBytes, busy: true),
      UpdateReadyToInstall() => _UpdateActionRow(icon: Icons.restart_alt_rounded, iconColor: accent, title: 'Update ready to install', subtitle: 'The app will close and restart to finish the update', actionLabel: 'Restart', onTap: _install),
      UpdateInstalling() => const _UpdateActionRow(icon: Icons.restart_alt_rounded, title: 'Installing update…', subtitle: 'MQTT Monitor will restart shortly', busy: true),
      UpdateFailed() => _UpdateActionRow(icon: Icons.error_outline_rounded, iconColor: context.tokens.error, title: 'Could not check for updates', subtitle: 'Check your connection and try again', actionLabel: 'Try again', onTap: () => _check(context)),
      UpdateIdle() => _UpdateActionRow(icon: Icons.system_update_alt_rounded, iconColor: accent, title: 'Check for ${service.channel} updates', subtitle: 'Look for a newer version of MQTT Monitor', actionLabel: 'Check', onTap: () => _check(context)),
    };
  }

  Future<void> _check(BuildContext context) async {
    final result = await service.checkForUpdates();
    if (!context.mounted || result is! ManualUpdateCheckUpToDate) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MQTT Monitor is up to date.')));
  }

  Future<void> _download() async {
    try {
      await service.downloadUpdate();
    } on Object {
      // The controller changes to UpdateFailed, which this custom UI renders.
    }
  }

  Future<void> _install() async {
    try {
      await service.restartApp();
    } on Object {
      // The controller changes to UpdateFailed, which this custom UI renders.
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _UpdateActionRow extends StatelessWidget {
  const _UpdateActionRow({required this.icon, required this.title, required this.subtitle, this.iconColor, this.actionLabel, this.onTap, this.busy = false, this.progress});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onTap;
  final bool busy;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = iconColor ?? tokens.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary)),
                  if (progress != null) ...[const SizedBox(height: 8), LinearProgressIndicator(value: progress, minHeight: 3, borderRadius: BorderRadius.circular(99))],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (busy)
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            else if (actionLabel != null)
              Text(
                actionLabel!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
