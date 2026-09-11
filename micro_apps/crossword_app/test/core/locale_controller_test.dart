import 'dart:ui';

import 'package:crossword_app/core/localization/locale_controller.dart';
import 'package:crossword_app/core/storage/local_storage_service.dart';
import 'package:crossword_app/core/storage/storage_keys.dart';
import 'package:crossword_app/features/game_language/game_language_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The UI language and the game language stay separate *settings*, but
/// they no longer resolve independently: an Arabic player on an
/// English-language phone was shown an Arabic board with `Hint` and
/// `Check` written in English, because the UI fell straight through to the
/// device locale and nothing ever considered the language they had chosen
/// to play in.
Future<ProviderContainer> _container(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  final storage = await SharedPreferencesStorageService.create();
  return ProviderContainer(
    overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'falls back to the chosen game language when the UI language is unset',
    () async {
      final container = await _container({StorageKeys.gameLanguageCode: 'ar'});
      addTearDown(container.dispose);

      expect(container.read(localeControllerProvider), const Locale('ar'));
    },
  );

  test(
    'an explicit Settings choice still wins over the game language',
    () async {
      final container = await _container({
        StorageKeys.gameLanguageCode: 'ar',
        StorageKeys.uiLanguageCode: 'en',
      });
      addTearDown(container.dispose);

      expect(container.read(localeControllerProvider), const Locale('en'));
    },
  );

  test(
    'a game language with no UI translation leaves the UI resolution alone',
    () async {
      final container = await _container({StorageKeys.gameLanguageCode: 'ja'});
      addTearDown(container.dispose);

      // Whatever the device says — the point is that an untranslated code is
      // never adopted as a UI locale.
      expect(
        container.read(localeControllerProvider),
        isNot(const Locale('ja')),
      );
    },
  );

  test(
    'picking a game language moves the UI with it, without a relaunch',
    () async {
      final container = await _container({});
      addTearDown(container.dispose);
      expect(
        container.read(localeControllerProvider),
        isNot(const Locale('ar')),
      );

      await container
          .read(gameLanguageControllerProvider.notifier)
          .select('ar');

      expect(container.read(localeControllerProvider), const Locale('ar'));
    },
  );

  test(
    'picking a game language does not overwrite an explicit UI choice',
    () async {
      final container = await _container({StorageKeys.uiLanguageCode: 'en'});
      addTearDown(container.dispose);

      await container
          .read(gameLanguageControllerProvider.notifier)
          .select('ar');

      expect(container.read(localeControllerProvider), const Locale('en'));
      expect(container.read(gameLanguageControllerProvider), 'ar');
    },
  );
}
