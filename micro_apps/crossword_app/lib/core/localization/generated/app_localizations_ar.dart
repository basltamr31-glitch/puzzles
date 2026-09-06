// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'كلمات متقاطعة';

  @override
  String get onboardingTitle => 'كلمات متقاطعة';

  @override
  String get onboardingSubtitle =>
      'ألغاز كلمات متقاطعة قصيرة يمكنك لعبها في أي مكان وفي أي وقت — بدون حساب وبدون إنترنت.';

  @override
  String get continueButton => 'متابعة';

  @override
  String get chooseGameLanguageTitle => 'اختر لغة الألغاز';

  @override
  String get chooseGameLanguageSubtitle =>
      'هذه هي لغة الأدلة والإجابات. يمكنك تغييرها لاحقًا من الإعدادات.';

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
  String puzzlesSolvedLabel(int solved, int total) {
    return 'تم حل $solved من $total';
  }

  @override
  String get puzzleLockedMessage => 'أكمل اللغز السابق لفتح هذا اللغز.';

  @override
  String puzzleNumberLabel(String number) {
    return 'لغز $number';
  }

  @override
  String get noPuzzlesTitle => 'لا توجد ألغاز بعد';

  @override
  String get noPuzzlesMessage => 'ألغاز جديدة لهذا المستوى قادمة قريبًا.';

  @override
  String get acrossLabel => 'أفقي';

  @override
  String get downLabel => 'عمودي';

  @override
  String get previousClueTooltip => 'الدليل السابق';

  @override
  String get nextClueTooltip => 'الدليل التالي';

  @override
  String get hintButton => 'تلميح';

  @override
  String get hintConfirmTitle => 'استخدام تلميح؟';

  @override
  String get hintConfirmMessage => 'سيؤدي هذا إلى كشف الحرف في الخلية المحددة.';

  @override
  String get watchAdForHint => 'شاهد فيديو قصيرًا للحصول على تلميح';

  @override
  String get checkButton => 'تحقق';

  @override
  String get restartPuzzleButton => 'إعادة البدء';

  @override
  String get zoomInButton => 'تكبير';

  @override
  String get zoomOutButton => 'تصغير';

  @override
  String get restartConfirmTitle => 'إعادة بدء هذا اللغز؟';

  @override
  String get restartConfirmMessage => 'سيتم مسح تقدمك في هذا اللغز.';

  @override
  String get exitPuzzleConfirmTitle => 'مغادرة اللغز؟';

  @override
  String get exitPuzzleConfirmMessage => 'يتم حفظ تقدمك تلقائيًا.';

  @override
  String get puzzleCompletedTitle => 'اكتمل اللغز!';

  @override
  String get puzzleCompletedMessage => 'أحسنت! هل أنت مستعد للغز التالي؟';

  @override
  String get nextPuzzleButton => 'اللغز التالي';

  @override
  String get backToPuzzlesButton => 'العودة إلى الألغاز';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsUiLanguage => 'لغة التطبيق';

  @override
  String get settingsGameLanguage => 'لغة الألغاز';

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
}
