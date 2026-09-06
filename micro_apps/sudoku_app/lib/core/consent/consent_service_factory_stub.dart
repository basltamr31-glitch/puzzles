import 'consent_service.dart';

/// Web/desktop fallback — UMP (bundled in `google_mobile_ads`) doesn't
/// support these targets, so consent is simply not required.
ConsentService createConsentService() => const NoOpConsentService();
