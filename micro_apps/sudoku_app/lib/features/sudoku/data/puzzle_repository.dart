import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../../puzzle_list/domain/puzzle_summary.dart';
import '../domain/sudoku_models.dart';
import '../domain/sudoku_progress.dart';

/// Data-layer boundary for puzzle content and progress.
///
/// Loads puzzle JSON from assets (never touches the network — gameplay is
/// fully offline) and persists per-puzzle progress through
/// [LocalStorageService]. Feature code only ever talks to this repository,
/// never to `rootBundle` or storage directly.
class PuzzleRepository {
  PuzzleRepository(this._storage);

  final LocalStorageService _storage;

  /// One decoded bundle per difficulty, kept for the process lifetime.
  ///
  /// All 100 puzzles of a difficulty live in a single ~20KB asset, so the
  /// list screen, the game screen, and the "next puzzle" jump between
  /// them all share one parse instead of re-reading the bundle each time.
  final Map<String, List<SudokuPuzzleDef>> _cache = {};

  Future<List<SudokuPuzzleDef>> loadDifficulty(String difficulty) async {
    final cached = _cache[difficulty];
    if (cached != null) return cached;

    final String raw;
    try {
      raw = await rootBundle.loadString('assets/puzzles/$difficulty.json');
    } catch (_) {
      throw PuzzleNotFoundException('assets/puzzles/$difficulty.json');
    }

    final List<SudokuPuzzleDef> puzzles;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      puzzles = (json['puzzles'] as List)
          .map((e) => SudokuPuzzleDef.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on FormatException {
      throw InvalidPuzzleException(
        'Puzzle bundle for "$difficulty" is not valid JSON.',
      );
    } catch (_) {
      throw InvalidPuzzleException(
        'Puzzle bundle for "$difficulty" is missing expected fields.',
      );
    }

    if (puzzles.isEmpty) {
      throw InvalidPuzzleException('Puzzle bundle for "$difficulty" is empty.');
    }

    _cache[difficulty] = puzzles;
    return puzzles;
  }

  Future<List<PuzzleSummary>> listPuzzleSummaries({
    required String difficulty,
  }) async {
    final puzzles = await loadDifficulty(difficulty);
    return [
      for (var i = 0; i < puzzles.length; i++)
        PuzzleSummary(
          id: puzzles[i].id,
          difficulty: difficulty,
          index: i,
          givenCount: puzzles[i].givenCount,
          status: statusFor(puzzles[i].id),
        ),
    ];
  }

  Future<SudokuPuzzleDef> loadPuzzle({
    required String difficulty,
    required int index,
  }) async {
    final puzzles = await loadDifficulty(difficulty);
    if (index < 0 || index >= puzzles.length) {
      throw PuzzleNotFoundException('$difficulty #$index');
    }
    return puzzles[index];
  }

  PuzzleStatus statusFor(String puzzleId) {
    if (_storage.getBool(StorageKeys.puzzleCompleted(puzzleId)) ?? false) {
      return PuzzleStatus.completed;
    }
    if (_storage.getString(StorageKeys.puzzleProgress(puzzleId)) != null) {
      return PuzzleStatus.inProgress;
    }
    return PuzzleStatus.notStarted;
  }

  /// Saved entries, notes, and elapsed time, or null if there is none.
  /// Corrupted or unreadable progress is treated as "no progress" rather
  /// than crashing the puzzle screen.
  SudokuProgress? loadProgress(String puzzleId) {
    final raw = _storage.getString(StorageKeys.puzzleProgress(puzzleId));
    if (raw == null) return null;
    try {
      return SudokuProgress.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress(String puzzleId, SudokuProgress progress) async {
    await _storage.setString(
      StorageKeys.puzzleProgress(puzzleId),
      progress.encode(),
    );
  }

  Future<void> markCompleted(String puzzleId) async {
    await _storage.setBool(StorageKeys.puzzleCompleted(puzzleId), true);
  }

  Future<void> clearProgress(String puzzleId) async {
    await _storage.remove(StorageKeys.puzzleProgress(puzzleId));
    await _storage.remove(StorageKeys.puzzleCompleted(puzzleId));
  }
}

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return PuzzleRepository(ref.watch(localStorageServiceProvider));
});
