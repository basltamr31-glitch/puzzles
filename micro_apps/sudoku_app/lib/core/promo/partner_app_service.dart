/// Whether the companion app this one cross-promotes is on the device.
///
/// Deliberately the *only* thing this abstraction can answer. It cannot
/// list installed packages and does not want to: Android 11+ filters
/// package visibility by default, and the manifest grants visibility of
/// exactly one package — see the `<queries>` entry naming
/// [AppConfig.partnerAppPackageId]. Anything broader would be a privacy
/// change and a Play policy question, not a feature.
abstract class PartnerAppService {
  /// True when the partner app is installed right now.
  ///
  /// Must never throw: every failure path — wrong platform, missing
  /// plugin, a platform exception — resolves to `false`, which simply
  /// means "no unlock", the same as not having the app.
  Future<bool> isInstalled();
}

/// Used on every platform except Android. iOS cannot answer this question
/// for an arbitrary bundle id, and web/desktop have no Play Store at all,
/// so the honest answer everywhere else is "no".
class NoOpPartnerAppService implements PartnerAppService {
  const NoOpPartnerAppService();

  @override
  Future<bool> isInstalled() async => false;
}
