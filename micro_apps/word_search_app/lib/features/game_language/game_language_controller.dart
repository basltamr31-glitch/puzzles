import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';

/// The language word search *content* is played in — independent from the
/// app's UI language (spec §11/§12). `null` means the player hasn't
/// chosen one yet, which the router treats as "onboarding not finished".
class GameLanguageController extends Notifier<String?> {
  @override
  String? build() {
    final storage = ref.watch(localStorageServiceProvider);
    return storage.getString(StorageKeys.gameLanguageCode);
  }

  Future<void> select(String languageCode) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setString(StorageKeys.gameLanguageCode, languageCode);
    state = languageCode;
    ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.gameLanguageSelected,
      {'language_code': languageCode},
    );
  }
}

final gameLanguageControllerProvider =
    NotifierProvider<GameLanguageController, String?>(
      GameLanguageController.new,
    );
