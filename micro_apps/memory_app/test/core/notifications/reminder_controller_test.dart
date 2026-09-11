import 'package:memory_app/core/notifications/notification_service.dart';
import 'package:memory_app/core/notifications/reminder_controller.dart';
import 'package:memory_app/core/storage/local_storage_service.dart';
import 'package:memory_app/core/storage/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryStorage implements LocalStorageService {
  final Map<String, Object> values = {};

  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  Future<bool> setBool(String key, bool value) async {
    values[key] = value;
    return true;
  }

  @override
  String? getString(String key) => values[key] as String?;
  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => values[key] as int?;
  @override
  Future<bool> setInt(String key, int value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

class _FakeNotificationService implements NotificationService {
  bool permissionGranted = true;
  int scheduleCount = 0;
  int cancelCount = 0;
  int permissionRequests = 0;
  DateTime? lastScheduledFrom;
  String? lastTitle;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<void> scheduleInactivityReminder({
    required DateTime lastPlayedAt,
    required int afterDays,
    required String title,
    required String body,
  }) async {
    scheduleCount++;
    lastScheduledFrom = lastPlayedAt;
    lastTitle = title;
  }

  @override
  Future<void> cancelReminders() async {
    cancelCount++;
  }
}

void main() {
  late _InMemoryStorage storage;
  late _FakeNotificationService notifications;
  late ProviderContainer container;

  ProviderContainer build() {
    return ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
  }

  setUp(() {
    storage = _InMemoryStorage();
    notifications = _FakeNotificationService();
    container = build();
    // The scheduled text is captured at schedule time because the OS may
    // fire it when no localized context exists.
    container.read(reminderStringsProvider.notifier).set(
          const ReminderStrings(title: 'A puzzle is waiting', body: 'Solve one.'),
        );
  });

  tearDown(() => container.dispose());

  test('reminders are off by default', () {
    expect(container.read(reminderControllerProvider), isFalse);
  });

  test('enabling asks for OS permission and schedules once granted', () async {
    final granted =
        await container.read(reminderControllerProvider.notifier).setEnabled(true);

    expect(granted, isTrue);
    expect(container.read(reminderControllerProvider), isTrue);
    expect(notifications.permissionRequests, 1);
    expect(notifications.scheduleCount, greaterThan(0));
    expect(storage.values[StorageKeys.remindersEnabled], isTrue);
  });

  test('a declined permission leaves the setting off rather than pretending', () async {
    notifications.permissionGranted = false;

    final granted =
        await container.read(reminderControllerProvider.notifier).setEnabled(true);

    expect(granted, isFalse);
    expect(container.read(reminderControllerProvider), isFalse,
        reason: 'the switch must reflect what will actually happen');
    expect(notifications.scheduleCount, 0);
  });

  test('disabling cancels the pending reminder', () async {
    final controller = container.read(reminderControllerProvider.notifier);
    await controller.setEnabled(true);

    await controller.setEnabled(false);

    expect(container.read(reminderControllerProvider), isFalse);
    expect(notifications.cancelCount, greaterThan(0));
    expect(storage.values[StorageKeys.remindersEnabled], isFalse);
  });

  test('playing records a timestamp and pushes the reminder back', () async {
    final controller = container.read(reminderControllerProvider.notifier);
    await controller.setEnabled(true);
    final before = notifications.scheduleCount;

    await controller.recordPlayed();

    expect(storage.values[StorageKeys.lastPlayedAt], isA<int>());
    expect(notifications.scheduleCount, greaterThan(before));
    expect(notifications.lastScheduledFrom, isNotNull);
  });

  test('an active player is never scheduled from a stale timestamp', () async {
    final controller = container.read(reminderControllerProvider.notifier);
    await controller.setEnabled(true);

    // Simulate having played long ago, then playing again now.
    await storage.setInt(
      StorageKeys.lastPlayedAt,
      DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
    );
    await controller.recordPlayed();

    final scheduledFrom = notifications.lastScheduledFrom!;
    expect(
      DateTime.now().difference(scheduledFrom).inMinutes,
      lessThan(5),
      reason: 'the reminder must be measured from the latest play',
    );
  });

  test('nothing is scheduled while reminders are disabled', () async {
    await container.read(reminderControllerProvider.notifier).recordPlayed();
    expect(notifications.scheduleCount, 0);
  });

  test('a stored preference is restored on a fresh launch', () async {
    await storage.setBool(StorageKeys.remindersEnabled, true);
    final fresh = build();
    addTearDown(fresh.dispose);

    expect(fresh.read(reminderControllerProvider), isTrue);
  });
}
