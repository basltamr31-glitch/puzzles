import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';

/// Tracks whether the first-launch flow (welcome → difficulty) has been
/// completed. Read by the router's redirect guard so
/// a returning user always lands directly on the puzzle list.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() {
    final storage = ref.watch(localStorageServiceProvider);
    final stored = storage.getBool(StorageKeys.onboardingComplete);
    if (stored == null) {
      ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.firstLaunch);
    }
    return stored ?? false;
  }

  Future<void> complete() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setBool(StorageKeys.onboardingComplete, true);
    state = true;
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
