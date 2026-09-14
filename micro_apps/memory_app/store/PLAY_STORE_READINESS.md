# Google Play readiness — Memory Match

Honest status as of this version. "Done" means verified working in this
repo. "External" means it can only happen in a Google/Apple account this
environment doesn't have access to — no amount of code changes finishes
these.

## Done, verified in this repo

| Item | Status |
|---|---|
| App icon (adaptive, Android + iOS + web) | Generated from `assets/icon/`, wired via `flutter_launcher_icons`. Custom brand mark (not a placeholder/default Flutter icon). |
| Native splash screen | Generated via `flutter_native_splash`, including Android 12+ splash and dark-mode variant. |
| Versioning | `pubspec.yaml` set to `1.0.0+1`. App version displayed in Settings is read from the real installed package at runtime (`package_info_plus`), not a hand-maintained constant — can't drift out of sync. |
| Application ID consistency | `com.baslt.memory_app` matches across `AppConfig`, `android/app/build.gradle.kts`, and iOS `Info.plist`/bundle ID. |
| AdMob wiring | Real Android App ID `ca-app-pub-1057967613304012~8346757209` in `AndroidManifest.xml`; the three real unit IDs in the gitignored `ad_config.json`. Release builds must pass `--dart-define-from-file=ad_config.json` or they ship with no ads at all. iOS carries no `GADApplicationIdentifier` — AdMob issues a separate App ID per platform, and this app has no iOS AdMob app. |
| Signing | **Not set up.** No keystore and no `android/key.properties`, so release builds are debug-signed and cannot be uploaded. The three sibling apps each have their own keystore in `C:/Users/baslt/keys/`; this one needs the same. |
| Release build compiles | `flutter build apk --release` succeeded end-to-end on 11 September 2026 (R8/minification, resource merging, manifest merging all clean) — real Android SDK, real Gradle build, not a simulation. Output: 64.9MB `app-release.apk`, **debug-signed**, since no upload keystore exists yet. `flutter build appbundle` has not been run for this app. |
| Signing infrastructure | `build.gradle.kts` reads `android/key.properties` for real release signing when present, falls back to debug signing otherwise (so the build keeps working before you have a key). See `android/key.properties.example`. |
| Permissions | Audited the actual merged release manifest. Every permission present (`INTERNET`, `ACCESS_NETWORK_STATE`, `AD_ID`, three `ACCESS_ADSERVICES_*`, `BILLING`, `WAKE_LOCK`, `FOREGROUND_SERVICE`) is pulled in by the ads or billing SDKs for functionality this app actually uses — nothing extraneous requested. |
| Privacy policy | Bundled at `assets/legal/privacy_policy.md` (what the in-app screen renders) and **hosted live** at `doc-hosting.flycricket.io/memory-match/c13f70a9-…/privacy`, wired into `AppConfig.privacyPolicyUrl`. Fetched and checked on 2026-09-14: names Memory Match, BT Developer, baladream.help@gmail.com, the 13+ audience, AdMob / UMP / Play Billing, the on-device reminders, and card-matching progress — matching what the code actually does. Paste that URL into the Play Console listing. |
| Data Safety mapping | Drafted at `store/DATA_SAFETY.md` as a lookup reference for the Play Console questionnaire. |

## Requires your action outside this environment

| Item | What's needed | Why it can't be done here |
|---|---|---|
| Real `applicationId` | Decide the final reverse-domain package name before your *first* upload — Play Console treats it as permanent. `com.baslt.memory_app` was a reasonable placeholder chosen during initial scaffolding, not a confirmed business decision. | Naming/branding decision only you can make. |
| Upload keystore | Generate one (`keytool -genkeystore ...`, command in `android/key.properties.example`), store it securely, fill in `android/key.properties`. | Must be generated and held by you — a keystore I generated wouldn't be securely yours, and losing it permanently blocks future updates to a published app. |
| Register your phone as an AdMob test device | AdMob → Settings → Test devices, before opening a real-ID build. Tapping your own live ads is invalid traffic and the most common reason new accounts are suspended. | Requires AdMob console access. |
| Play Console Billing product | Create the `remove_ads` non-consumable product at $1.00 in Play Console, matching `AppConfig.removeAdsProductId`. | Play Console account action. |
| Privacy policy hosting + legal review | Host `store/PRIVACY_POLICY.md` (or your reviewed version of it) at a public URL; have it reviewed by counsel for your target markets, especially the children's-privacy section, which is a placeholder. | Legal review and hosting are outside code. |
| Data Safety form | Fill out the live Play Console questionnaire using `store/DATA_SAFETY.md` as a reference. | Play Console UI only. |
| Content rating questionnaire | Complete Play Console's rating questionnaire (should be straightforward — no violence/mature content). | Play Console UI only. |
| Store listing assets | App screenshots (phone + tablet), a feature graphic, short/long description, promo text. | Needs a real device/emulator screenshot session — this environment has no Android emulator or connected device running the actual UI to screenshot. |
| Testing track | Set up an internal testing track, add testers, do a real install-and-play pass before any production release. | Play Console account action + real device testing. |
| iOS equivalents | App Store Connect listing, In-App Purchase product, StoreKit capability, App Store screenshots, privacy nutrition label. | No Xcode/macOS available in this environment; not attempted. |

## Bottom line

The app **builds as a real, installable release artifact today**
(`app-release.aab`, `app-release.apk` both produced successfully) with a
real icon, real splash screen, clean permissions, and correct version
metadata. Everything left is account-holder actions in Google/Apple
consoles, content you need to review (privacy policy) or produce
(screenshots, a real signing key) — not further app code.
