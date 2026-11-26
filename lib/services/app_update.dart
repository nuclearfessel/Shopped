import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GitHub Releases endpoint for the latest Shopped tag and assets.
const shoppedLatestReleaseUrl =
    'https://api.github.com/repos/nuclearfessel/Shopped/releases/latest';

/// Product download section when no platform asset matches.
const shoppedDownloadPageUrl =
    'https://nuclearfessel.github.io/Shopped/#download';

/// Result of a manual "Check for updates" against GitHub Releases.
sealed class AppUpdateCheck {
  const AppUpdateCheck();
}

/// Installed version is the same as, or newer than, the latest release.
class AppUpdateUpToDate extends AppUpdateCheck {
  const AppUpdateUpToDate({required this.currentVersion});

  final String currentVersion;
}

/// A newer release is available; [downloadUrl] may be the platform package or
/// the product download page.
class AppUpdateAvailable extends AppUpdateCheck {
  const AppUpdateAvailable({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final Uri downloadUrl;
}

/// Network or payload failure while checking.
class AppUpdateFailed extends AppUpdateCheck {
  const AppUpdateFailed({required this.message});

  final String message;
}

/// Strips a leading `v` and any `+build` / `-pre` suffix; keeps major.minor.patch.
String normalizeAppVersion(String raw) {
  var s = raw.trim();
  if (s.startsWith('v') || s.startsWith('V')) {
    s = s.substring(1);
  }
  final plus = s.indexOf('+');
  if (plus >= 0) s = s.substring(0, plus);
  final dash = s.indexOf('-');
  if (dash >= 0) s = s.substring(0, dash);
  return s.trim();
}

/// Compares two `major.minor.patch` strings. Missing parts count as 0.
/// Negative when [a] < [b], zero when equal, positive when [a] > [b].
int compareAppVersions(String a, String b) {
  final pa = _parts(normalizeAppVersion(a));
  final pb = _parts(normalizeAppVersion(b));
  for (var i = 0; i < 3; i++) {
    final d = pa[i].compareTo(pb[i]);
    if (d != 0) return d;
  }
  return 0;
}

List<int> _parts(String version) {
  final bits = version.split('.');
  return [
    for (var i = 0; i < 3; i++)
      i < bits.length ? (int.tryParse(bits[i]) ?? 0) : 0,
  ];
}

/// Picks the release asset download for [platform], or the site download page.
Uri downloadUriForPlatform({
  required String version,
  required List<({String name, String url})> assets,
  TargetPlatform? platform,
}) {
  final v = normalizeAppVersion(version);
  final target = platform ?? defaultTargetPlatform;
  final expected = switch (target) {
    TargetPlatform.windows => 'Shopped-Setup-$v.exe',
    TargetPlatform.android => 'Shopped-$v.apk',
    TargetPlatform.macOS => 'Shopped-$v-macos.zip',
    _ => null,
  };
  if (expected != null) {
    for (final asset in assets) {
      if (asset.name == expected) {
        final uri = Uri.tryParse(asset.url);
        if (uri != null) return uri;
      }
    }
  }
  return Uri.parse(shoppedDownloadPageUrl);
}

/// Fetches the latest GitHub Release and compares it to [currentVersion].
Future<AppUpdateCheck> checkForAppUpdate({
  required String currentVersion,
  http.Client? client,
  TargetPlatform? platform,
  Uri? latestReleaseUri,
}) async {
  final current = normalizeAppVersion(currentVersion);
  if (current.isEmpty) {
    return const AppUpdateFailed(
      message:
          "Shopped couldn't read the installed version, so it can't check "
          'for updates right now.',
    );
  }

  final c = client ?? http.Client();
  try {
    final uri =
        latestReleaseUri ?? Uri.parse(shoppedLatestReleaseUrl);
    final res = await c
        .get(
          uri,
          headers: {
            'Accept': 'application/vnd.github+json',
            'User-Agent':
                'Shopped/1.0 (https://github.com/nuclearfessel/Shopped)',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      return const AppUpdateFailed(
        message:
            "Shopped couldn't reach the update server. "
            'Try again when you have a connection.',
      );
    }
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) {
      return const AppUpdateFailed(
        message:
            "Shopped got an unexpected reply while checking for updates.",
      );
    }
    final tag = body['tag_name'];
    if (tag is! String || normalizeAppVersion(tag).isEmpty) {
      return const AppUpdateFailed(
        message:
            "Shopped couldn't read the latest version from the update server.",
      );
    }
    final latest = normalizeAppVersion(tag);
    final assets = <({String name, String url})>[];
    final rawAssets = body['assets'];
    if (rawAssets is List) {
      for (final item in rawAssets) {
        if (item is! Map) continue;
        final name = item['name'];
        final url = item['browser_download_url'];
        if (name is String && url is String) {
          assets.add((name: name, url: url));
        }
      }
    }

    if (compareAppVersions(current, latest) >= 0) {
      return AppUpdateUpToDate(currentVersion: current);
    }
    return AppUpdateAvailable(
      currentVersion: current,
      latestVersion: latest,
      downloadUrl: downloadUriForPlatform(
        version: latest,
        assets: assets,
        platform: platform,
      ),
    );
  } on Object {
    return const AppUpdateFailed(
      message:
          "Shopped couldn't check for updates. "
          'Try again when you have a connection.',
    );
  } finally {
    if (client == null) c.close();
  }
}
