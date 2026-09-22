package com.baslt.word_search_app

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Hosts one method channel: "is this one package installed?".
///
/// It answers about exactly the package Dart passes, which is always
/// AppConfig.partnerAppPackageId, and that package is the only one this
/// app declares in its manifest <queries>. Android 11+ filters package
/// visibility by default, so anything else would come back "not found"
/// whether it is installed or not — the app genuinely cannot enumerate
/// what is on the device.
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.baslt.puzzles/partner_app"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPackageInstalled" -> {
                        val name = call.argument<String>("package")
                        result.success(name != null && isInstalled(name))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isInstalled(packageName: String): Boolean = try {
        packageManager.getPackageInfo(packageName, 0)
        true
    } catch (notFound: PackageManager.NameNotFoundException) {
        // Indistinguishable from "filtered out by <queries>", and that is
        // fine: both mean no unlock.
        false
    }
}
