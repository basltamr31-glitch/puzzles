import 'notification_service.dart';

/// Web/desktop fallback — see [createNotificationService] in the
/// non-stub factory for why this exists.
NotificationService createNotificationService() =>
    const NoOpNotificationService();
