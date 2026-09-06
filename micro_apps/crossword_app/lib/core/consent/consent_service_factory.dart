import 'consent_service.dart';
import 'consent_service_factory_stub.dart'
    if (dart.library.io) 'consent_service_factory_io.dart'
    as impl;

/// Picks the right [ConsentService] for the current platform at compile
/// time — the same conditional-import approach used for ads and billing.
ConsentService createConsentService() => impl.createConsentService();
