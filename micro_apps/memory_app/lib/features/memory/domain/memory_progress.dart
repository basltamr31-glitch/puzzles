import 'dart:convert';

/// Everything worth restoring when a player reopens a deck: which cards
/// they have already matched, which ones they have *seen*, how many moves
/// they have spent and how long they have been playing.
///
/// [seenCards] is the unusual one, and it is not optional. Whether a
/// mismatch costs a life depends on whether the player had already been
/// shown both of those cards (see `MemoryController.flipCard`), so
/// dropping the seen set on a reopen would silently hand back the lives a
/// player had already put at risk — and make backing out to the list the
/// cheapest strategy in the game.
class MemoryProgress {
  const MemoryProgress({
    required this.matchedCards,
    required this.seenCards,
    required this.moves,
    required this.elapsedSeconds,
    required this.fingerprint,
  });

  const MemoryProgress.empty()
    : matchedCards = const {},
      seenCards = const {},
      moves = 0,
      elapsedSeconds = 0,
      fingerprint = '';

  /// Board positions whose pair has been found, row-major indices into
  /// `MemoryDeckDef.cards`.
  final Set<int> matchedCards;

  /// Board positions the player has had revealed at least once.
  final Set<int> seenCards;

  /// Completed reveals of two cards. The number a memory player actually
  /// competes against, more than the clock.
  final int moves;

  final int elapsedSeconds;

  /// The layout this progress was recorded against — see
  /// `deckFingerprint`. Progress whose fingerprint no longer matches the
  /// deck is discarded rather than replayed onto a different deal.
  final String fingerprint;

  MemoryProgress copyWith({
    Set<int>? matchedCards,
    Set<int>? seenCards,
    int? moves,
    int? elapsedSeconds,
    String? fingerprint,
  }) {
    return MemoryProgress(
      matchedCards: matchedCards ?? this.matchedCards,
      seenCards: seenCards ?? this.seenCards,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      fingerprint: fingerprint ?? this.fingerprint,
    );
  }

  String encode() {
    return jsonEncode({
      'matched': matchedCards.toList()..sort(),
      'seen': seenCards.toList()..sort(),
      'moves': moves,
      'elapsedSeconds': elapsedSeconds,
      'fingerprint': fingerprint,
    });
  }

  static MemoryProgress decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return MemoryProgress(
      matchedCards: (json['matched'] as List? ?? const []).cast<int>().toSet(),
      seenCards: (json['seen'] as List? ?? const []).cast<int>().toSet(),
      moves: (json['moves'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      fingerprint: json['fingerprint'] as String? ?? '',
    );
  }
}
