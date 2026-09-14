import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/sound_service.dart';
import '../core/errors/error_handler.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/localization/locale_controller.dart';
import '../core/localization/supported_locales.dart';
import '../core/notifications/reminder_controller.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/settings/settings_controller.dart';
import 'app_config.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

/// Root widget. Composes the theme, localization, and router providers
/// built up across `app/` and `core/` into a single `MaterialApp.router`.
/// RTL follows automatically from [locale] via Flutter's own
/// `Localizations`/`Directionality` resolution — no manual direction
/// handling needed here.
///
/// Also owns background-music lifecycle: resumes the player's chosen
/// track on launch (state itself is passive — nothing else in the
/// provider graph triggers actual playback as a side effect of being
/// read), and pauses/resumes it as the app leaves/re-enters the
/// foreground so music doesn't keep playing over other apps.
class SudokuApp extends ConsumerStatefulWidget {
  const SudokuApp({super.key});

  @override
  ConsumerState<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends ConsumerState<SudokuApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final track = ref.read(settingsControllerProvider).musicTrack;
      if (track != MusicTrack.off) {
        ref.read(soundServiceProvider).playMusic(track);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final soundService = ref.read(soundServiceProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        soundService.pauseMusic();
      case AppLifecycleState.resumed:
        soundService.resumeMusic();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return AppErrorBoundary(
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: SupportedLocales.all,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        builder: (context, child) {
          // The reminder fires long after this app is gone from memory, so
          // its text must be captured now, while a localized context still
          // exists. Re-published on every build so switching UI language
          // re-arms the reminder in the new language.
          final l10n = AppLocalizations.of(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(reminderStringsProvider.notifier).set(
                  ReminderStrings(
                    title: l10n.reminderTitle,
                    body: l10n.reminderBody,
                  ),
                );
            final reminders = ref.read(reminderControllerProvider.notifier);
            // Only past the first-launch flow: a notification permission
            // dialog thrown over the welcome screen is the one players
            // deny without reading.
            if (ref.read(onboardingControllerProvider)) {
              reminders.applyDefaultOptIn();
            }
            reminders.rescheduleIfEnabled();
          });
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
