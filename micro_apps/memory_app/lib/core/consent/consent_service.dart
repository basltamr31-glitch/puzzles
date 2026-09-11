import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'consent_service_factory.dart';

/// Whether the user has granted personalized-advertising consent.
enum ConsentStatus { unknown, required, notRequired, obtained, denied }

/// Abstraction over advertising/privacy consent.
///
/// Deliberately not a custom-built consent UI — per spec §24 this uses the
/// ad SDK's own infrastructure: Google's User Messaging Platform, which
/// ships inside `google_mobile_ads` (already a dependency since Phase 6).
/// [UmpConsentService] is the real implementation on Android/iOS;
/// [NoOpConsentService] backs everything else.
abstract class ConsentService {
  /// Determines the user's region/regulatory requirements and shows a
  /// consent form if one is required (EEA/UK, or a regulated US state).
  /// Safe to call unconditionally — a no-op everywhere consent isn't
  /// required.
  Future<ConsentStatus> requestConsentIfNeeded();

  ConsentStatus get currentStatus;

  /// Whether Google requires a "privacy options" entry point somewhere in
  /// the app's Settings (spec §24/§25) — true for users in a regulated
  /// region who have already made a consent choice and may want to
  /// change it.
  bool get isPrivacyOptionsFormAvailable;

  /// Re-shows the consent choice UI so the user can change their mind.
  Future<void> showPrivacyOptionsForm();
}

class NoOpConsentService implements ConsentService {
  const NoOpConsentService();

  @override
  Future<ConsentStatus> requestConsentIfNeeded() async => ConsentStatus.notRequired;

  @override
  ConsentStatus get currentStatus => ConsentStatus.notRequired;

  @override
  bool get isPrivacyOptionsFormAvailable => false;

  @override
  Future<void> showPrivacyOptionsForm() async {}
}

final consentServiceProvider = Provider<ConsentService>((ref) => createConsentService());

/// Kicks off the consent flow once, cached app-wide like any other
/// [FutureProvider] — watched eagerly from [CrosswordApp] so it starts at
/// launch, and watched reactively from Settings to show/hide the privacy
/// options entry point once it resolves.
final consentRequestProvider = FutureProvider<ConsentStatus>((ref) {
  return ref.watch(consentServiceProvider).requestConsentIfNeeded();
});
