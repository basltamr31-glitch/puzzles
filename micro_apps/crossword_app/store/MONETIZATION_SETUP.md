# Monetization setup — AdMob & Play Billing

Everything in the app's code is finished and wired. What remains is
account configuration, which only you can do. This document is the
checklist.

---

## 1. Important: you need AdMob, not Google Ads

These are two different Google products and it's an easy mix-up:

| Product | What it's for | Do you need it? |
| --- | --- | --- |
| **Google Ads** (ads.google.com) | **Buying** ads — you pay Google to advertise your app to other people. | Only if you want to *promote* the game. |
| **AdMob** (apps.admob.com) | **Showing** ads inside your app — Google pays *you*. | **Yes. This is the one.** |

If your existing account is a Google Ads account, it will not produce ad
unit IDs for the app. Sign in to **apps.admob.com** with the same Google
account and create an AdMob account there; they can coexist, and AdMob
payments go to the same Google payments profile.

---

## 2. Create the app and its three ad units in AdMob

1. Go to **apps.admob.com** → **Apps** → **Add app**.
   - Platform: Android. "Is it listed on a store?" — No, if not published yet.
   - You will get an **App ID** shaped like `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`
     (note the **`~`**).
2. Under that app → **Ad units** → create three:

   | Ad unit | Format | Where it appears in this app |
   | --- | --- | --- |
   | Banner | Banner | Bottom of the puzzle list and the crossword screen |
   | Interstitial | Interstitial | After a puzzle is completed (rate-limited) |
   | Rewarded | Rewarded | Only when the player taps "Hint" and opts to watch |

   Each gives an **Ad unit ID** shaped `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`
   (note the **`/`**).

---

## 3. Put the App ID in the Android manifest

Edit `android/app/src/main/AndroidManifest.xml` and replace the test value:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY" />
```

This one is required. If the App ID is missing or malformed the app
**crashes on launch** when the ads SDK initializes.

## 4. Pass the three ad unit IDs at build time

Ad unit IDs are deliberately *not* committed to the repo. Copy the example
config once and fill in your three IDs:

```bash
cp ad_config.example.json ad_config.json
```

`ad_config.json` is gitignored. Then every build is just:

```bash
flutter build appbundle --release --dart-define-from-file=ad_config.json
```

The same flag works for `flutter run` and `flutter build apk`, so testing
on a device uses the identical IDs the store build will use.

How `AppConfig` resolves them (`lib/app/app_config.dart`):

- A `--dart-define` value is supplied → use it.
- Otherwise, **debug** build → Google's public **test** unit IDs, so ads
  render during development with no risk to your account.
- Otherwise, **release** build → **empty string**, which `AdService`
  treats as "no ad configured" and skips silently.

That last rule is deliberate: it is impossible to accidentally ship a
test ad unit to production, which would be an AdMob policy violation and
can get an account suspended.

---

## 5. How each ad type behaves

**Banner** — persistent strip at the bottom of the puzzle list and
crossword screens. It renders *nothing at all* until a real ad loads, so
a slow or failed load never leaves an empty grey box. Hidden entirely for
players who bought Remove Ads.

**Interstitial (full-screen, often video)** — shown only after a puzzle is
completed, never mid-puzzle. Rate-limited by
`AppConfig.interstitialMinPuzzlesBetween` (currently every 3 completions)
so it doesn't become obnoxious. Hidden for Remove Ads owners.

**Rewarded video** — the only ad the player chooses. Tapping **Hint**
offers "watch an ad for a hint"; the letter is revealed *only* after
AdMob confirms the reward. Cancelling the video gives no hint and costs
nothing. Remove Ads owners get hints free without any video.

Video content is served and rendered by the Google Mobile Ads SDK — you
don't supply or host any video yourself. Whether a given interstitial is
a video or a static image is decided by AdMob's auction at request time.

---

## 6. Testing with your real ad unit IDs — read this before you tap anything

**Never tap your own live ads.** Google calls this invalid traffic, and it
is one of the most common reasons new AdMob accounts get suspended before
an app ever launches. The safe way to test real ad units is to register
your phone as a test device, which makes *your* device receive test ads
even from your real ad unit IDs.

**Register your device (do this first):**

1. Build and run the app on your phone with your real IDs.
2. Look at the logs (`flutter logs`, or `adb logcat | grep -i "Use RequestConfiguration"`).
   The Google Mobile Ads SDK prints a line containing your device's test
   ID hash, something like:
   `Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))`
3. Copy that hash into **AdMob → Settings → Test devices → Add test device**.

From then on your device shows test ads (labelled "Test Ad") while using
your production ad unit IDs — so you can tap freely, confirm the rewarded
video grants a hint, and verify the banner renders, all without risking
your account.

**Things that look like bugs but are normal:**

- A brand-new ad unit often serves nothing for the first few hours, and
  can take up to 24h. "No fill" right after creating a unit is expected,
  not a broken integration.
- A brand-new AdMob account may not serve live ads until Google finishes
  reviewing it and your payment details are complete.
- The banner renders nothing at all until an ad actually loads — that is
  deliberate, so a failed load never leaves an empty grey box.

**Without any real IDs**, a debug build still works: it falls back to
Google's public test units, so the whole pipeline is verifiable before
your AdMob account is fully set up.

---

## 7. Remove Ads price ($1.00)

**The charged price is set in Play Console, not in the app code.** The app
displays whatever the store reports.

1. Play Console → your app → **Monetize → Products → In-app products**.
2. Create a product with ID **`remove_ads`** — this must match
   `AppConfig.removeAdsProductId` exactly, or purchase and restore break.
3. Type: **non-consumable** (one-time, permanent).
4. Set the default price to **USD 1.00**. Play auto-converts to every
   other currency; you can override individual countries if you want.
5. **Activate** the product.

The purchase screen calls `BillingService.localizedPrice()` and shows the
store's own localized string, so a Japanese player sees `¥150` and a
German player sees `0,89 €` — all reflecting the single $1.00 you set.
The bundled `$1.00` string is only a fallback for when the store can't be
reached (e.g. no network, or before the product is activated).

Testing purchases requires the app uploaded to a Play testing track and
your account added under **Setup → License testing**, which lets you make
test purchases without being charged.

---

## 7b. Testing the Remove Ads purchase end to end

A purchase cannot be tested from a locally-built debug APK. Google Play
Billing only answers an app it recognises — same `applicationId`, same
signing key, same version code as something it has on a track — so on a
sideloaded build every purchase attempt fails before a payment sheet can
appear. That is not a bug in the app; it is the billing sandbox refusing
to talk to an app it has never seen.

Since the app now tells the two failures apart, the message on screen
says which step is missing:

| Message on screen | What it means | What to do |
| --- | --- | --- |
| "The store isn't available right now…" | `InAppPurchase.isAvailable()` was false — no Play Store, not signed in, or an emulator without Play services | Use a real device signed in to the tester account |
| "This purchase isn't available right now…" | Play answered but returned no product for `remove_ads` — not created, not activated, or this build is not on a track | Work through the steps below |
| "The purchase couldn't be completed…" | A genuine store error, a refused flow start, or a 2-minute timeout | Retry; if it persists, check Play Console order/error logs |

Do these in order — each one is a hard prerequisite for the next:

1. **Create and activate the product.** Play Console → Monetize →
   Products → In-app products → ID exactly `remove_ads`, one-time
   purchase, price USD 1.00, then **Activate**. An inactive product is
   invisible to the app and is the most common cause of the second
   message above.
2. **Create an upload keystore and sign the build.** `android/key.properties`
   — see `android/key.properties.example`. Play identifies your app by
   its signature; a debug-signed build is a different app to Play.
3. **Upload a build to a track.** Internal testing is fastest. It must be
   an **App Bundle**:
   ```bash
   flutter build appbundle --release --dart-define-from-file=ad_config.json
   ```
   The version code must be higher than anything previously uploaded.
4. **Wait for the release to finish processing.** Billing does not work
   against a release still showing "In progress" — usually minutes, but
   the first upload of a brand-new app can take hours.
5. **Add your account as a licensed tester.** Play Console → (all apps)
   → **Setup → License testing** → add the Google account you will test
   with. This is account-wide, not per-app, and it is what makes the
   purchase free: the payment sheet appears and says **"Test card, always
   approves"**, and no money moves.
6. **Join the testing track on the device.** Open the opt-in link from
   the internal testing page with that same account, accept, then install
   the app **from the Play Store** — not by `flutter install`.
7. **Buy it.** The sheet should show the test card. After purchase,
   `PremiumStateController` writes the flag, banners disappear
   immediately, and the hint button stops asking you to watch an ad.
8. **Test restore.** Uninstall, reinstall from Play, open Settings →
   Restore purchases. It should report success without charging again —
   this is what proves the non-consumable is acknowledged properly.

**To buy it a second time**, refund and revoke the test order in Play
Console → Order management. A non-consumable stays owned forever
otherwise, and every later attempt returns "already owned".

**A note on what is already covered.** `PremiumStateController` listens
to `BillingService.purchaseUpdates`, so a purchase the store replays on a
later launch (e.g. one that completed while the app was killed) still
removes ads without any user action. That path is unit-tested; it is the
store-side setup above that cannot be tested from here.

---

## 8. Pre-launch checklist

- [x] AdMob account created (not just Google Ads)
- [x] App added in AdMob ("Crossword", Android); App ID
      `ca-app-pub-1057967613304012~7914008366` in `AndroidManifest.xml`
- [x] Three ad units created; IDs in the gitignored `ad_config.json`
- [ ] **Your phone registered in AdMob → Settings → Test devices** — do this
      before opening the app with real IDs. Tapping your own live ads is
      invalid traffic and gets new accounts suspended.
- [ ] `remove_ads` product created at $1.00 and **activated** in Play Console
- [ ] Upload keystore created (`android/key.properties`)
- [ ] Release build verified on a real device
- [ ] `store/PRIVACY_POLICY.md` hosted at a public URL and linked in Play Console
- [ ] After publishing: link the AdMob app to the Play listing (improves fill)
