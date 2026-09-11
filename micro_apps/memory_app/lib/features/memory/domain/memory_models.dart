import 'package:equatable/equatable.dart';

import '../../../core/errors/app_exception.dart';
import 'memory_theme.dart';

/// A deck exactly as it is stored on disk: the symbols in the order they
/// are dealt onto the board, plus the shape of that board.
///
/// The **layout is stored, not shuffled at runtime**. Two players opening
/// deck `easy_007` must see the same board, and a player who backs out
/// mid-game and comes back must find their cards where they left them —
/// neither survives a shuffle on load. It is also what lets saved
/// progress be a set of board positions instead of a set of symbols.
///
/// [cards] is ordered row-major: index `r * cols + c`.
class MemoryDeckDef extends Equatable {
  const MemoryDeckDef({
    required this.id,
    required this.difficulty,
    required this.index,
    required this.rows,
    required this.cols,
    required this.cards,
    this.theme,
  });

  final String id;
  final String difficulty;

  /// Zero-based position within its difficulty — the routing key and the
  /// number shown to the player (as [index] + 1).
  final int index;

  final int rows;
  final int cols;

  /// One symbol per board position, row-major. Every symbol appears
  /// exactly twice.
  final List<String> cards;

  /// Null when the asset names a theme this build does not know.
  final MemoryTheme? theme;

  int get cardCount => cards.length;
  int get pairCount => cards.length ~/ 2;

  String symbolAt(int index) => cards[index];
  int rowOf(int index) => index ~/ cols;
  int colOf(int index) => index % cols;

  factory MemoryDeckDef.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final difficulty = json['difficulty'] as String?;
    final index = json['index'];
    final rows = json['rows'];
    final cols = json['cols'];
    final cardsJson = json['cards'];

    if (id == null ||
        difficulty == null ||
        index is! int ||
        rows is! int ||
        cols is! int ||
        cardsJson is! List ||
        cardsJson.isEmpty) {
      throw const InvalidPuzzleException(
        'Deck is missing required fields (id, difficulty, index, rows, '
        'cols, cards).',
      );
    }

    final cards = cardsJson.cast<String>();
    if (cards.length != rows * cols) {
      throw InvalidPuzzleException(
        'Deck "$id" declares a ${rows}x$cols board but carries '
        '${cards.length} cards.',
      );
    }

    // Checked on load, not only at generation time: a deck with an odd
    // symbol out can never be completed, and a player would only discover
    // that after finding every other pair. Failing here means the deck is
    // skipped and the rest of the difficulty stays playable.
    final counts = <String, int>{};
    for (final symbol in cards) {
      counts[symbol] = (counts[symbol] ?? 0) + 1;
    }
    final unpaired = counts.entries.where((e) => e.value != 2).toList();
    if (unpaired.isNotEmpty) {
      throw InvalidPuzzleException(
        'Deck "$id" has ${unpaired.length} symbol(s) that do not appear '
        'exactly twice.',
      );
    }

    return MemoryDeckDef(
      id: id,
      difficulty: difficulty,
      index: index,
      rows: rows,
      cols: cols,
      cards: cards,
      theme: MemoryTheme.fromId(json['theme'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'difficulty': difficulty,
    'index': index,
    if (theme != null) 'theme': theme!.id,
    'rows': rows,
    'cols': cols,
    'cards': cards,
  };

  @override
  List<Object?> get props => [id, difficulty, index, rows, cols, cards, theme];
}

/// A stable fingerprint of a deck's layout.
///
/// Saved progress is a set of *board positions*, and positions only mean
/// anything against the exact deal they were recorded on. Deck ids are
/// stable across releases while the layouts behind them are regenerated
/// content — so a player mid-way through the old `easy_007` would come
/// back to find their matched cards pointing at whatever symbols now sit
/// in those cells. Comparing this fingerprint is what catches that.
///
/// FNV-1a rather than [Object.hashCode]: Dart's string hash is only
/// promised to be stable within one process, and this value is written to
/// disk and read back by a later build.
String deckFingerprint(List<String> cards) {
  var hash = 0x811c9dc5;
  for (final unit in cards.join(' ').codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
