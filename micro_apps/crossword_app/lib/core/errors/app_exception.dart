/// Base type for expected, user-facing failure conditions.
///
/// Anything thrown as an [AppException] is a condition the UI knows how to
/// present gracefully (a message + retry/dismiss), as opposed to a genuine
/// bug, which should surface as a normal Dart error caught by
/// [FlutterError.onError] / the global error boundary.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Puzzle JSON failed to parse or its word list is internally inconsistent
/// (e.g. overlapping cells disagree on a letter).
class InvalidPuzzleException extends AppException {
  const InvalidPuzzleException(super.message);
}

/// A requested puzzle asset does not exist.
class PuzzleNotFoundException extends AppException {
  const PuzzleNotFoundException(String puzzleId)
    : super('Puzzle "$puzzleId" could not be found.');
}

/// Persisted local state could not be decoded (corrupted preferences).
class CorruptedStateException extends AppException {
  const CorruptedStateException(super.message);
}
