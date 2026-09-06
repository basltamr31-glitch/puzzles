import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/analytics/analytics_events.dart';
import 'core/analytics/analytics_service.dart';
import 'core/consent/consent_service.dart';
import 'core/errors/error_handler.dart';
import 'core/storage/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandling();

  final storage = await SharedPreferencesStorageService.create();

  // Built explicitly (rather than via ProviderScope's `overrides`) so
  // main() can perform one-time startup side effects — logging app_open
  // and kicking off the consent flow — exactly once, before the first
  // frame, using the same container the whole app then runs on.
  final container = ProviderContainer(
    overrides: [localStorageServiceProvider.overrideWithValue(storage)],
  );

  container.read(analyticsServiceProvider).logEvent(AnalyticsEvents.appOpen);
  // Fire-and-forget so startup is not blocked, but started here so the
  // consent form appears as early as possible. The ads SDK is NOT
  // initialized here: `adsReadyProvider` does that only after this
  // resolves, because Google requires the consent signal to exist before
  // the Mobile Ads SDK starts.
  unawaited(container.read(consentRequestProvider.future));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CrosswordApp(),
    ),
  );
}
