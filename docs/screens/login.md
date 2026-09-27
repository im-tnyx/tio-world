# Login Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: `apps/features/auth`
Truth Boundary: Authoritative for the Login screen product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Phone authentication screen
**Current route:** `/login`
**Primary owner:** `apps/features/auth`
**Status:** Implemented authentication UI with real Supabase-backed sign-in flows for supported methods; verified success returns to app-level session/bootstrap handling.

## Current Runtime Behavior

- Shows the supported sign-in entry methods and back action; provider availability can still vary by configured capability.
- Email and Google sign-in are wired through injected Auth use cases, and the Auth feature also owns the Supabase phone-OTP repository/use-case flow.
- Successful authentication invokes the app-level explicit-login success callback so session/bootstrap state decides the next destination; Login does not directly fabricate a Home session.
- Terms and Privacy text remains visible; only approved destinations should become interactive.

## Target Responsibility

Login owns client-side authentication presentation and delegates real auth/session work to an approved, protected contract. It must not embed provider secrets, server-only keys, or account decisions in widgets.

## Target Actions

- Each enabled identity provider creates a clear pending, success, cancellation, and failure state.
- A successful sign-in returns a verified session/bootstrap result so Splash or the auth flow can route to Onboarding or Home correctly.
- Back returns to Welcome without leaving the navigation stack in an invalid state.
- Legal links open approved policy content only after destinations are available.

## States And Quality

- Disabled, loading, provider-cancelled, invalid input, network failure, and retry states are required for a real provider.
- Do not claim a sign-in method is supported until its authorization, privacy, and failure paths are implemented.
- Errors must be actionable but must not expose provider tokens, phone numbers, emails, or backend details in logs or UI.

## Acceptance Criteria

- No placeholder authentication action may be mistaken for a real account session.
- Every enabled provider uses an approved security and privacy boundary.
- Successful navigation depends on verified session and onboarding state, not only a button tap.

## Related

- [Welcome](welcome.md)
- [Splash](splash.md)
- [Onboarding](onboarding.md)
