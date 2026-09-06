/// Canonical analytics event names. Referencing these constants instead of
/// inline strings prevents silent typos from splitting one event into two
/// in the analytics backend.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const String appOpen = 'app_open';
  static const String firstLaunch = 'first_launch';
  static const String uiLanguageSelected = 'ui_language_selected';
  static const String gameLanguageSelected = 'game_language_selected';
  static const String difficultySelected = 'difficulty_selected';
  static const String puzzleStarted = 'puzzle_started';
  static const String puzzleCompleted = 'puzzle_completed';
  static const String hintUsed = 'hint_used';
  static const String rewardedAdCompleted = 'rewarded_ad_completed';
  static const String removeAdsPurchaseStarted = 'remove_ads_purchase_started';
  static const String removeAdsPurchaseCompleted =
      'remove_ads_purchase_completed';
}
