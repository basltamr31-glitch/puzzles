import 'billing_service.dart';
import 'billing_service_factory_stub.dart'
    if (dart.library.io) 'billing_service_factory_io.dart' as impl;

/// Picks the right [BillingService] for the current platform at compile
/// time — the same conditional-import approach used for ads, so
/// `in_app_purchase` never gets compiled into a web build.
BillingService createBillingService() => impl.createBillingService();
