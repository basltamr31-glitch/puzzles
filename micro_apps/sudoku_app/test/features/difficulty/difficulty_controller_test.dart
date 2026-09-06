import 'package:sudoku_app/core/storage/local_storage_service.dart';
import 'package:sudoku_app/features/difficulty/difficulty_controller.dart';
import 'package:sudoku_app/shared/models/difficulty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression coverage for a real bug: the difficulty picked during
/// onboarding used to be a write-only, one-time choice — nothing
/// persisted it, and nothing let the player change it afterward. These
/// tests guard the fix: the choice is saved, and a fresh controller
/// (standing in for "the app relaunched") picks up the last selection
/// rather than defaulting back to Easy every time.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to easy when nothing has been selected yet', () async {
    final storage = await SharedPreferencesStorageService.create();
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    expect(container.read(difficultyControllerProvider), Difficulty.easy);
  });

  test('select() persists the choice so a later read sees it', () async {
    final storage = await SharedPreferencesStorageService.create();
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    await container.read(difficultyControllerProvider.notifier).select(Difficulty.hard);

    expect(container.read(difficultyControllerProvider), Difficulty.hard);
  });

  test('a fresh controller (simulating a relaunch) resumes the last difficulty, not Easy',
      () async {
    final storage = await SharedPreferencesStorageService.create();
    final firstContainer = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    await firstContainer.read(difficultyControllerProvider.notifier).select(Difficulty.expert);
    firstContainer.dispose();

    final secondContainer = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(secondContainer.dispose);

    expect(secondContainer.read(difficultyControllerProvider), Difficulty.expert);
  });

  test('the difficulty can be changed repeatedly, in any direction', () async {
    final storage = await SharedPreferencesStorageService.create();
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(difficultyControllerProvider.notifier);

    await notifier.select(Difficulty.hard);
    expect(container.read(difficultyControllerProvider), Difficulty.hard);

    await notifier.select(Difficulty.easy);
    expect(container.read(difficultyControllerProvider), Difficulty.easy);

    await notifier.select(Difficulty.medium);
    expect(container.read(difficultyControllerProvider), Difficulty.medium);
  });
}
