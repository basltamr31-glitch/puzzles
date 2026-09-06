import 'package:flutter/material.dart';

import '../../domain/clue_category.dart';

/// Icon for a [ClueCategory].
///
/// Chosen to signal the *field* a word belongs to without depicting the
/// word itself — a paw print for "animal", not a cat. See [ClueCategory]
/// for why that distinction is the whole point.
IconData clueCategoryIcon(ClueCategory category) {
  return switch (category) {
    ClueCategory.animal => Icons.pets_rounded,
    ClueCategory.nature => Icons.eco_rounded,
    ClueCategory.food => Icons.restaurant_rounded,
    ClueCategory.home => Icons.chair_rounded,
    ClueCategory.people => Icons.people_alt_rounded,
    ClueCategory.body => Icons.accessibility_new_rounded,
    ClueCategory.time => Icons.schedule_rounded,
    ClueCategory.place => Icons.place_rounded,
    ClueCategory.object => Icons.category_rounded,
    ClueCategory.color => Icons.palette_rounded,
    ClueCategory.action => Icons.directions_run_rounded,
  };
}

/// Small tinted badge shown beside a clue. Decorative only — the clue text
/// carries the meaning — so it's hidden from screen readers rather than
/// announced as an unlabelled icon between the number and the clue.
class ClueCategoryIcon extends StatelessWidget {
  const ClueCategoryIcon({super.key, required this.category, this.size = 18});

  final ClueCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Icon(
        clueCategoryIcon(category),
        size: size,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
