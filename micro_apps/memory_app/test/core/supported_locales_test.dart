import 'dart:ui';

import 'package:memory_app/core/localization/supported_locales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupportedLocales', () {
    test('isSupported reflects AppConfig.supportedUILanguageCodes', () {
      expect(SupportedLocales.isSupported('en'), isTrue);
      expect(SupportedLocales.isSupported('ar'), isTrue);
      expect(SupportedLocales.isSupported('de'), isTrue);
      expect(SupportedLocales.isSupported('fr'), isTrue);
      expect(SupportedLocales.isSupported('es'), isTrue);
      expect(SupportedLocales.isSupported('it'), isTrue);
      // Not every language is supported just because a few are — this
      // must stay false, or the test would be vacuous.
      expect(SupportedLocales.isSupported('ja'), isFalse);
    });

    test('isRtl is true only for Arabic', () {
      expect(SupportedLocales.isRtl('ar'), isTrue);
      expect(SupportedLocales.isRtl('en'), isFalse);
      expect(SupportedLocales.isRtl('de'), isFalse);
    });

    test('resolveFromDevice picks the first supported device locale', () {
      final resolved = SupportedLocales.resolveFromDevice(const [
        Locale('ja'), // unsupported — should be skipped
        Locale('ar'),
        Locale('en'),
      ]);
      expect(resolved, const Locale('ar'));
    });

    test('resolveFromDevice returns the device locale directly when it is already supported',
        () {
      final resolved = SupportedLocales.resolveFromDevice(const [Locale('en')]);
      expect(resolved, const Locale('en'));
    });

    test('resolveFromDevice picks a non-English supported language over falling back', () {
      final resolved = SupportedLocales.resolveFromDevice(const [Locale('fr')]);
      expect(resolved, const Locale('fr'));
    });

    test('resolveFromDevice falls back to English when nothing matches (spec §10)', () {
      final resolved = SupportedLocales.resolveFromDevice(const [
        Locale('ja'),
        Locale('pt'),
      ]);
      expect(resolved, const Locale('en'));
    });

    test('resolveFromDevice falls back to English for an empty device locale list', () {
      final resolved = SupportedLocales.resolveFromDevice(const []);
      expect(resolved, const Locale('en'));
    });

    test('all lists exactly the currently supported UI locales', () {
      final codes = SupportedLocales.all.map((l) => l.languageCode).toSet();
      expect(codes, {'en', 'ar', 'de', 'fr', 'es', 'it'});
    });
  });
}
