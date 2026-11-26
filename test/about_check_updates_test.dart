import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shopped/features/settings/about_section.dart';
import 'package:shopped/services/app_update.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends UrlLauncherPlatform {
  final urls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    return true;
  }
}

void main() {
  late _FakeLauncher launcher;

  setUp(() {
    final previous = UrlLauncherPlatform.instance;
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previous);
    PackageInfo.setMockInitialValues(
      appName: 'Shopped',
      packageName: 'shopped',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  Future<void> pumpAbout(
    WidgetTester tester, {
    required Future<AppUpdateCheck> Function({required String currentVersion})
    checker,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AboutSection(updateChecker: checker),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Check for updates shows up to date', (tester) async {
    await pumpAbout(
      tester,
      checker: ({required currentVersion}) async =>
          AppUpdateUpToDate(currentVersion: currentVersion),
    );
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Up to date'), findsOneWidget);
    expect(
      find.text("You're on the latest version (1.2.3)."),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Check for updates offers Download for a newer release', (
    tester,
  ) async {
    const download = 'https://example.test/Shopped-Setup-1.2.4.exe';
    await pumpAbout(
      tester,
      checker: ({required currentVersion}) async => AppUpdateAvailable(
        currentVersion: currentVersion,
        latestVersion: '1.2.4',
        downloadUrl: Uri.parse(download),
      ),
    );
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);
    expect(
      find.text('Version 1.2.4 is available (you have 1.2.3).'),
      findsOneWidget,
    );
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(launcher.urls, [download]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Check for updates shows a failure notice', (tester) async {
    await pumpAbout(
      tester,
      checker: ({required currentVersion}) async => const AppUpdateFailed(
        message: 'Network is down.',
      ),
    );
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't check for updates"), findsOneWidget);
    expect(find.text('Network is down.'), findsOneWidget);
  });

  testWidgets('Check for updates ignores a second tap while busy', (
    tester,
  ) async {
    final gate = Completer<AppUpdateCheck>();
    var calls = 0;
    await pumpAbout(
      tester,
      checker: ({required currentVersion}) {
        calls++;
        return gate.future;
      },
    );
    await tester.tap(find.text('Check for updates'));
    await tester.pump();
    expect(find.text('Checking for updates…'), findsOneWidget);
    await tester.tap(find.text('Checking for updates…'));
    await tester.pump();
    expect(calls, 1);
    gate.complete(const AppUpdateUpToDate(currentVersion: '1.2.3'));
    await tester.pumpAndSettle();
    expect(find.text('Up to date'), findsOneWidget);
  });
}
