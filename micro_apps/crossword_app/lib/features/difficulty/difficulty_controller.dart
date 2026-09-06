import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../../shared/models/difficulty.dart';

/// The player's current difficulty — persisted so it survives restarts,
/// and changeable at any time (not just once during onboarding). Read by
/// the router's redirect guard so a returning player lands back on
/// whichever difficulty they were last playing, not always Easy.
class DifficultyController extends Notifier<Difficulty> {
  @override
  Difficulty build() {
    final storage = ref.watch(localStorageServiceProvider);
    final stored = storage.getString(StorageKeys.difficulty);
    return stored == null
        ? Difficulty.easy
        : Difficulty.fromStorageValue(stored);
  }

  Future<void> select(Difficulty difficulty) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setString(StorageKeys.difficulty, difficulty.storageValue);
    state = difficulty;
    ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.difficultySelected,
      {'difficulty': difficulty.storageValue},
    );
  }
}

final difficultyControllerProvider =
    NotifierProvider<DifficultyController, Difficulty>(
      DifficultyController.new,
    );
