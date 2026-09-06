import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../../puzzle_list/domain/puzzle_summary.dart';
import '../domain/crossword_grid_generator.dart';
import '../domain/crossword_models.dart';

/// Data-layer boundary for puzzle content and progress.
///
/// Loads puzzle JSON from assets (never touches the network — gameplay is
/// fully offline per spec §17) and persists per-puzzle progress through
/// [LocalStorageService]. Feature code (controllers/screens) only ever
/// talks to this repository, never to `rootBundle` or storage directly.
class PuzzleRepository {
  PuzzleRepository(this._storage);

  final LocalStorageService _storage;

  Future<List<PuzzleSummary>> listPuzzleSummaries({
    required String language,
    required String difficulty,
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final prefix = 'assets/puzzles/$language/$difficulty/';
    final matches =
        assets
            .where((a) => a.startsWith(prefix) && a.endsWith('.json'))
            .toList()
          ..sort();

    final summaries = <PuzzleSummary>[];
    for (final assetPath in matches) {
      try {
        final def = await loadPuzzleDef(assetPath);
        summaries.add(
          PuzzleSummary(
            assetPath: assetPath,
            id: def.id,
            title: def.title,
            status: statusFor(def.id),
          ),
        );
      } on AppException {
        // A corrupted/invalid puzzle file must not take down the whole
        // list — skip it and keep the rest playable.
        continue;
      }
    }
    return summaries;
  }

  Future<CrosswordPuzzleDef> loadPuzzleDef(String assetPath) async {
    final String raw;
    try {
      raw = await rootBundle.loadString(assetPath);
    } catch (_) {
      throw PuzzleNotFoundException(assetPath);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      throw InvalidPuzzleException(
        'Puzzle file "$assetPath" is not valid JSON.',
      );
    }

    return CrosswordPuzzleDef.fromJson(json);
  }

  Future<CrosswordGrid> loadGrid(String assetPath) async {
    final def = await loadPuzzleDef(assetPath);
    return CrosswordGridGenerator.generate(def);
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

  /// Returns saved letters keyed as "row,col" -> letter, or null if there
  /// is no saved progress. Corrupted/unreadable progress is treated as
  /// "no progress" rather than crashing the puzzle screen (spec §30).
  Map<String, String>? loadProgress(String puzzleId) {
    final raw = _storage.getString(StorageKeys.puzzleProgress(puzzleId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress(
    String puzzleId,
    Map<String, String> letters,
  ) async {
    await _storage.setString(
      StorageKeys.puzzleProgress(puzzleId),
      jsonEncode(letters),
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
