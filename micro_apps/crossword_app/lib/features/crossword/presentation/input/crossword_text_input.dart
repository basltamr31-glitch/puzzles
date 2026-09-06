/// Decoding for the hidden text field that drives crossword typing.
///
/// The field is kept holding a single zero-width sentinel character rather
/// than being cleared to empty. That makes decoding *stateless*: what the
/// player typed is whatever sits after the sentinel, and a value that is
/// exactly the sentinel means "this is our own reset echoing back", which
/// is a no-op.
///
/// The previous approach — clear the field and set a `suppressNextChange`
/// flag — was subtly broken: Flutter only invokes `TextField.onChanged`
/// for platform/IME edits, *not* for programmatic controller changes, so
/// the flag was frequently set but never consumed and then swallowed the
/// next real keystroke (the "have to tap twice" bug). Some Android IMEs
/// echo the programmatic edit back and some don't, which is exactly why it
/// looked intermittent. Comparing against a sentinel is idempotent, so an
/// echoed callback is harmless whether it arrives or not.
library;

/// Zero-width space. Invisible, and never a letter any puzzle expects.
const String inputSentinel = '​';

sealed class CrosswordInput {
  const CrosswordInput();
}

/// The player typed one or more characters.
class CrosswordLetters extends CrosswordInput {
  const CrosswordLetters(this.letters);

  final String letters;

  @override
  bool operator ==(Object other) =>
      other is CrosswordLetters && other.letters == letters;

  @override
  int get hashCode => letters.hashCode;

  @override
  String toString() => 'CrosswordLetters($letters)';
}

/// The player deleted — the sentinel itself was removed.
class CrosswordBackspace extends CrosswordInput {
  const CrosswordBackspace();

  @override
  bool operator ==(Object other) => other is CrosswordBackspace;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'CrosswordBackspace()';
}

/// Nothing happened — typically our own field reset being reported back.
class CrosswordNoInput extends CrosswordInput {
  const CrosswordNoInput();

  @override
  bool operator ==(Object other) => other is CrosswordNoInput;

  @override
  int get hashCode => 1;

  @override
  String toString() => 'CrosswordNoInput()';
}

/// Interprets the hidden field's raw value. Pure and idempotent —
/// [rawValue] alone determines the result, with no cross-callback state.
CrosswordInput decodeCrosswordInput(String rawValue) {
  if (rawValue == inputSentinel) return const CrosswordNoInput();

  // Shorter than the sentinel means the sentinel was deleted: a backspace
  // at the start of the field.
  if (rawValue.length < inputSentinel.length) return const CrosswordBackspace();

  // Normally the typed characters land after the sentinel. Some IMEs
  // replace the whole field instead, so fall back to treating the entire
  // value as freshly typed.
  final typed = rawValue.startsWith(inputSentinel)
      ? rawValue.substring(inputSentinel.length)
      : rawValue;

  if (typed.isEmpty) return const CrosswordBackspace();
  return CrosswordLetters(typed);
}
