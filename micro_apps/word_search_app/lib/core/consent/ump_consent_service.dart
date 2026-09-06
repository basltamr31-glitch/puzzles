import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as ump;

import '../../app/app_config.dart';
import 'consent_service.dart';

/// The real, UMP-backed implementation of [ConsentService].
///
/// `requestConsentInfoUpdate` determines the user's region and whether a
/// consent form is legally required, and `loadAndShowConsentFormIfRequired`
/// shows one only when it actually is — for most users outside a
/// regulated region this whole flow completes near-instantly with nothing
/// shown. Once consent is obtained, the Mobile Ads SDK reads it
/// automatically for ad requests; nothing else in this app needs to know
/// about it.
class UmpConsentService implements ConsentService {
  ConsentStatus _status = ConsentStatus.unknown;
  bool _privacyOptionsRequired = false;

  @override
  ConsentStatus get currentStatus => _status;

  @override
  bool get isPrivacyOptionsFormAvailable => _privacyOptionsRequired;

  @override
  Future<ConsentStatus> requestConsentIfNeeded() async {
    final params = ump.ConsentRequestParameters(
      // Debug builds force EEA geography so the consent flow is actually
      // testable during development — real users get their real region.
      // Add your test device's advertising ID to `testIdentifiers` for a
      // more realistic debug run (see ConsentDebugSettings.testIdentifiers).
      consentDebugSettings: AppConfig.isDebug
          ? ump.ConsentDebugSettings(
              debugGeography: ump.DebugGeography.debugGeographyEea,
            )
          : null,
    );

    final updateCompleter = Completer<void>();
    ump.ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      updateCompleter.complete,
      (_) => updateCompleter.complete(),
    );
    await updateCompleter.future;

    if (await ump.ConsentInformation.instance.isConsentFormAvailable()) {
      await ump.ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    }

    final requirementStatus = await ump.ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    _privacyOptionsRequired =
        requirementStatus == ump.PrivacyOptionsRequirementStatus.required;

    final sdkStatus = await ump.ConsentInformation.instance.getConsentStatus();
    _status = _mapStatus(sdkStatus);
    return _status;
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    await ump.ConsentForm.showPrivacyOptionsForm((_) {});

    final requirementStatus = await ump.ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    _privacyOptionsRequired =
        requirementStatus == ump.PrivacyOptionsRequirementStatus.required;
    final sdkStatus = await ump.ConsentInformation.instance.getConsentStatus();
    _status = _mapStatus(sdkStatus);
  }

  ConsentStatus _mapStatus(ump.ConsentStatus status) {
    return switch (status) {
      ump.ConsentStatus.obtained => ConsentStatus.obtained,
      ump.ConsentStatus.required => ConsentStatus.required,
      ump.ConsentStatus.notRequired => ConsentStatus.notRequired,
      ump.ConsentStatus.unknown => ConsentStatus.unknown,
    };
  }
}
