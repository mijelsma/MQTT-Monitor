import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/update/github_release_source.dart';
import '../../../theme/app_tokens/app_tokens.dart';

Future<void> showGitHubReleaseNotesSheet(BuildContext context, GitHubRelease release) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _GitHubReleaseNotesSheet(release: release),
  );
}

class _GitHubReleaseNotesSheet extends StatelessWidget {
  const _GitHubReleaseNotesSheet({required this.release});

  final GitHubRelease release;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final publishedAt = release.publishedAt;
    final subtitle = publishedAt == null ? release.tagName : '${release.tagName} · ${DateFormat.yMMMd().format(publishedAt.toLocal())}';
    final notes = release.body.trim().isEmpty ? 'No release notes were provided for this version.' : release.body;

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(release.name.trim().isEmpty ? 'What’s new' : release.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary)),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Open on GitHub', onPressed: () => _openUrl(release.htmlUrl), icon: const Icon(Icons.open_in_new_rounded)),
                IconButton(tooltip: 'Close', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Markdown(
              data: notes,
              selectable: true,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              onTapLink: (_, href, _) {
                final uri = href == null ? null : Uri.tryParse(href);
                if (uri != null) _openUrl(uri);
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openUrl(Uri uri) async {
  if (uri.scheme != 'https' && uri.scheme != 'http') return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
