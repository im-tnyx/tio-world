# Startup bootstrap initial session + timeout

Status: Complete / Frozen

## Problem

Fresh-install/debug runs could remain on Splash forever when the active `AuthSessionRepository.sessionState` did not replay its initial state. `AppSessionBootstrapController.start()` listened only to the stream, so an already-emitted unauthenticated state could be missed. The initial `Loading` state then had no bounded current-session resolution.

Observed acceptance failure: clear local/app data, launch app, Splash progress ring continued indefinitely and Welcome never appeared.

## Implemented

- Startup now subscribes to auth transitions and also explicitly resolves `currentSessionState`.
- Initial current-session lookup is bounded to 8 seconds.
- Retry/refresh current-session lookup uses the same 8-second timeout.
- Timeout/error resolves `AppSessionBootstrapFailure`, allowing Splash to show failure + Retry instead of an endless progress ring.
- Generation guarding prevents a late startup snapshot from overwriting a newer auth stream transition.
- Product Onboarding flow/data/schema, Auth provider ownership, Supabase runtime config, Splash branding, and database schema were not changed.

## Regression coverage

Focused tests prove:

1. A non-replaying auth stream with current unauthenticated state resolves from `start()` without manual refresh.
2. A hanging initial current-session lookup becomes `AppSessionBootstrapFailure` instead of remaining Loading forever.
3. A hanging retry/refresh lookup is also bounded.
4. A late initial snapshot cannot overwrite a newer auth stream event.
5. Existing authenticated bootstrap/completion/race behavior remains green.

## Accepted runtime/source-test checkpoint

```text
f3517d211dacb0945d14163af9abb4c97f52082c
```

Validation:

```text
Flutter CI #2021 / run 32861957470 ✅
Android Native CI #433 / run 32861957648 ✅
Flutter analyze ✅
Dart analyze ✅
Flutter tests ✅
Dart tests ✅
Phone Android debug APK ✅
Wear Android debug APK ✅
```

## Merge state

PR #50 remains Draft / open / unmerged. This startup fix is a post-audit merge-blocker correction and does not reopen the accepted Product Onboarding O1–O11 data/UI architecture.
