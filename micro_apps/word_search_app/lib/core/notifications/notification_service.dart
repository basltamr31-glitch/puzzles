/// Abstraction over local, on-device reminder notifications.
///
/// Deliberately **local only** — nothing here contacts a server, stores a
/// device token, or needs an account. The device schedules the reminder
/// itself, which is why the app stays fully offline and the privacy policy
/// needs no new data-collection disclosure. Push notifications would be a
/// different thing entirely (Firebase project + backend + token storage)
/// and are not needed to remind someone to come back and play.
///
/// Same shape as [AdService]/[BillingService]/[SoundService]: feature code
/// only ever sees this interface, never the plugin.
abstract class NotificationService {
  /// Prepares the plugin and timezone database. Safe to call more than
  /// once; a no-op on platforms without notification support.
  Future<void> initialize();

  /// Asks the OS for permission. Android 13+ and iOS both require this,
  /// and a large share of users decline — callers must treat `false` as a
  /// normal outcome, not an error. Ask at a good moment (after a first
  /// win), never on cold start.
  Future<bool> requestPermission();

  /// True when the OS will actually deliver notifications right now.
  Future<bool> hasPermission();

  /// (Re)schedules the inactivity reminder [afterDays] from [lastPlayedAt].
  /// Replaces any previously scheduled reminder, so calling this on every
  /// launch keeps exactly one pending reminder — never a growing pile.
  Future<void> scheduleInactivityReminder({
    required DateTime lastPlayedAt,
    required int afterDays,
    required String title,
    required String body,
  });

  /// Removes any pending reminder — used when the player turns reminders
  /// off, so nothing fires after they opted out.
  Future<void> cancelReminders();
}

/// Backs web/desktop, where the plugin isn't supported, and tests.
class NoOpNotificationService implements NotificationService {
  const NoOpNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> scheduleInactivityReminder({
    required DateTime lastPlayedAt,
    required int afterDays,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelReminders() async {}
}
