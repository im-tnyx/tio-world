# Welcome Screen

**Surface:** Phone entry / auth landing screen
**Current route:** `/auth`
**Primary owner:** `apps/features/welcome`
**Status:** Implemented Flutter UI and navigation. Language and legal actions are placeholders.

## Current Runtime Behavior

- Shows the Tio landing image, backdrop, product message, feature tiles, Get Started, Sign In, Skip for now, language, and legal text.
- **Get Started** pushes `/onboarding`.
- **Sign In** pushes `/login`.
- **Skip for now** navigates to `/`.
- Language selection and Terms/Privacy taps do not yet perform an action.

## Target Responsibility

Welcome explains the product and gives a safe entry choice. It must not decide App Mode, create a profile, or assume an authenticated session.

## Target Actions

- Get Started opens the mode-first Onboarding flow.
- Sign In opens Login.
- Skip must be retained only if the product supports an explicit guest path. Before real feature persistence is added, define what guest data is available, local-only, or blocked.
- Language and legal links must open approved, accessible destinations before they are represented as live actions.

## States And Quality

- Image loading failures need a branded fallback that preserves readable text and actions.
- Buttons must retain visible focus and touch feedback despite the dark, image-led visual treatment.
- The existing animated content must honor reduced-motion preferences when the shared design-system behavior is implemented.
- Legal copy must not imply a policy URL or consent behavior that does not exist.

## Acceptance Criteria

- All visible actions either work, are clearly unavailable, or are not presented as interactive.
- Get Started consistently leads to App Mode selection as the first onboarding step.
- Guest behavior, if retained, has an explicit data and privacy boundary.

## Related

- [Login](login.md)
- [Onboarding](onboarding.md)
- [Screen catalog](README.md)
