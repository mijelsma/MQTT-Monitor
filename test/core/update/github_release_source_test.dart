import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mqtt_monitor/core/update/github_release_source.dart';

void main() {
  final releasesUrl = Uri.parse(
    'https://api.github.com/repos/mijelsma/MQTT-Monitor/releases',
  );

  test('stable selection ignores semantic and flagged prereleases', () async {
    final source = _source(releasesUrl, [
      _release('v1.2.0-beta.1'),
      _release('v1.1.0'),
      _release('v1.3.0', prerelease: true),
    ]);
    addTearDown(source.close);

    final selection = await source.findLatest(includePrereleases: false);

    expect(selection?.release.tagName, 'v1.1.0');
    expect(selection?.channel, GitHubReleaseSource.stableChannel);
  });

  test(
    'beta tracking selects the greatest stable or prerelease version',
    () async {
      final source = _source(releasesUrl, [
        _release('v1.2.0'),
        _release('v1.3.0-beta.2'),
      ]);
      addTearDown(source.close);

      final beta = await source.findLatest(includePrereleases: true);

      expect(beta?.release.tagName, 'v1.3.0-beta.2');
      expect(beta?.channel, GitHubReleaseSource.betaChannel);
    },
  );

  test('beta tracking graduates to a newer stable release', () async {
    final source = _source(releasesUrl, [
      _release('v1.3.0-beta.4'),
      _release('v1.3.0'),
    ]);
    addTearDown(source.close);

    final beta = await source.findLatest(includePrereleases: true);

    expect(beta?.release.tagName, 'v1.3.0');
    expect(beta?.channel, GitHubReleaseSource.stableChannel);
  });

  test('supports calendar-version tags with leading zeroes', () async {
    final source = _source(releasesUrl, [
      _release('2025.09.28'),
      _release('2025.10.06'),
    ]);
    addTearDown(source.close);

    final selection = await source.findLatest(includePrereleases: false);

    expect(selection?.release.tagName, '2025.10.06');
  });

  test('ignores drafts, malformed tags, and incomplete releases', () async {
    final source = _source(releasesUrl, [
      _release('v9.0.0', draft: true),
      _release('nightly'),
      _release('v2.0.0', includeArchive: false),
      _release('v1.0.0'),
    ]);
    addTearDown(source.close);

    final selection = await source.findLatest(includePrereleases: true);

    expect(selection?.release.tagName, 'v1.0.0');
    expect(
      selection?.archiveUrl.toString(),
      'https://github.com/example/app/releases/download/v1.0.0/app-archive.json',
    );
  });

  test('reuses the cached response after an ETag 304', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests += 1;
      expect(request.url.queryParameters['per_page'], '100');
      if (requests == 1) {
        return http.Response(
          jsonEncode([_release('v1.0.0')]),
          200,
          headers: {'etag': '"release-list"'},
        );
      }
      expect(request.headers['if-none-match'], '"release-list"');
      return http.Response('', 304);
    });
    final source = GitHubReleaseSource(
      releasesUrl: releasesUrl,
      client: client,
    );
    addTearDown(source.close);

    final first = await source.findLatest(includePrereleases: false);
    final second = await source.findLatest(includePrereleases: false);

    expect(first?.release.tagName, 'v1.0.0');
    expect(second?.release.tagName, 'v1.0.0');
    expect(requests, 2);
  });
}

GitHubReleaseSource _source(Uri url, List<Map<String, Object?>> releases) {
  return GitHubReleaseSource(
    releasesUrl: url,
    client: MockClient((request) async {
      expect(request.url.queryParameters['per_page'], '100');
      expect(request.headers['accept'], 'application/vnd.github+json');
      expect(request.headers['x-github-api-version'], githubApiVersion);
      return http.Response(jsonEncode(releases), 200);
    }),
  );
}

Map<String, Object?> _release(
  String tag, {
  bool prerelease = false,
  bool draft = false,
  bool includeArchive = true,
}) {
  return {
    'tag_name': tag,
    'name': 'Release $tag',
    'body': "## What's changed",
    'html_url': 'https://github.com/example/app/releases/tag/$tag',
    'prerelease': prerelease,
    'draft': draft,
    'published_at': '2026-08-11T10:00:00Z',
    'assets': [
      if (includeArchive)
        {
          'name': 'app-archive.json',
          'browser_download_url':
              'https://github.com/example/app/releases/download/$tag/app-archive.json',
          'state': 'uploaded',
          'size': 200,
          'digest':
              'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        },
    ],
  };
}
