import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';
import 'notification_service.dart';
import 'notification_service_factory.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return createNotificationService();
});

/// How long a player must be away before the reminder fires.
const int reminderAfterDays = 2;

/// Whether a player who has never touched the setting gets reminders.
///
/// On by default. Settings turns them off and [setEnabled] records that,
/// so this only ever applies to someone who has not decided for
/// themselves — an existing player's choice is never overwritten.
const bool defaultRemindersEnabled = true;

/// Owns the "remind me to play" preference and keeps the single scheduled
/// reminder in sync with it.
///
/// The default is on, but it is never applied silently: on Android 13+ a
/// reminder cannot be delivered at all without POST_NOTIFICATIONS, so
/// [applyDefaultOptIn] asks once and stores the answer. A switch reading
/// "on" that the OS would never deliver is worse than one honestly off.
class ReminderController extends Notifier<bool> {
  @override
  bool build() {
    final storage = ref.watch(localStorageServiceProvider);
    return storage.getBool(StorageKeys.remindersEnabled) ??
        defaultRemindersEnabled;
  }

  /// Guards against the app widget's post-frame callback calling
  /// [applyDefaultOptIn] again while the permission dialog is still open.
  bool _optInInFlight = false;

  /// Turning reminders on asks for OS permission first. If the player
  /// declines, the setting stays off rather than silently pretending to be
  /// on — the switch reflects what will actually happen.
  Future<bool> setEnabled(bool value) async {
    final storage = ref.read(localStorageServiceProvider);
    final notifications = ref.read(notificationServiceProvider);

    if (!value) {
      await storage.setBool(StorageKeys.remindersEnabled, false);
      await notifications.cancelReminders();
      state = false;
      return false;
    }

    final granted = await notifications.requestPermission();
    await storage.setBool(StorageKeys.remindersEnabled, granted);
    state = granted;
    if (granted) await rescheduleIfEnabled();
    return granted;
  }

  /// Applies [defaultRemindersEnabled] once per install, by asking for the
  /// permission the default needs before claiming to be on.
  ///
  /// Returns immediately once any answer is stored — granted, denied, or
  /// set later from the switch. That is what keeps this from re-prompting
  /// on every launch, and what stops an upgrading player who had
  /// deliberately turned reminders off from having them turned back on.
  Future<void> applyDefaultOptIn() async {
    if (!defaultRemindersEnabled || _optInInFlight) return;

    final storage = ref.read(localStorageServiceProvider);
    if (storage.getBool(StorageKeys.remindersEnabled) != null) return;

    _optInInFlight = true;
    try {
      final notifications = ref.read(notificationServiceProvider);
      final granted = await notifications.requestPermission();
      await storage.setBool(StorageKeys.remindersEnabled, granted);
      state = granted;
      if (granted) await rescheduleIfEnabled();
    } finally {
      _optInInFlight = false;
    }
  }

  /// Records that a puzzle was just opened and pushes the reminder back.
  /// Called from gameplay, so an active player is never nagged.
  Future<void> recordPlayed() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setInt(
      StorageKeys.lastPlayedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    await rescheduleIfEnabled();
  }

  /// Re-arms the single pending reminder. Safe and cheap to call on every
  /// launch; scheduling replaces rather than accumulates.
  Future<void> rescheduleIfEnabled() async {
    if (!state) return;
    final storage = ref.read(localStorageServiceProvider);
    final notifications = ref.read(notificationServiceProvider);

    final millis = storage.getInt(StorageKeys.lastPlayedAt);
    final lastPlayed = millis == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(millis);

    final strings = ref.read(reminderStringsProvider);
    if (strings == null) return;

    await notifications.scheduleInactivityReminder(
      lastPlayedAt: lastPlayed,
      afterDays: reminderAfterDays,
      title: strings.title,
      body: strings.body,
    );
  }
}

final reminderControllerProvider = NotifierProvider<ReminderController, bool>(
  ReminderController.new,
);

/// Localized reminder text.
///
/// The notification is scheduled by the OS and may fire long after the app
/// is gone from memory, so its text has to be baked in at schedule time —
/// there is no `BuildContext` to localize against when it actually
/// appears. [WordSearchApp] publishes the current translations here.
class ReminderStrings {
  const ReminderStrings({required this.title, required this.body});

  final String title;
  final String body;
}

class ReminderStringsController extends Notifier<ReminderStrings?> {
  @override
  ReminderStrings? build() => null;

  void set(ReminderStrings strings) => state = strings;
}

final reminderStringsProvider =
    NotifierProvider<ReminderStringsController, ReminderStrings?>(
      ReminderStringsController.new,
    );
