// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Memory Match';

  @override
  String get onboardingTitle => 'Memory Match';

  @override
  String get onboardingSubtitle =>
      'اقلب البطاقات واعثر على كل الأزواج — 400 لوحة، بدون حساب وبدون إنترنت.';

  @override
  String get continueButton => 'متابعة';

  @override
  String get chooseDifficultyTitle => 'اختر مستوى الصعوبة';

  @override
  String get chooseDifficultySubtitle => 'يمكنك لعب أي مستوى صعوبة في أي وقت.';

  @override
  String get difficultyEasy => 'سهل';

  @override
  String get difficultyMedium => 'متوسط';

  @override
  String get difficultyHard => 'صعب';

  @override
  String get difficultyExpert => 'خبير';

  @override
  String puzzleListTitle(String difficulty) {
    return 'ألغاز $difficulty';
  }

  @override
  String get puzzleStatusCompleted => 'مكتمل';

  @override
  String get puzzleStatusInProgress => 'قيد التقدم';

  @override
  String get puzzleStatusNotStarted => 'لم يبدأ';

  @override
  String get puzzleStatusLocked => 'مقفل';

  @override
  String get puzzleLockedMessage => 'أكمل اللغز السابق لفتح هذا اللغز.';

  @override
  String puzzleNumberLabel(String number) {
    return 'لغز $number';
  }

  @override
  String puzzlesSolvedLabel(int solved, int total) {
    return 'تم حل $solved من $total';
  }

  @override
  String get noPuzzlesTitle => 'لا توجد ألغاز بعد';

  @override
  String get noPuzzlesMessage => 'ألغاز جديدة لهذا المستوى قادمة قريبًا.';

  @override
  String cellSemanticLabel(int row, int column) {
    return 'الصف $row، العمود $column';
  }

  @override
  String get hintButton => 'تلميح';

  @override
  String get hintConfirmTitle => 'استخدام تلميح؟';

  @override
  String get hintConfirmMessage => 'سيتم مطابقة زوج واحد نيابةً عنك.';

  @override
  String get watchAdForHint => 'شاهد فيديو قصيرًا للحصول على تلميح';

  @override
  String get restartPuzzleButton => 'إعادة البدء';

  @override
  String get restartConfirmTitle => 'إعادة بدء هذا اللغز؟';

  @override
  String get restartConfirmMessage => 'سيتم مسح تقدمك في هذا اللغز.';

  @override
  String get puzzleCompletedTitle => 'اكتمل اللغز!';

  @override
  String puzzleCompletedTime(String time) {
    return 'تم الحل في $time';
  }

  @override
  String get nextPuzzleButton => 'اللغز التالي';

  @override
  String get backToPuzzlesButton => 'العودة إلى الألغاز';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsUiLanguage => 'لغة التطبيق';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get themeModeSystem => 'النظام';

  @override
  String get themeModeLight => 'فاتح';

  @override
  String get themeModeDark => 'داكن';

  @override
  String get settingsSound => 'المؤثرات الصوتية';

  @override
  String get settingsVibration => 'الاهتزاز';

  @override
  String get settingsMusic => 'الموسيقى الخلفية';

  @override
  String get musicTrackOff => 'إيقاف';

  @override
  String get musicTrackCalm => 'هادئة';

  @override
  String get musicTrackGentle => 'لطيفة';

  @override
  String get musicTrackUplifting => 'منعشة';

  @override
  String get musicTrackFocus => 'تركيز';

  @override
  String get musicTrackBright => 'مشرقة';

  @override
  String get musicTrackNight => 'ليلية';

  @override
  String get settingsReminders => 'تذكير باللعب';

  @override
  String get remindersPermissionDenied =>
      'الإشعارات معطّلة لهذا التطبيق. يمكنك تفعيلها من إعدادات جهازك.';

  @override
  String get reminderTitle => 'هناك لغز في انتظارك';

  @override
  String get reminderBody => 'خذ استراحة وحلّ لغزاً — لن يستغرق سوى بضع دقائق.';

  @override
  String get settingsTestSound => 'اختبار الصوت';

  @override
  String get soundTestOk => 'تم تشغيل الصوت.';

  @override
  String soundTestFailed(String error) {
    return 'فشل تشغيل الصوت: $error';
  }

  @override
  String get settingsRemoveAds => 'إزالة الإعلانات';

  @override
  String get settingsRestorePurchases => 'استعادة المشتريات';

  @override
  String get settingsAdPrivacyOptions => 'خيارات خصوصية الإعلانات';

  @override
  String get settingsPrivacy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyViewOnline => 'عرض عبر الإنترنت';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get removeAdsTitle => 'إزالة الإعلانات';

  @override
  String get removeAdsDescription =>
      'استمتع بكل لغز بدون إعلانات بانر أو إعلانات بينية — إلى الأبد، بعملية شراء واحدة.';

  @override
  String get removeAdsPrice => '١٫٠٠ دولار';

  @override
  String get removeAdsPurchaseButton => 'شراء — ١٫٠٠ دولار';

  @override
  String removeAdsPurchaseButtonWithPrice(String price) {
    return 'شراء — $price';
  }

  @override
  String get musicToggleOn => 'تشغيل الموسيقى';

  @override
  String get musicToggleOff => 'إيقاف الموسيقى';

  @override
  String get settingsDeveloper => 'المطوّر';

  @override
  String get settingsDeveloperName => 'BT developer';

  @override
  String get settingsCopyright => '© BaLa Dream';

  @override
  String get removeAdsAlreadyOwned =>
      'أنت تملك بالفعل إزالة الإعلانات. شكرًا لدعمك!';

  @override
  String get partnerUnlockTitle => 'أو أزل لافتات الإعلانات مجانًا';

  @override
  String partnerUnlockDescription(String app) {
    return 'ثبّت $app وستختفي لافتات الإعلانات نهائيًا. أما التلميحات والحيوات الإضافية فما زالت تتطلب مشاهدة فيديو قصير.';
  }

  @override
  String partnerUnlockButton(String app) {
    return 'احصل على $app';
  }

  @override
  String partnerUnlockActive(String app) {
    return 'تم إيقاف لافتات الإعلانات — شكرًا لتثبيتك $app.';
  }

  @override
  String get purchasePending => 'جارٍ معالجة عملية الشراء…';

  @override
  String get purchaseError =>
      'تعذر إتمام عملية الشراء. يرجى المحاولة مرة أخرى.';

  @override
  String get purchaseStoreUnavailable =>
      'المتجر غير متاح حاليًا. تأكد من تسجيل الدخول ثم حاول مرة أخرى.';

  @override
  String get purchaseProductUnavailable =>
      'هذا الشراء غير متاح حاليًا. يرجى المحاولة لاحقًا.';

  @override
  String get purchaseCancelled => 'تم إلغاء عملية الشراء.';

  @override
  String get restoreSuccess => 'تمت استعادة مشترياتك.';

  @override
  String get restoreNothingFound => 'لم يتم العثور على مشتريات سابقة.';

  @override
  String get errorGeneric => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get errorNoInternet =>
      'أنت غير متصل بالإنترنت. تتطلب هذه الميزة اتصالاً بالإنترنت.';

  @override
  String get errorAdUnavailable =>
      'لا يوجد إعلان متاح حاليًا. يرجى المحاولة لاحقًا.';

  @override
  String get errorPuzzleMissing => 'تعذر تحميل هذا اللغز.';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get okButton => 'موافق';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get mistakesLabel => 'الأخطاء';

  @override
  String livesRemaining(int remaining, int max) {
    return '$remaining من $max محاولات متبقية';
  }

  @override
  String get outOfLivesTitle => 'انتهت المحاولات';

  @override
  String outOfLivesMessage(int max) {
    return 'لقد ارتكبت $max أخطاء. أعد بدء هذا اللغز للمحاولة مرة أخرى.';
  }

  @override
  String get outOfLivesTryAgain => 'حاول مرة أخرى';

  @override
  String outOfLivesMessageRevive(int max) {
    return 'لقد ارتكبت $max أخطاء. يمكنك الحصول على حياة إضافية أو إعادة بدء هذا اللغز.';
  }

  @override
  String get outOfLivesWatchAd => 'شاهد فيديو للحصول على حياة إضافية';

  @override
  String get outOfLivesExtraLife => 'احصل على حياة إضافية';

  @override
  String get rewardHeadlineFlawless => 'بلا أخطاء!';

  @override
  String get rewardHeadlineGreat => 'حل رائع!';

  @override
  String get rewardHeadlineSolved => 'تم الحل!';

  @override
  String get rewardNoMistakes => 'بدون أخطاء';

  @override
  String rewardMistakesMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أخطاء',
      two: 'خطآن',
      one: 'خطأ واحد',
    );
    return '$_temp0';
  }

  @override
  String rewardStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days أيام متتالية',
      two: 'يومان متتاليان',
      one: 'يوم واحد متتالٍ',
    );
    return '$_temp0';
  }

  @override
  String rewardBestStreak(int days) {
    return 'أفضل سلسلة جديدة: $days';
  }

  @override
  String rewardBadgeUnlocked(String badge) {
    return 'شارة جديدة: $badge';
  }

  @override
  String rewardStarsEarned(int stars, int max) {
    return '$stars من $max نجوم';
  }

  @override
  String get achievementsTitle => 'التقدم';

  @override
  String get achievementsStreakLabel => 'أيام متتالية';

  @override
  String get achievementsSolvedLabel => 'ألغاز محلولة';

  @override
  String get achievementsStarsLabel => 'النجوم المكتسبة';

  @override
  String get achievementsBestStreakLabel => 'أفضل سلسلة';

  @override
  String get achievementsBadgesTitle => 'الشارات';

  @override
  String achievementsEarnedSemantics(String badge) {
    return '$badge، تم الحصول عليها';
  }

  @override
  String achievementsLockedSemantics(String badge) {
    return '$badge، مقفلة';
  }

  @override
  String get achievementFirstSolveTitle => 'أول حل';

  @override
  String get achievementFirstSolveDescription => 'أكمل أول لغز لك';

  @override
  String get achievementTenSolvesTitle => 'بداية قوية';

  @override
  String get achievementTenSolvesDescription => 'أكمل 10 ألغاز';

  @override
  String get achievementFiftySolvesTitle => 'لاعب منتظم';

  @override
  String get achievementFiftySolvesDescription => 'أكمل 50 لغزًا';

  @override
  String get achievementHundredSolvesTitle => 'مئة لغز';

  @override
  String get achievementHundredSolvesDescription => 'أكمل 100 لغز';

  @override
  String get achievementFlawlessFiveTitle => 'إتقان';

  @override
  String get achievementFlawlessFiveDescription =>
      'احصل على ثلاث نجوم في 5 ألغاز';

  @override
  String get achievementWeekStreakTitle => 'سبعة أيام';

  @override
  String get achievementWeekStreakDescription => 'العب 7 أيام متتالية';

  @override
  String puzzlePairsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count زوج',
      many: '$count زوجًا',
      few: '$count أزواج',
      two: 'زوجان',
      one: 'زوج واحد',
    );
    return '$_temp0';
  }

  @override
  String puzzleThemedPairsLabel(String pairs, String theme) {
    return '$pairs · $theme';
  }

  @override
  String pairsFoundLabel(String found, String total) {
    return 'الأزواج $found/$total';
  }

  @override
  String movesLabel(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves حركة',
      many: '$moves حركة',
      few: '$moves حركات',
      two: 'حركتان',
      one: 'حركة واحدة',
    );
    return '$_temp0';
  }

  @override
  String puzzleCompletedMoves(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: 'في $moves حركة',
      many: 'في $moves حركة',
      few: 'في $moves حركات',
      two: 'في حركتين',
      one: 'في حركة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get cardFaceDownLabel => 'مقلوبة';

  @override
  String cardFaceUpLabel(String symbol) {
    return 'تُظهر $symbol';
  }

  @override
  String cardMatchedLabel(String symbol) {
    return '$symbol، تم العثور على الزوج';
  }

  @override
  String get themeAnimals => 'حيوانات';

  @override
  String get themeFood => 'طعام';

  @override
  String get themeNature => 'طبيعة';

  @override
  String get themeTravel => 'سفر';

  @override
  String get themeSports => 'رياضة';

  @override
  String get themeFaces => 'وجوه';

  @override
  String get themeParty => 'حفلة';

  @override
  String get themeObjects => 'أشياء';
}
