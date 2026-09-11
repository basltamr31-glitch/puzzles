import 'dart:io';

import 'local_notification_service.dart';
import 'notification_service.dart';

/// Android/iOS get the real implementation; other `dart:io` platforms
/// (Windows/Linux/macOS desktop) fall back to the no-op, since reminder
/// notifications only make sense on a phone here.
NotificationService createNotificationService() {
  if (Platform.isAndroid || Platform.isIOS) {
    return LocalNotificationService();
  }
  return const NoOpNotificationService();
}
