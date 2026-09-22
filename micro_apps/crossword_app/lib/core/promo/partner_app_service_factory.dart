import 'partner_app_service.dart';
import 'partner_app_service_factory_stub.dart'
    if (dart.library.io) 'partner_app_service_factory_io.dart'
    as impl;

/// Picks the right [PartnerAppService] for the current platform at
/// compile time, mirroring how ads, billing and consent are wired.
PartnerAppService createPartnerAppService() => impl.createPartnerAppService();
