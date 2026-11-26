import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopped/services/app_update.dart';

String _releaseJson({
  required String tag,
  List<Map<String, String>> assets = const [],
}) => jsonEncode({
  'tag_name': tag,
  'assets': [
    for (final a in assets)
      {'name': a['name'], 'browser_download_url': a['url']},
  ],
});

void main() {
  test('normalizeAppVersion strips v prefix and build metadata', () {
    expect(normalizeAppVersion('v1.2.3'), '1.2.3');
    expect(normalizeAppVersion('1.2.3+45'), '1.2.3');
    expect(normalizeAppVersion('1.2.3-beta'), '1.2.3');
  });

  test('compareAppVersions orders major.minor.patch', () {
    expect(compareAppVersions('1.2.3', '1.2.3'), 0);
    expect(compareAppVersions('1.2.3', '1.2.4'), lessThan(0));
    expect(compareAppVersions('1.3.0', '1.2.9'), greaterThan(0));
    expect(compareAppVersions('v2.0.0', '1.9.9'), greaterThan(0));
    expect(compareAppVersions('1.2', '1.2.0'), 0);
  });

  test('downloadUriForPlatform picks the matching asset', () {
    final assets = [
      (
        name: 'Shopped-Setup-1.2.1.exe',
        url: 'https://example.test/Setup.exe',
      ),
      (name: 'Shopped-1.2.1.apk', url: 'https://example.test/Shopped.apk'),
      (
        name: 'Shopped-1.2.1-macos.zip',
        url: 'https://example.test/mac.zip',
      ),
    ];
    expect(
      downloadUriForPlatform(
        version: '1.2.1',
        assets: assets,
        platform: TargetPlatform.windows,
      ).toString(),
      'https://example.test/Setup.exe',
    );
    expect(
      downloadUriForPlatform(
        version: '1.2.1',
        assets: assets,
        platform: TargetPlatform.android,
      ).toString(),
      'https://example.test/Shopped.apk',
    );
    expect(
      downloadUriForPlatform(
        version: '1.2.1',
        assets: assets,
        platform: TargetPlatform.macOS,
      ).toString(),
      'https://example.test/mac.zip',
    );
    expect(
      downloadUriForPlatform(
        version: '1.2.1',
        assets: assets,
        platform: TargetPlatform.iOS,
      ).toString(),
      shoppedDownloadPageUrl,
    );
  });

  test('checkForAppUpdate reports up to date', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), shoppedLatestReleaseUrl);
      expect(request.headers['User-Agent'], contains('Shopped'));
      return http.Response(
        _releaseJson(tag: 'v1.2.3'),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final result = await checkForAppUpdate(
      currentVersion: '1.2.3',
      client: client,
      platform: TargetPlatform.windows,
    );
    expect(result, isA<AppUpdateUpToDate>());
    expect((result as AppUpdateUpToDate).currentVersion, '1.2.3');
  });

  test('checkForAppUpdate reports an available Windows download', () async {
    final client = MockClient((request) async {
      return http.Response(
        _releaseJson(
          tag: 'v1.2.4',
          assets: [
            {
              'name': 'Shopped-Setup-1.2.4.exe',
              'url': 'https://example.test/Shopped-Setup-1.2.4.exe',
            },
          ],
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final result = await checkForAppUpdate(
      currentVersion: '1.2.3',
      client: client,
      platform: TargetPlatform.windows,
    );
    expect(result, isA<AppUpdateAvailable>());
    final update = result as AppUpdateAvailable;
    expect(update.latestVersion, '1.2.4');
    expect(update.currentVersion, '1.2.3');
    expect(
      update.downloadUrl.toString(),
      'https://example.test/Shopped-Setup-1.2.4.exe',
    );
  });

  test('checkForAppUpdate fails on non-200', () async {
    final client = MockClient(
      (request) async => http.Response('nope', 503),
    );
    final result = await checkForAppUpdate(
      currentVersion: '1.0.0',
      client: client,
    );
    expect(result, isA<AppUpdateFailed>());
  });

  test('checkForAppUpdate fails on empty installed version', () async {
    final result = await checkForAppUpdate(currentVersion: '   ');
    expect(result, isA<AppUpdateFailed>());
  });
}
