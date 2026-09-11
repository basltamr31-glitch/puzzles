import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../../puzzle_list/domain/puzzle_summary.dart';
import '../domain/memory_models.dart';
import '../domain/memory_progress.dart';

/// Data-layer boundary for deck content and progress.
///
/// Loads deck JSON from assets (never touches the network — gameplay is
/// fully offline) and persists per-deck progress through
/// [LocalStorageService]. Feature code only ever talks to this repository,
/// never to `rootBundle` or storage directly.
class DeckRepository {
  DeckRepository(this._storage);

  final LocalStorageService _storage;

  /// One decoded bundle per difficulty, kept for the process lifetime.
  ///
  /// All 100 decks of a difficulty live in a single ~60KB asset, so the
  /// list screen, the game screen, and the "next deck" jump between them
  /// all share one parse instead of re-reading the bundle each time.
  final Map<String, List<MemoryDeckDef>> _cache = {};

  Future<List<MemoryDeckDef>> loadDifficulty(String difficulty) async {
    final cached = _cache[difficulty];
    if (cached != null) return cached;

    final String raw;
    try {
      raw = await rootBundle.loadString('assets/puzzles/$difficulty.json');
    } catch (_) {
      throw PuzzleNotFoundException('assets/puzzles/$difficulty.json');
    }

    final List<MemoryDeckDef> decks;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      decks = (json['decks'] as List)
          .map((e) => MemoryDeckDef.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on FormatException {
      throw InvalidPuzzleException(
        'Deck bundle for "$difficulty" is not valid JSON.',
      );
    } on InvalidPuzzleException {
      rethrow;
    } catch (_) {
      throw InvalidPuzzleException(
        'Deck bundle for "$difficulty" is missing expected fields.',
      );
    }

    if (decks.isEmpty) {
      throw InvalidPuzzleException('Deck bundle for "$difficulty" is empty.');
    }

    _cache[difficulty] = decks;
    return decks;
  }

  Future<List<PuzzleSummary>> listPuzzleSummaries({
    required String difficulty,
  }) async {
    final decks = await loadDifficulty(difficulty);
    return [
      for (var i = 0; i < decks.length; i++)
        PuzzleSummary(
          id: decks[i].id,
          difficulty: difficulty,
          index: i,
          pairCount: decks[i].pairCount,
          status: statusFor(decks[i].id),
          theme: decks[i].theme,
        ),
    ];
  }

  Future<MemoryDeckDef> loadDeck({
    required String difficulty,
    required int index,
  }) async {
    final decks = await loadDifficulty(difficulty);
    if (index < 0 || index >= decks.length) {
      throw PuzzleNotFoundException('$difficulty #$index');
    }
    return decks[index];
  }

  PuzzleStatus statusFor(String deckId) {
    if (_storage.getBool(StorageKeys.puzzleCompleted(deckId)) ?? false) {
      return PuzzleStatus.completed;
    }
    if (_storage.getString(StorageKeys.puzzleProgress(deckId)) != null) {
      return PuzzleStatus.inProgress;
    }
    return PuzzleStatus.notStarted;
  }

  /// Matched cards, seen cards, moves and elapsed time, or null if there
  /// is none. Corrupted or unreadable progress is treated as "no
  /// progress" rather than crashing the game screen.
  MemoryProgress? loadProgress(String deckId) {
    final raw = _storage.getString(StorageKeys.puzzleProgress(deckId));
    if (raw == null) return null;
    try {
      return MemoryProgress.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress(String deckId, MemoryProgress progress) async {
    await _storage.setString(
      StorageKeys.puzzleProgress(deckId),
      progress.encode(),
    );
  }

  Future<void> markCompleted(String deckId) async {
    await _storage.setBool(StorageKeys.puzzleCompleted(deckId), true);
  }

  Future<void> clearProgress(String deckId) async {
    await _storage.remove(StorageKeys.puzzleProgress(deckId));
    await _storage.remove(StorageKeys.puzzleCompleted(deckId));
  }
}

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(ref.watch(localStorageServiceProvider));
});
