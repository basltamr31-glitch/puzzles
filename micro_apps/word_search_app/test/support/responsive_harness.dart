import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_search_app/app/app_config.dart';
import 'package:word_search_app/app/theme/app_theme.dart';
import 'package:word_search_app/core/ads/ad_service.dart';
import 'package:word_search_app/core/billing/billing_service.dart';
import 'package:word_search_app/core/billing/premium_state.dart';
import 'package:word_search_app/core/consent/consent_service.dart';
import 'package:word_search_app/core/localization/generated/app_localizations.dart';
import 'package:word_search_app/core/storage/local_storage_service.dart';

/// One device, locale and text-scale combination to render a screen under.
class LayoutCase {
  const LayoutCase({
    required this.label,
    required this.size,
    required this.locale,
    this.textScale = 1.0,
    this.themeMode = ThemeMode.light,
  });

  final String label;
  final Size size;
  final String locale;
  final double textScale;
  final ThemeMode themeMode;

  @override
  String toString() => label;
}

/// The combinations worth checking. Small enough to run on every screen,
/// wide enough to catch the three things that actually break layouts:
/// a narrow phone, a large accessibility text scale, and RTL.
const responsiveCases = <LayoutCase>[
  LayoutCase(label: 'small phone', size: Size(320, 568), locale: 'en'),
  LayoutCase(
    label: 'small phone, 1.5x text',
    size: Size(320, 568),
    locale: 'en',
    textScale: 1.5,
  ),
  LayoutCase(label: 'small phone, RTL', size: Size(320, 568), locale: 'ar'),
  LayoutCase(
    label: 'typical phone, 1.3x text, RTL',
    size: Size(411, 891),
    locale: 'ar',
    textScale: 1.3,
  ),
  LayoutCase(label: 'tablet', size: Size(834, 1112), locale: 'en'),
  LayoutCase(
    label: 'tablet, 1.5x text, RTL',
    size: Size(834, 1112),
    locale: 'ar',
    textScale: 1.5,
  ),
  // Dark mode is a different set of colour tokens and, in places, a
  // different widget tree (the card shadow is dropped), so the worst
  // case is worth running in both themes.
  LayoutCase(
    label: 'small phone, dark',
    size: Size(320, 568),
    locale: 'en',
    themeMode: ThemeMode.dark,
  ),
  LayoutCase(
    label: 'small phone, 1.5x text, dark',
    size: Size(320, 568),
    locale: 'en',
    textScale: 1.5,
    themeMode: ThemeMode.dark,
  ),
];

/// Pumps [child] inside the app's real theme and localizations at a given
/// [layoutCase], with the platform-backed services stubbed out.
///
/// Deliberately does *not* build the router: `testWidgets` cases in one
/// file share an isolate, and go_router leaks route state between them.
/// Screens are pumped directly instead, which also keeps each case fast.
Future<void> pumpAtViewport(
  WidgetTester tester,
  LayoutCase layoutCase, {
  required Widget child,
  Map<String, Object> initialPrefs = const {},
}) async {
  tester.view.physicalSize = layoutCase.size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);

  SharedPreferences.setMockInitialValues(initialPrefs);
  final storage = await SharedPreferencesStorageService.create();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        adServiceProvider.overrideWithValue(const NoOpAdService()),
        billingServiceProvider.overrideWithValue(const NoOpBillingService()),
        consentServiceProvider.overrideWithValue(const NoOpConsentService()),
      ],
      child: MaterialApp(
        locale: Locale(layoutCase.locale),
        supportedLocales: AppConfig.supportedUILanguageCodes.map(Locale.new),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: layoutCase.themeMode,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: layoutCase.size,
              textScaler: TextScaler.linear(layoutCase.textScale),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Advances enough frames for async asset loads and entry animations to
/// finish, without requiring the tree to go quiescent.
///
/// `pumpAndSettle` cannot be used on these screens: the loading state
/// shows a [CircularProgressIndicator], which animates forever, so
/// settling never happens and the test times out instead of reporting
/// what it found.
Future<void> pumpFrames(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}
