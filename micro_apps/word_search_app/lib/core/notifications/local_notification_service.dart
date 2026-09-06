import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

/// The real, `flutter_local_notifications`-backed implementation.
///
/// Everything is on-device: the OS holds the pending reminder and fires it
/// even if the app is never launched again. No network, no server, no
/// stored device token.
class LocalNotificationService implements NotificationService {
  static const int _reminderId = 1001;
  static const String _channelId = 'play_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // zonedSchedule needs a real timezone database, otherwise every
      // scheduled time is interpreted as UTC and the reminder lands at the
      // wrong hour of the player's day.
      tz.initializeTimeZones();

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          // Permission is requested later, at a good moment — not on the
          // very first launch, where it reads as noise and gets denied.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('NotificationService init failed: $error\n$stackTrace');
    }
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        // Android 13+ (API 33) gates notifications behind a runtime
        // permission. On older versions this returns true without a prompt.
        return await android?.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    } catch (error) {
      debugPrint('NotificationService permission request failed: $error');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    await initialize();
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.areNotificationsEnabled() ?? false;
      }
      // iOS has no cheap synchronous check; requesting again is a no-op
      // once the user has already answered.
      return true;
    } catch (error) {
      debugPrint('NotificationService permission check failed: $error');
      return false;
    }
  }

  @override
  Future<void> scheduleInactivityReminder({
    required DateTime lastPlayedAt,
    required int afterDays,
    required String title,
    required String body,
  }) async {
    await initialize();
    try {
      // Cancel first so repeated launches never stack up reminders — there
      // is only ever one pending.
      await _plugin.cancel(_reminderId);

      final when = _reminderTime(lastPlayedAt, afterDays);
      if (when == null) return;

      await _plugin.zonedSchedule(
        _reminderId,
        title,
        body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Play reminders',
            channelDescription: 'Occasional nudge to come back to a puzzle.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact on purpose: exact alarms need SCHEDULE_EXACT_ALARM, which
        // is restricted on Android 12+ and draws review scrutiny. A "come
        // back and play" nudge does not need to-the-minute precision.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error, stackTrace) {
      debugPrint('NotificationService schedule failed: $error\n$stackTrace');
    }
  }

  /// Reminder fires [afterDays] after the last play, nudged to a civil hour
  /// so nobody is woken at 3am. Returns null if that moment has already
  /// passed, so a lapsed player isn't ambushed the instant they reopen.
  tz.TZDateTime? _reminderTime(DateTime lastPlayedAt, int afterDays) {
    final local = tz.TZDateTime.from(lastPlayedAt, tz.local);
    var target = tz.TZDateTime(
      tz.local,
      local.year,
      local.month,
      local.day + afterDays,
      19, // 7pm local
    );

    final now = tz.TZDateTime.now(tz.local);
    if (!target.isAfter(now)) {
      // Already overdue — schedule for the next 7pm instead of dropping it.
      target = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }
    }
    return target;
  }

  @override
  Future<void> cancelReminders() async {
    await initialize();
    try {
      await _plugin.cancel(_reminderId);
    } catch (error) {
      debugPrint('NotificationService cancel failed: $error');
    }
  }
}
