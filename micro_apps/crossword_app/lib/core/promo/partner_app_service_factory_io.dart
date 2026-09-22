import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../app/app_config.dart';
import 'partner_app_service.dart';

/// Asks the platform whether one specific package is installed.
///
/// Android only. iOS deliberately falls through to [NoOpPartnerAppService]:
/// there is no way to ask about an arbitrary bundle id without declaring
/// it in `LSApplicationQueriesSchemes` *and* the other app owning a custom
/// URL scheme, which the companion app does not.
class MethodChannelPartnerAppService implements PartnerAppService {
  const MethodChannelPartnerAppService();

  /// Must match the channel name registered in `MainActivity.kt`.
  static const MethodChannel channel = MethodChannel(
    'com.baslt.puzzles/partner_app',
  );

  @override
  Future<bool> isInstalled() async {
    if (!Platform.isAndroid) return false;
    try {
      final installed = await channel.invokeMethod<bool>(
        'isPackageInstalled',
        {'package': AppConfig.partnerAppPackageId},
      );
      return installed ?? false;
    } on MissingPluginException {
      // The host side is missing — an older build, or a test harness with
      // no platform behind it. Silently "not installed" is right: this is
      // a bonus, and it must never be the reason something breaks.
      return false;
    } catch (error) {
      debugPrint('Partner app lookup failed: $error');
      return false;
    }
  }
}

PartnerAppService createPartnerAppService() =>
    const MethodChannelPartnerAppService();
