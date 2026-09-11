import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_controller.dart';

/// Named haptic intents rather than raw [HapticFeedback] calls at each
/// call site — this is what lets the *mapping* from action to intensity
/// live in one place (see [HapticService._impactFor]) instead of being
/// re-decided ad hoc every time a screen wants to buzz.
enum HapticIntent {
  /// Frequent, low-weight: cell selection, picking an item from a list.
  selection,

  /// A standard confirmation that isn't the primary action: a hint reveal.
  light,

  /// More consequential: an incorrect-answer check result.
  medium,

  /// "That move is not allowed" — a digit refused because it would
  /// duplicate one the cell can already see. Deliberately not an impact:
  /// a buzz is qualitatively different from the taps that confirm a
  /// successful action, so a rejection never feels like a soft success.
  rejected,

  /// Rare, major, celebratory: puzzle completion.
  heavy,
}

/// Thin wrapper around [HapticFeedback], gated by the user's Settings
/// toggle. Follows the same abstraction shape as Ads/Billing/Analytics —
/// feature code asks for an *intent*, never calls the platform API or
/// checks the setting directly.
abstract class HapticService {
  void play(HapticIntent intent);
}

class SystemHapticService implements HapticService {
  SystemHapticService(this._isEnabled);

  final bool Function() _isEnabled;

  @override
  void play(HapticIntent intent) {
    if (!_isEnabled()) return;
    switch (intent) {
      case HapticIntent.selection:
        HapticFeedback.selectionClick();
      case HapticIntent.light:
        HapticFeedback.lightImpact();
      case HapticIntent.medium:
        HapticFeedback.mediumImpact();
      case HapticIntent.rejected:
        HapticFeedback.vibrate();
      case HapticIntent.heavy:
        HapticFeedback.heavyImpact();
    }
  }
}

final hapticServiceProvider = Provider<HapticService>((ref) {
  return SystemHapticService(
    () => ref.read(settingsControllerProvider).vibrationEnabled,
  );
});
