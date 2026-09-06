import 'package:equatable/equatable.dart';

/// Side length of the grid, and of the 3x3 boxes inside it. Everything
/// else derives from these two so the code reads as "Sudoku" rather than
/// as a pile of 9s and 3s.
const int sudokuSize = 9;
const int sudokuBoxSize = 3;
const int sudokuCellCount = sudokuSize * sudokuSize;

/// A puzzle exactly as it is stored on disk.
///
/// [givens] and [solution] are each 81 characters read row by row.
/// A given of `.` means "empty, for the player to fill in"; every other
/// character is the digit `1`-`9`. Storing them as flat strings rather
/// than nested lists is what lets 100 puzzles fit in one small JSON file.
class SudokuPuzzleDef extends Equatable {
  const SudokuPuzzleDef({
    required this.id,
    required this.difficulty,
    required this.givens,
    required this.solution,
  });

  factory SudokuPuzzleDef.fromJson(Map<String, dynamic> json) {
    return SudokuPuzzleDef(
      id: json['id'] as String,
      difficulty: json['difficulty'] as String,
      givens: json['givens'] as String,
      solution: json['solution'] as String,
    );
  }

  final String id;
  final String difficulty;
  final String givens;
  final String solution;

  /// Number of digits the puzzle starts with. The conventional headline
  /// measure of how hard a Sudoku looks (though not of how hard it
  /// actually is to solve — see [SudokuTechnique]).
  int get givenCount => givens.split('').where((c) => c != emptyCell).length;

  bool isGiven(int index) => givens[index] != emptyCell;

  Map<String, dynamic> toJson() => {
        'id': id,
        'difficulty': difficulty,
        'givens': givens,
        'solution': solution,
      };

  @override
  List<Object?> get props => [id, difficulty, givens, solution];
}

const String emptyCell = '.';

int indexOf(int row, int col) => row * sudokuSize + col;
int rowOf(int index) => index ~/ sudokuSize;
int colOf(int index) => index % sudokuSize;
int boxOf(int index) =>
    (rowOf(index) ~/ sudokuBoxSize) * sudokuBoxSize + colOf(index) ~/ sudokuBoxSize;

/// The indices sharing a row, column, or box with [index] — the cells a
/// value in [index] constrains. Precomputed once because both the solver
/// and every grid repaint ask for them.
final List<List<int>> sudokuPeers = List.generate(sudokuCellCount, (index) {
  final peers = <int>{};
  for (var i = 0; i < sudokuCellCount; i++) {
    if (i == index) continue;
    if (rowOf(i) == rowOf(index) || colOf(i) == colOf(index) || boxOf(i) == boxOf(index)) {
      peers.add(i);
    }
  }
  return peers.toList(growable: false);
}, growable: false);

/// The three kinds of group ("house") a Sudoku constraint applies to,
/// flattened into one list of 27 index groups for solver convenience.
final List<List<int>> sudokuUnits = () {
  final units = <List<int>>[];
  for (var r = 0; r < sudokuSize; r++) {
    units.add(List.generate(sudokuSize, (c) => indexOf(r, c)));
  }
  for (var c = 0; c < sudokuSize; c++) {
    units.add(List.generate(sudokuSize, (r) => indexOf(r, c)));
  }
  for (var b = 0; b < sudokuSize; b++) {
    final baseRow = (b ~/ sudokuBoxSize) * sudokuBoxSize;
    final baseCol = (b % sudokuBoxSize) * sudokuBoxSize;
    units.add([
      for (var r = 0; r < sudokuBoxSize; r++)
        for (var c = 0; c < sudokuBoxSize; c++) indexOf(baseRow + r, baseCol + c),
    ]);
  }
  return List<List<int>>.unmodifiable(units);
}();
