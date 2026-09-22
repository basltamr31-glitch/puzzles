import 'partner_app_service.dart';

/// Web/desktop: there is no package manager to ask.
PartnerAppService createPartnerAppService() => const NoOpPartnerAppService();
