import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the AdMob App ID in AndroidManifest.xml.
///
/// This one value is easy to get wrong and expensive when it is:
/// - missing or malformed → the app **crashes on launch** when the ads SDK
///   initializes, before any screen renders;
/// - left as Google's sample ID → the shipped app can never earn anything,
///   and it is a fault nobody notices until after release.
///
/// Reading the manifest directly is the only way to catch either, since
/// neither is visible from Dart at runtime.
void main() {
  late String manifest;

  setUpAll(() {
    manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  });

  test('the AdMob App ID meta-data is present', () {
    expect(
      manifest.contains('com.google.android.gms.ads.APPLICATION_ID'),
      isTrue,
      reason: 'without this meta-data the app crashes when ads initialize',
    );
  });

  test('the App ID is a real one, not Google\'s sample', () {
    // 3940256099942544 is Google's public sample publisher, fine for the
    // test *ad units* but never correct as a shipped App ID.
    expect(
      manifest.contains('ca-app-pub-3940256099942544~'),
      isFalse,
      reason: 'the sample App ID would ship an app that can never earn',
    );
  });

  test('the App ID has App-ID shape, not an ad-unit shape', () {
    // App IDs use "~", ad unit IDs use "/". Pasting an ad unit ID here is a
    // common mix-up and produces a launch crash rather than a clear error.
    final match = RegExp(
      r'APPLICATION_ID"\s*\n?\s*android:value="([^"]+)"',
    ).firstMatch(manifest);

    expect(match, isNotNull, reason: 'could not read the App ID value');
    final appId = match!.group(1)!;

    expect(appId, startsWith('ca-app-pub-'));
    expect(appId, contains('~'), reason: 'an App ID uses ~, an ad unit uses /');
    expect(appId, isNot(contains('/')), reason: 'this looks like an ad unit ID');
  });
}
