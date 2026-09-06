import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The real, installed app version/build number, read from the platform
/// at runtime rather than duplicated as a hardcoded constant in
/// [AppConfig] — a hand-maintained copy would silently drift out of sync
/// with the version actually declared in pubspec.yaml.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
