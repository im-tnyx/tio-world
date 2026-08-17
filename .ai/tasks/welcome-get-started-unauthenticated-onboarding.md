# Welcome Get Started → unauthenticated onboarding

Issue: #12
Branch: `codex/onboarding-mode-migration`
Status: Active

## Problem
After session bootstrap hardening, tapping **Get Started** on Welcome does not advance. `WelcomeRoute` pushes `/onboarding`, but unauthenticated bootstrap routing redirects `/onboarding` back to `/auth` (Welcome).

## Frozen behavior
- Signed-out user taps **Get Started** → onboarding opens.
- Onboarding may run signed out until its explicit auth-required boundary.
- Protected Home/Profile routes remain inaccessible while signed out.
- Authenticated incomplete users remain gated to onboarding.
- Authenticated completed users entering onboarding are redirected Home.
- No Welcome UI/layout/token/pixel changes.

## Slice A
1. Allow `AppRoutes.onboarding.path` in the unauthenticated public-flow allow-list.
2. Add route-policy regression coverage for signed-out onboarding access.
3. Preserve protected-route redirect coverage.
4. Run targeted route-policy test + app analyze.
5. Real-device check: Welcome → Get Started → onboarding first step.

## Root cause evidence
- `WelcomeRoute` handles `WelcomeGetStartedClicked` with `context.push(AppRoutes.onboarding.path)`.
- `OnboardingFlowPage` already owns an `onAuthRequired` callback and can defer auth until needed.
- `appSessionBootstrapRedirect` currently redirects any unauthenticated path outside its public allow-list back to `AppRoutes.auth.path`.

## Handoff
Pending implementation and local/device validation.
