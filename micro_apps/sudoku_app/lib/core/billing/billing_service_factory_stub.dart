import 'billing_service.dart';

/// Web/desktop fallback — Play Billing/StoreKit purchases aren't
/// meaningful on these targets, so billing is simply absent.
BillingService createBillingService() => const NoOpBillingService();
