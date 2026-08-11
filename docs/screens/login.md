# Login Screen

**Surface:** Phone authentication screen
**Current route:** `/login`
**Primary owner:** `apps/features/auth`
**Status:** Implemented UI; all sign-in buttons are placeholders that route to Home.

## Current Runtime Behavior

- Shows Truecaller, Google, phone-number, and email-address entry buttons plus a back action.
- Pressing any sign-in method currently routes to `/`; it does not authenticate a user or establish a session.
- Terms and Privacy text is visible but not linked.

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
