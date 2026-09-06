import 'notification_service.dart';
import 'notification_service_factory_stub.dart'
    if (dart.library.io) 'notification_service_factory_io.dart' as impl;

/// Picks the right [NotificationService] for the current platform at
/// compile time — the same conditional-import approach the ad and billing
/// factories use, so the web build never compiles
/// `flutter_local_notifications` (which it doesn't support).
NotificationService createNotificationService() => impl.createNotificationService();
