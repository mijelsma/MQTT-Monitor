import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

const githubApiVersion = '2026-03-10';

/// A published GitHub Release selected as an update candidate.
class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.prerelease,
    required this.draft,
    required this.publishedAt,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      htmlUrl: Uri.parse(json['html_url'] as String? ?? ''),
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      assets: (json['assets'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GitHubReleaseAsset.fromJson)
          .toList(growable: false),
    );
  }

  final String tagName;
  final String name;
  final String body;
  final Uri htmlUrl;
  final bool prerelease;
  final bool draft;
  final DateTime? publishedAt;
  final List<GitHubReleaseAsset> assets;

  String get versionLabel =>
      tagName.startsWith('v') ? tagName.substring(1) : tagName;

  GitHubReleaseAsset? assetNamed(String name) {
    for (final asset in assets) {
      if (asset.name == name && asset.state == 'uploaded') return asset;
    }
    return null;
  }
}

class GitHubReleaseAsset {
  const GitHubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.state,
    required this.size,
    required this.digest,
  });

  factory GitHubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GitHubReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: Uri.parse(json['browser_download_url'] as String? ?? ''),
      state: json['state'] as String? ?? '',
      size: json['size'] as int? ?? -1,
      digest: json['digest'] as String?,
    );
  }

  final String name;
  final Uri downloadUrl;
  final String state;
  final int size;
  final String? digest;
}

class GitHubReleaseSelection {
  const GitHubReleaseSelection({
    required this.release,
    required this.version,
    required this.channel,
    required this.archiveUrl,
  });

  final GitHubRelease release;
  final Version version;
  final String channel;
  final Uri archiveUrl;
}

/// Selects update releases from GitHub while leaving download and installation
/// to `desktop_updater`.
abstract interface class AppUpdateReleaseSource {
  Future<GitHubReleaseSelection?> findLatest({
    required bool includePrereleases,
  });

  void close();
}

/// Loads and selects update candidates from the GitHub Releases API.
class GitHubReleaseSource implements AppUpdateReleaseSource {
  GitHubReleaseSource({required this.releasesUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const stableChannel = 'stable';
  static const betaChannel = 'beta';
  static const archiveAssetName = 'app-archive.json';

  final Uri releasesUrl;
  final http.Client _client;
  final bool _ownsClient;

  String? _etag;
  List<GitHubRelease>? _cachedReleases;

  @override
  Future<GitHubReleaseSelection?> findLatest({
    required bool includePrereleases,
  }) async {
    final releases = await _fetchReleases();
    final candidates = <({GitHubRelease release, Version version})>[];

    for (final release in releases) {
      if (release.draft) continue;
      final version = _parseVersion(release.tagName);
      if (version == null) continue;
      final isPrerelease = release.prerelease || version.isPreRelease;
      if (!includePrereleases && isPrerelease) continue;
      if (release.assetNamed(archiveAssetName) == null) continue;
      candidates.add((release: release, version: version));
    }

    if (candidates.isEmpty) return null;
    candidates.sort((left, right) {
      final versionComparison = left.version.compareTo(right.version);
      if (versionComparison != 0) return versionComparison;
      final leftDate = left.release.publishedAt;
      final rightDate = right.release.publishedAt;
      if (leftDate == null || rightDate == null) return 0;
      return leftDate.compareTo(rightDate);
    });

    final selected = candidates.last;
    final isPrerelease =
        selected.release.prerelease || selected.version.isPreRelease;
    return GitHubReleaseSelection(
      release: selected.release,
      version: selected.version,
      channel: isPrerelease ? betaChannel : stableChannel,
      archiveUrl: selected.release.assetNamed(archiveAssetName)!.downloadUrl,
    );
  }

  Future<List<GitHubRelease>> _fetchReleases() async {
    final request = http.Request('GET', _withPageSize(releasesUrl));
    request.headers.addAll({
      HttpHeaders.acceptHeader: 'application/vnd.github+json',
      'X-GitHub-Api-Version': githubApiVersion,
    });
    final etag = _etag;
    if (etag != null) request.headers[HttpHeaders.ifNoneMatchHeader] = etag;
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == HttpStatus.notModified &&
        _cachedReleases != null) {
      return _cachedReleases!;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'GitHub Releases request failed: HTTP ${response.statusCode}',
        uri: releasesUrl,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('GitHub Releases response must be a list.');
    }
    final releases = decoded
        .whereType<Map<String, dynamic>>()
        .map(GitHubRelease.fromJson)
        .toList(growable: false);
    _etag = response.headers[HttpHeaders.etagHeader];
    _cachedReleases = releases;
    return releases;
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}

Uri _withPageSize(Uri url) {
  return url.replace(
    queryParameters: {...url.queryParameters, 'per_page': '100'},
  );
}

Version? _parseVersion(String tagName) {
  final value = tagName.startsWith('v') ? tagName.substring(1) : tagName;
  try {
    return Version.parse(value);
  } on FormatException {
    return null;
  }
}
