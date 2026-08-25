# Startup bootstrap initial session + timeout

Status: In Progress

## Problem

Fresh-install/debug runs can remain on Splash forever when the active `AuthSessionRepository.sessionState` does not replay its initial state. `AppSessionBootstrapController.start()` currently listens only to the stream, so an already-emitted unauthenticated state can be missed. The initial `Loading` state then has no deadline.

Observed acceptance failure: clear local/app data, launch app, Splash progress ring continues indefinitely and Welcome never appears.

## Scope

- Make startup bootstrap resolve the repository's current session snapshot after subscribing to transitions.
- Bound initial/current-session lookup with a finite timeout.
- Ensure stale initial reads cannot overwrite a newer stream event.
- Ensure refresh/retry uses the same finite timeout and fails to Splash error/Retry instead of spinning forever.
- Add focused regression tests using a non-replaying auth stream and a hanging current-session lookup.
- Improve Splash bootstrap failure copy only if needed for accurate startup messaging.

## Out of scope

- Product Onboarding flow/data/schema changes.
- Auth provider redesign.
- Supabase runtime-config policy changes.
- Splash branding/image redesign.
- Database migrations.

## Acceptance

1. Fresh unauthenticated state with a non-replaying auth stream resolves `AppSessionBootstrapUnauthenticated` from `start()` without manual `refresh()`.
2. Initial current-session lookup cannot remain pending forever; timeout produces `AppSessionBootstrapFailure`.
3. Retry/current-session lookup is also bounded by the same timeout.
4. A newer auth stream event wins over a late initial snapshot.
5. Existing authenticated bootstrap/completion behavior remains green.
6. Full Flutter/Dart + Android phone/Wear CI passes at exact accepted SHA.
7. PR #50 remains Draft/open/unmerged.
