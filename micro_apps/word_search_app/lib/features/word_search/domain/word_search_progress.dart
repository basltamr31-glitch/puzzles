import 'dart:convert';

/// Everything worth restoring when a player reopens a puzzle: which words
/// they've already found and how long they've spent.
///
/// Unlike the crossword app there is no per-cell letter grid to restore —
/// the grid is static content, not player input — so "progress" collapses
/// to the one thing that actually changes: the found-word set.
class WordSearchProgress {
  const WordSearchProgress({
    required this.foundWords,
    required this.elapsedSeconds,
  });

  const WordSearchProgress.empty()
    : foundWords = const {},
      elapsedSeconds = 0;

  final Set<String> foundWords;
  final int elapsedSeconds;

  WordSearchProgress copyWith({
    Set<String>? foundWords,
    int? elapsedSeconds,
  }) {
    return WordSearchProgress(
      foundWords: foundWords ?? this.foundWords,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  String encode() {
    return jsonEncode({
      'foundWords': foundWords.toList()..sort(),
      'elapsedSeconds': elapsedSeconds,
    });
  }

  static WordSearchProgress decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final rawFound = json['foundWords'] as List? ?? const [];
    return WordSearchProgress(
      foundWords: rawFound.cast<String>().toSet(),
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
