# Splash Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: `apps/features/splash`
Truth Boundary: Authoritative for the Splash screen product contract and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Phone entry screen
**Current route:** `/splash`
**Primary owner:** `apps/features/splash`
**Status:** Implemented presentation-only startup surface. App-level session/bootstrap resolution, redirect policy, failure state, and retry are implemented outside the feature screen.

## Current Runtime Behavior

- `SplashScreen` is passive presentation: it shows the TIO wordmark plus loading state, or a recoverable failure message with Retry.
- `AppSessionBootstrapController` and the app-level GoRouter policy own session/bootstrap resolution and destination routing; the screen itself has no fixed timer or direct `/auth` navigation.
- Bootstrap failure can surface on Splash and Retry calls the app-level bootstrap refresh.
- Authentication, App Mode, onboarding completion, profile/bootstrap reads, and safe fallback routing remain app-composition responsibilities rather than feature-widget decisions.

## Target Responsibility

Keep splash short and deterministic. When a real session/bootstrap contract exists, it may choose the next route based on explicit state:

| Verified condition | Target destination |
| :--- | :--- |
| No authenticated session | Welcome/Auth |
| Session exists, onboarding incomplete | Onboarding |
| Session and onboarding complete | Home using the selected App Mode |
| Bootstrap cannot safely continue | Recoverable error state with retry or signed-out path |

## Implementation Boundaries

- Splash may coordinate startup only; authentication, profile, App Mode, and feature data remain owned by their respective contracts.
- Do not keep a fixed delay once real bootstrap work exists merely to simulate loading.
- Never show private health or account data on Splash.

## Acceptance Criteria

- The next route is based on verified bootstrap state, not an arbitrary timeout.
- An unavailable local store or startup error has a visible, accessible recovery action.
- The transition respects reduced-motion preferences once that behavior is implemented.

## Related

- [Welcome](welcome.md)
- [Onboarding](onboarding.md)
- [Screen catalog](README.md)
