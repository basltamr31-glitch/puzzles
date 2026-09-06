# Google Play readiness — Word Search

Honest status as of this version. "Done" means verified working in this
repo. "External" means it can only happen in a Google/Apple account this
environment doesn't have access to — no amount of code changes finishes
these.

## Done, verified in this repo

| Item | Status |
|---|---|
| App icon (adaptive, Android + iOS + web) | Generated from `assets/icon/` by `tool/generate_icon.dart` (a violet gradient with the app's own "found word" stroke mark — not a placeholder/default Flutter icon), wired via `flutter_launcher_icons`. |
| Native splash screen | Generated via `flutter_native_splash`, including Android 12+ splash and dark-mode variant. |
| Versioning | `pubspec.yaml` set to `1.0.0+1`. App version displayed in Settings is read from the real installed package at runtime (`package_info_plus`), not a hand-maintained constant — can't drift out of sync. |
| Application ID consistency | `com.baslt.word_search_app` matches across `AppConfig`, `android/app/build.gradle.kts`, and iOS `Info.plist`/bundle ID/Xcode project. |
| Release build compiles | `flutter build apk --release` (`app-release.apk`, ~92MB) and `flutter build appbundle --release` (`app-release.aab`, ~80MB) both succeeded end-to-end (R8/minification, resource merging, manifest merging all clean) — real Android SDK, real Gradle build, not a simulation. |
| Release signing | **Real upload key, signed.** `C:/Users/baslt/keys/word-search-upload.jks` (JKS, alias `upload`, 2048-bit RSA, valid ~27 years), matching the crossword and sudoku keystores' convention. Credentials are in `android/key.properties`, which is gitignored (`android/.gitignore:12`) along with `*.jks`. `build.gradle.kts` picks it up automatically and falls back to debug signing only when that file is absent. |
| Permissions | Audited the actual merged release manifest (`build/app/intermediates/merged_manifests/release/.../AndroidManifest.xml`). Every permission present (`INTERNET`, `ACCESS_NETWORK_STATE`, `AD_ID`, three `ACCESS_ADSERVICES_*`, `BILLING`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`) is pulled in by the ads, billing, notification, or haptics functionality this app actually uses — nothing extraneous requested. |
| Test suite | `flutter analyze` — no issues. `flutter test` — 349 tests passing, including every bundled puzzle (2,400 of them, across all 6 languages x 4 difficulties) validated through the real scanner. |
| Privacy policy | Bundled at `assets/legal/privacy_policy.md` (what the in-app screen renders) and **hosted live** at `doc-hosting.flycricket.io/word-search/70ff7ba2-…/privacy`, wired into `AppConfig.privacyPolicyUrl`. Fetched and checked on 2026-09-03: names Word Search, BT Developer, baladream.help@gmail.com, the 13+ audience, AdMob / UMP / Play Billing, and the on-device reminders — matching what the code actually does. Paste that URL into the Play Console listing. |
| Data Safety mapping | Drafted at `store/DATA_SAFETY.md` as a lookup reference for the Play Console questionnaire. |
| AdMob wiring | Real Android App ID `ca-app-pub-1057967613304012~1554723382` in `AndroidManifest.xml`; the three real unit IDs in the gitignored `ad_config.json`. Release builds must pass `--dart-define-from-file=ad_config.json` or they ship with no ads at all. iOS keeps Google's test App ID in `Info.plist` — AdMob issues a separate App ID per platform. |

**Still owner action before you open a real-ID build on your phone:**
register that device in AdMob → Settings → Test devices. Tapping your own
live ads is invalid traffic and is the most common reason new AdMob
accounts get suspended.

## Requires your action outside this environment

| Item | What's needed | Why it can't be done here |
|---|---|---|
| Real `applicationId` | Decide the final reverse-domain package name before your *first* upload — Play Console treats it as permanent. `com.baslt.word_search_app` was a reasonable placeholder chosen during initial scaffolding, not a confirmed business decision. | Naming/branding decision only you can make. |
| **Back up the keystore** | `C:/Users/baslt/keys/word-search-upload.jks` and the password in `android/key.properties` exist in exactly one place: this machine. Copy both somewhere durable and offline. | Recoverable but painful: this is an *upload* key, and with Play App Signing (on for all new apps) Google holds the actual app signing key — so losing this one means a key-reset request to Play support, not a dead app. Neither file is recoverable from anything in this repo, though. |
| AdMob test-device registration | Add your own phone under AdMob → Settings → Test devices before installing a build that carries the real unit IDs. | AdMob console action; the account is yours. |
| AdMob for iOS | If iOS ships, create a *separate* iOS app in AdMob and put its App ID in `ios/Runner/Info.plist` (it currently holds Google's test ID). The Android App ID must not be reused there. | AdMob console action, and iOS isn't built here anyway. |
| Play Console Billing product | Create the `remove_ads` non-consumable product at $1.00 in Play Console, matching `AppConfig.removeAdsProductId`. | Play Console account action. |
| Privacy policy legal review | Hosting is **done** (see above). What remains is having the wording reviewed by counsel for your target markets — I am not a lawyer and this policy was written to describe the code, not to satisfy a jurisdiction. | Legal review is outside code. |
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
