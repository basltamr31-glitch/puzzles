import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/player_progress.dart';
import '../domain/puzzle_attempt.dart';

/// Reads and writes the player's progress and their per-puzzle star
/// results. Reads are synchronous — the storage layer is a warmed-up
/// SharedPreferences cache — so the puzzle list can render stars without a
/// loading state on every row.
class RewardsRepository {
  RewardsRepository(this._storage);

  final LocalStorageService _storage;

  PlayerProgress loadProgress() =>
      PlayerProgress.decode(_storage.getString(StorageKeys.playerProgress));

  Future<void> saveProgress(PlayerProgress progress) =>
      _storage.setString(StorageKeys.playerProgress, progress.encode());

  /// The best star result recorded for [puzzleId], or 0 if it has never
  /// been solved.
  int starsFor(String puzzleId) =>
      _storage.getInt(StorageKeys.puzzleStars(puzzleId)) ?? 0;

  Future<void> saveStars(String puzzleId, int stars) =>
      _storage.setInt(StorageKeys.puzzleStars(puzzleId), stars);

  Future<void> clearStars(String puzzleId) =>
      _storage.remove(StorageKeys.puzzleStars(puzzleId));

  PuzzleAttempt loadAttempt(String puzzleId) =>
      PuzzleAttempt.decode(_storage.getString(StorageKeys.puzzleAttempt(puzzleId)));

  Future<void> saveAttempt(String puzzleId, PuzzleAttempt attempt) =>
      _storage.setString(StorageKeys.puzzleAttempt(puzzleId), attempt.encode());

  Future<void> clearAttempt(String puzzleId) =>
      _storage.remove(StorageKeys.puzzleAttempt(puzzleId));
}

final rewardsRepositoryProvider = Provider<RewardsRepository>(
  (ref) => RewardsRepository(ref.watch(localStorageServiceProvider)),
);
