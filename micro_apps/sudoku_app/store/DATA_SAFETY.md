# Google Play Data Safety — reference mapping

Google Play's Data Safety form is filled out in the Play Console UI, not
in code — this document exists so filling it out is a lookup instead of
a guess. It reflects what this app's actual implementation does as of
this version. **Verify against the live Play Console form before
submitting** — Google revises its categories periodically, and this
mapping should be re-checked if the app's dependencies change (e.g. a
real analytics backend is added).

## Does your app collect or share any of the required user data types?

**Yes** — via the bundled Google SDKs (AdMob, UMP, Play Billing), not
via any custom backend (this app has none).

## Data types

| Category | Collected? | Shared? | Purpose | Notes |
|---|---|---|---|---|
| Device or other IDs (advertising ID) | Yes | Yes (Google) | Advertising, analytics | Via Google Mobile Ads SDK. Subject to user consent (UMP) where required. |
| Approximate location | Yes | Yes (Google) | Advertising, fraud prevention, consent-region detection | Derived from IP by Google's SDKs (AdMob, UMP) — the app never requests device location permissions directly. |
| App activity (app interactions) | No* | No* | — | *True only while analytics stays console-only (no transmission). Update this row the moment a real analytics backend is wired in. |
| Purchase history | Yes | Yes (Google) | Account management / purchases | Handled entirely by Google Play Billing. The app only stores a local boolean ("ads removed"); it does not independently transmit purchase records anywhere. |
| Personal info (name, email, address, phone) | No | No | — | The app has no account system and never asks for this. |
| Financial info (card numbers etc.) | No | No | — | Payment entirely handled by Google Play's own checkout UI; card details never pass through this app. |
| Photos/videos, audio, contacts, calendar | No | No | — | Not accessed. |
| Precise location | No | No | — | Not requested. |

## Security practices to declare

- Data is encrypted in transit: **Yes** (all third-party SDK traffic is
  HTTPS — this is inherent to the Google SDKs used, not custom code).
- Users can request data deletion: uninstalling the app deletes all
  locally-stored data; for data Google's SDKs hold (advertising ID
  activity, purchase records), direct users to Google's own account
  controls (Google Ads Settings, Google Play purchase history) — this
  app has no server-side user data to delete on request, because it has
  no server.

## Independent security review

Not conducted. Leave the corresponding Play Console field unchecked
unless one is actually performed.

## Before submitting

1. Confirm the current Play Console Data Safety questionnaire's exact
   category list still matches this table (Google updates it
   periodically) and fill it out there directly — this file is prep,
   not a substitute for the real form.
2. Get `store/PRIVACY_POLICY.md` reviewed, hosted, and linked from the
   Play Console listing before submitting the Data Safety section —
   Play Console requires the privacy policy URL to be live first.
3. If a real analytics backend (e.g. Firebase Analytics) is added later,
   update the "App activity" row above and the Data Safety form
   together — they must stay consistent with each other and with what
   the app's code actually does.
