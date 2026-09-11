import 'ad_policy.dart';
import 'ad_service.dart';
import 'ad_service_factory_stub.dart'
    if (dart.library.io) 'ad_service_factory_io.dart' as impl;

/// Picks the right [AdService] for the current platform at compile time.
///
/// Using a conditional import (rather than an `if (kIsWeb)` runtime check)
/// means the web build never even compiles `google_mobile_ads_service.dart`
/// or its `google_mobile_ads` import — the package isn't web-compatible,
/// so this keeps the web target buildable without any runtime workaround.
AdService createAdService(AdPolicy policy) => impl.createAdService(policy);

/// Initializes the ad SDK. A no-op on platforms `google_mobile_ads`
/// doesn't support (web/desktop) — see the note on [createAdService].
Future<void> initializeAds() => impl.initializeAds();
