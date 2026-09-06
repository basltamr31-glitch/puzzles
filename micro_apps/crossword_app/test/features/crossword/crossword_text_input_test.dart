import 'package:crossword_app/features/crossword/presentation/input/crossword_text_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeCrosswordInput', () {
    test('a character typed after the sentinel is a letter', () {
      expect(
        decodeCrosswordInput('${inputSentinel}C'),
        const CrosswordLetters('C'),
      );
    });

    test('the bare sentinel is a no-op, not a letter or a backspace', () {
      expect(decodeCrosswordInput(inputSentinel), const CrosswordNoInput());
    });

    test('an empty field is a backspace', () {
      expect(decodeCrosswordInput(''), const CrosswordBackspace());
    });

    test('an IME that replaces the whole field is still read as a letter', () {
      expect(decodeCrosswordInput('C'), const CrosswordLetters('C'));
    });

    test('multiple characters are all captured', () {
      expect(
        decodeCrosswordInput('${inputSentinel}CAT'),
        const CrosswordLetters('CAT'),
      );
    });

    // Regression: the old implementation cleared the field and set a
    // `suppressNextChange` flag. Flutter only fires onChanged for
    // platform/IME edits, not programmatic ones, so the flag often went
    // unconsumed and swallowed the *next* real keystroke — the player had
    // to tap twice. Decoding must therefore be stateless: the same
    // sequence must yield a letter every time, whether or not a reset
    // echoes back in between.
    test('consecutive keystrokes each register, with no swallowed input', () {
      final results = <CrosswordInput>[];
      for (final letter in ['C', 'A', 'T']) {
        results.add(decodeCrosswordInput('$inputSentinel$letter'));
        // Our reset, which may or may not echo back through onChanged.
        results.add(decodeCrosswordInput(inputSentinel));
      }

      expect(
        results.whereType<CrosswordLetters>().map((r) => r.letters).toList(),
        ['C', 'A', 'T'],
      );
      // The echoes are inert rather than consuming a keystroke.
      expect(results.whereType<CrosswordNoInput>().length, 3);
    });

    test('typing without any echoed reset also registers every keystroke', () {
      final results = [
        decodeCrosswordInput('${inputSentinel}C'),
        decodeCrosswordInput('${inputSentinel}A'),
        decodeCrosswordInput('${inputSentinel}T'),
      ];
      expect(
        results.map((r) => (r as CrosswordLetters).letters).toList(),
        ['C', 'A', 'T'],
      );
    });
  });
}
