import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstraction over product analytics. Only anonymous, product-level
/// events are ever logged through this — no PII, per spec §23.
///
/// A real backend (e.g. Firebase Analytics) is wired in during Phase 8,
/// once consent handling exists. Until then [ConsoleAnalyticsService]
/// keeps every call site in place and testable.
abstract class AnalyticsService {
  void logEvent(String name, [Map<String, Object?> parameters]);
}

class ConsoleAnalyticsService implements AnalyticsService {
  const ConsoleAnalyticsService();

  @override
  void logEvent(String name, [Map<String, Object?> parameters = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $name $parameters');
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const ConsoleAnalyticsService(),
);
