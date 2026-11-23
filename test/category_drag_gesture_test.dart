import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopped/features/settings/swipe_actions.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('phones and tablets require a long-press before category drag', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(categoryMoveRequiresLongPress, isTrue);
    expect(swipeActionsUseDesktop, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(categoryMoveRequiresLongPress, isTrue);
    expect(swipeActionsUseDesktop, isFalse);
  });

  test('desktop starts category drag without a long-press', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(categoryMoveRequiresLongPress, isFalse);
    expect(swipeActionsUseDesktop, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(categoryMoveRequiresLongPress, isFalse);
    expect(swipeActionsUseDesktop, isTrue);
  });
}
