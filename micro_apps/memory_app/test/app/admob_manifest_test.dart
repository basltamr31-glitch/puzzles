import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the AdMob App ID in AndroidManifest.xml.
///
/// This one value is easy to get wrong and expensive when it is:
/// - missing or malformed → the app **crashes on launch** when the ads SDK
///   initializes, before any screen renders;
/// - left as Google's sample ID → the shipped app can never earn anything,
///   and it is a fault nobody notices until after release;
/// - copied from a sibling app → its ad inventory is billed against the
///   wrong app, which is an AdMob policy problem, not just a reporting one.
///
/// Reading the manifest directly is the only way to catch any of them,
/// since none is visible from Dart at runtime.
void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  String appId() {
    final match = RegExp(
      r'APPLICATION_ID"\s*\n?\s*android:value="([^"]+)"',
    ).firstMatch(manifest);
    expect(match, isNotNull, reason: 'could not read the App ID value');
    return match!.group(1)!;
  }

  test('the AdMob App ID meta-data is present', () {
    expect(
      manifest.contains('com.google.android.gms.ads.APPLICATION_ID'),
      isTrue,
      reason: 'without this meta-data the app crashes when ads initialize',
    );
  });

  test('the App ID has App-ID shape, not an ad-unit shape', () {
    // App IDs use "~", ad unit IDs use "/". Pasting an ad unit ID here is a
    // common mix-up and produces a launch crash rather than a clear error.
    expect(appId(), startsWith('ca-app-pub-'));
    expect(
      appId(),
      contains('~'),
      reason: 'an App ID uses ~, an ad unit uses /',
    );
    expect(
      appId(),
      isNot(contains('/')),
      reason: 'this looks like an ad unit ID',
    );
  });

  test('the App ID is not one of the sibling apps\' own', () {
    // Every app in the portfolio has its own App ID under the same
    // publisher. Copying this file from one to the next is exactly how a
    // sibling's ID ends up here, and nothing at runtime would complain.
    for (final sibling in const {
      'ca-app-pub-1057967613304012~7914008366': 'crossword',
      'ca-app-pub-1057967613304012~2137218877': 'sudoku',
      'ca-app-pub-1057967613304012~1554723382': 'word search',
    }.entries) {
      expect(
        appId(),
        isNot(sibling.key),
        reason: 'this is the ${sibling.value} app\'s App ID',
      );
    }
  });

  test('the sample App ID is flagged as still to be replaced', () {
    // Memory Match has no AdMob app of its own yet, so the manifest
    // deliberately carries Google's public sample App ID: it is valid, so
    // the app launches, and it earns nothing, which is the honest state.
    //
    // This test is the reminder, not a rule — when the real ~ id is
    // pasted in, delete this test rather than working around it. What
    // must never happen is *shipping* the sample, so the check that
    // outlives this one is the sibling test above plus the release
    // checklist in store/PLAY_STORE_READINESS.md.
    const sample = 'ca-app-pub-3940256099942544~3347511713';
    if (appId() == sample) {
      expect(
        manifest,
        contains('no AdMob app of its own yet'),
        reason: 'the sample App ID must be commented as provisional',
      );
    }
  });
}
