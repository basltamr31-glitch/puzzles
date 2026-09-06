import 'package:flutter/foundation.dart';

/// Centralized, static configuration for the Sudoku app.
///
/// Every environment or product-level constant lives here so the rest of
/// the app never hardcodes IDs, locales, or feature-flag-style values.
/// Future apps in the portfolio copy this file's shape and replace values.
class AppConfig {
  AppConfig._();

  static const String appName = 'Sudoku';
  static const String applicationId = 'com.baslt.sudoku_app';

  /// Languages the app UI itself can be displayed in.
  /// Must have a matching lib/core/localization/l10n/app_<code>.arb file.
  ///
  /// This is the *only* language list in the app — see the note above
  /// [difficultyOrder] for why Sudoku has no separate puzzle language.
  static const List<String> supportedUILanguageCodes = [
    'en',
    'ar',
    'de',
    'fr',
    'es',
    'it',
  ];
  static const String fallbackUILanguageCode = 'en';

  /// Right-to-left UI languages. The Sudoku grid itself is always laid
  /// out left-to-right — digits and box positions are not mirrored in
  /// Arabic Sudoku — so only the surrounding chrome follows this.
  static const List<String> rtlLanguageCodes = ['ar'];

  /// Sudoku deliberately has **no** game-language concept. A Sudoku grid
  /// contains digits, not words, so the same puzzle bundle serves every
  /// UI language — unlike the crossword app, which needs a separate
  /// puzzle language per player. Do not reintroduce one here.
  static const List<String> difficultyOrder = [
    'easy',
    'medium',
    'hard',
    'expert',
  ];

  /// Public URL of the hosted privacy policy.
  ///
  /// Google Play requires this in the store listing; the in-app screen
  /// renders the same bundled file, so the two cannot disagree. Empty
  /// until the policy is hosted — see assets/legal/privacy_policy.md.
  static const String privacyPolicyUrl =
      'https://doc-hosting.flycricket.io/sudoku/e1f77064-12f0-48a1-9676-3bd58e1334dd/privacy';

  static const String removeAdsProductId = 'remove_ads';

  /// Real ad unit IDs are supplied at build time via `--dart-define`
  /// (e.g. `BANNER_AD_UNIT_ID=ca-app-pub-...`). Until that's configured:
  /// - Debug builds fall back to Google's public *test* ad unit IDs, so
  ///   ads actually load and render during development without risking
  ///   invalid-traffic issues on a real account.
  /// - Release builds resolve to an empty string, which [AdService]
  ///   implementations must treat as "no ad configured" and skip
  ///   loading — never guessing or shipping a test ID by accident.
  static String get bannerAdUnitId => _resolveAdUnitId(
        override: const String.fromEnvironment('BANNER_AD_UNIT_ID'),
        androidTestId: 'ca-app-pub-3940256099942544/6300978111',
        iosTestId: 'ca-app-pub-3940256099942544/2934735716',
      );

  static String get interstitialAdUnitId => _resolveAdUnitId(
        override: const String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID'),
        androidTestId: 'ca-app-pub-3940256099942544/1033173712',
        iosTestId: 'ca-app-pub-3940256099942544/4411468910',
      );

  static String get rewardedAdUnitId => _resolveAdUnitId(
        override: const String.fromEnvironment('REWARDED_AD_UNIT_ID'),
        androidTestId: 'ca-app-pub-3940256099942544/5224354917',
        iosTestId: 'ca-app-pub-3940256099942544/1712485313',
      );

  static String _resolveAdUnitId({
    required String override,
    required String androidTestId,
    required String iosTestId,
  }) {
    if (override.isNotEmpty) return override;
    if (!isDebug) return '';
    return defaultTargetPlatform == TargetPlatform.iOS ? iosTestId : androidTestId;
  }

  /// Minimum number of puzzle completions between interstitial ads.
  static const int interstitialMinPuzzlesBetween = 3;

  static bool get isDebug => kDebugMode;
}
