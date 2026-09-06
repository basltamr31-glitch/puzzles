import 'package:word_search_app/core/analytics/analytics_service.dart';

/// In-memory [AnalyticsService] that records every logged event, so tests
/// can assert on exactly what would have been sent without needing a real
/// analytics backend.
class FakeAnalyticsService implements AnalyticsService {
  final List<({String name, Map<String, Object?> parameters})> events = [];

  @override
  void logEvent(String name, [Map<String, Object?> parameters = const {}]) {
    events.add((name: name, parameters: parameters));
  }

  bool hasEvent(String name) => events.any((e) => e.name == name);

  int countOf(String name) => events.where((e) => e.name == name).length;
}
