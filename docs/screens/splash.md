# Splash Screen

**Surface:** Phone entry screen
**Current route:** `/splash`
**Primary owner:** `apps/features/splash`
**Status:** Implemented visual screen with a fixed transition; session and data initialization are not implemented.

## Current Runtime Behavior

- Shows a bold "TIO" wordmark and a loading spinner on the Tio background.
- Waits two seconds, then navigates to `/auth`.
- Does not inspect authentication, App Mode, profile completeness, persistence, network state, or sync state.

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
