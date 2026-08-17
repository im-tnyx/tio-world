# Welcome Get Started → unauthenticated onboarding

Issue: #12
Branch: `codex/onboarding-mode-migration`
Status: Implemented — validation pending

## Problem
After session bootstrap hardening, tapping **Get Started** on Welcome does not advance. `WelcomeRoute` pushes `/onboarding`, but unauthenticated bootstrap routing redirects `/onboarding` back to `/auth` (Welcome).

## Frozen behavior
- Signed-out user taps **Get Started** → onboarding opens.
- Onboarding may run signed out until its explicit auth-required boundary.
- Protected Home/Profile routes remain inaccessible while signed out.
- Authenticated incomplete users remain gated to onboarding.
- Authenticated completed users entering onboarding are redirected Home.
- No Welcome UI/layout/token/pixel changes.

## Slice A implementation
- Added `AppRoutes.onboarding.path` to `_unauthenticatedPublicPaths` in `app_session_route_policy.dart`.
- Added route-policy regression coverage proving signed-out `/onboarding` is allowed.
- Preserved signed-out protected Home redirect to Welcome.
- Welcome screen/button code was not changed.

## Root cause evidence
- `WelcomeRoute` handles `WelcomeGetStartedClicked` with `context.push(AppRoutes.onboarding.path)`.
- `OnboardingFlowPage` already owns an `onAuthRequired` callback and can defer auth until needed.
- Before this fix, `appSessionBootstrapRedirect` redirected unauthenticated `/onboarding` back to `AppRoutes.auth.path`.

## Commits
- `5af431a21c92dc8cd32390c2f48a9c87a0feb855` — allow signed-out onboarding entry.
- `8937867fbaa93bc13719056d1dd93beaeead3d9c` — regression test.

## Validation
- GitHub Actions run #29 is queued/pending at handoff time.
- Local targeted test pending.
- Real-device check pending: Welcome → Get Started → onboarding first step.

## Handoff
Pull latest branch, run the targeted session route-policy test and app analyze, then verify Get Started on a signed-out device. Close #12 only after the real-device flow passes.
