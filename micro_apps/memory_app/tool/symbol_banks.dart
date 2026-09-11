// The symbols decks are dealt from, one bank per theme.
//
// Generation-time content only: the app never reads this file. Whatever
// `generate_puzzles.dart` picks is written into the deck asset, so a bank
// edited here changes nothing until the decks are regenerated.
//
// Three rules these banks follow, and the reasons they exist:
//
//  1. **Every emoji is Unicode 9.0 or older** (2016). Android renders
//     emoji from the system font, so a newer codepoint is a blank
//     rectangle on the phones this app's `minSdk 21` invites in — and a
//     card showing a rectangle can still be *matched*, so it would ship
//     as a puzzle that merely looks broken rather than as a crash anyone
//     would notice in testing.
//  2. **No variation selectors, no ZWJ sequences, no skin tones.**
//     Characters like U+2600 need a trailing U+FE0F to render in colour
//     and fall back to a black-and-white glyph without it; a ZWJ sequence
//     that the platform does not know silently splits into two or three
//     separate glyphs, which changes how wide the card's symbol is.
//  3. **No two symbols in a bank read as the same thing at card size.**
//     The full moon and the new moon are a fair memory challenge; a
//     grinning face and a beaming face are a rendering coin-flip.
//
// Every bank must hold at least 15 symbols — the expert tier's pair
// count — and the mixed tiers draw at most two per theme, so eight banks
// is also the ceiling on how large a mixed deck can get.

import 'package:memory_app/features/memory/domain/memory_theme.dart';

const Map<MemoryTheme, List<String>> symbolBanks = {
  MemoryTheme.animals: [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🦆', '🦉',
  ],
  MemoryTheme.food: [
    '🍎', '🍌', '🍇', '🍉', '🍓', '🍒', '🍍', '🥝', '🍅', '🥕',
    '🌽', '🍕', '🍔', '🌭', '🍟', '🍩', '🍪', '🎂', '🍫', '🍿',
  ],
  MemoryTheme.nature: [
    '🌵', '🌲', '🌳', '🌴', '🌱', '🌿', '🍀', '🍁', '🍂', '🌸',
    '🌺', '🌻', '🌼', '🌷', '🌹', '🍄', '🌰', '🐚', '🌊', '🗻',
  ],
  MemoryTheme.travel: [
    '🚗', '🚕', '🚌', '🚑', '🚒', '🚜', '🚲', '🚂', '🚀', '🚁',
    '🛫', '🚢', '🗼', '🗽', '🏰', '⛺', '🎡', '🎢', '🚤', '🚠',
  ],
  MemoryTheme.sports: [
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸',
    '⛳', '🏹', '🎣', '🏒', '🏑', '🥇', '🥈', '🥉', '🎯', '🎳',
  ],
  MemoryTheme.faces: [
    '😀', '😆', '😅', '😂', '😉', '😊', '😍', '😘', '😜', '🤓',
    '😎', '🤔', '😴', '😭', '😡', '🤗', '😱', '🤒', '🤠', '👻',
  ],
  MemoryTheme.party: [
    '🎉', '🎊', '🎈', '🎁', '🍰', '🎄', '🎃', '🎆', '🎇', '🎀',
    '🎲', '🃏', '🎭', '🎬', '🎪', '🎠', '🔔', '💎', '👑', '🎩',
  ],
  MemoryTheme.objects: [
    '⌚', '📱', '💻', '📺', '💾', '💿', '📷', '📹', '📼', '🔍',
    '🔒', '🔑', '🔨', '💡', '📚', '📝', '📌', '📎', '🔦', '🔧',
  ],
};
