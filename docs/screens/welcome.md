# Welcome Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: `apps/features/welcome`
Truth Boundary: Authoritative for the Welcome screen product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Phone entry / auth landing screen
**Current route:** `/auth`
**Primary owner:** `apps/features/welcome`
**Status:** Implemented Flutter UI and navigation. Language and legal actions are placeholders.

## Current Runtime Behavior

- Shows the Tio landing surface, Get Started, Sign In, Skip for now, language, and legal text.
- **Get Started** pushes `/account-setup/app-mode`, beginning pre-auth App Mode selection for the fresh-account journey.
- **Sign In** pushes `/login`.
- **Skip for now** currently also pushes `/login`; there is no implicit guest Home session.
- Language and legal copy remain visible placeholders until approved destinations exist.

## Target Responsibility

Welcome explains the product and owns the entry choice into fresh-account setup or authentication. It may route into pre-auth App Mode selection, but it does not itself persist App Mode, create canonical profile data, or establish an authenticated session.

## Target Actions

- Get Started opens pre-auth App Mode selection; authenticated account setup and Product Onboarding follow through their owning routes.
- Sign In opens Login.
- Skip must be retained only if the product supports an explicit guest path. Before real feature persistence is added, define what guest data is available, local-only, or blocked.
- Language and legal copy remain non-interactive until approved, accessible destinations exist; when implemented, their actions must be restored with explicit semantics and tests.

## States And Quality

- Image loading failures need a branded fallback that preserves readable text and actions.
- Buttons must retain visible focus and touch feedback despite the dark, image-led visual treatment.
- The entrance animation consumes the shared motion scheme and becomes zero-duration when reduced motion is enabled.
- Legal copy must not imply a policy URL or consent behavior that does not exist.

## Acceptance Criteria

- All visible actions either work, are clearly unavailable, or are not presented as interactive.
- Get Started consistently leads to App Mode selection as the first onboarding step.
- Guest behavior, if retained, has an explicit data and privacy boundary.

## Related

- [Login](login.md)
- [Onboarding](onboarding.md)
- [Screen catalog](README.md)
