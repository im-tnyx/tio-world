# Auth Session Bootstrap Routing

**Status:** In progress
**Primary owner:** `apps/app` + `apps/features/auth` + `apps/features/onboarding`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #7
**Source baseline:** `codex/onboarding-mode-migration`

## 1. Discovery

### User Outcome

Separate authentication success from product onboarding completion and make cold-start/post-login routing consume one authoritative readiness result.

```text
unauthenticated
→ Auth

authenticated + missing/uninitialized backend app user
→ Onboarding

authenticated + backend onboarding incomplete
→ Onboarding / Resume

authenticated + backend onboarding completed
→ Home
```

### Success Criteria

- Existing completed Google/email user goes directly to Home.
- Existing incomplete user enters/resumes onboarding.
- First-time/uninitialized authenticated user enters onboarding.
- Auth success never implies onboarding completion.
- Missing local `AppMode` never downgrades authoritative completed onboarding.
- Cold start and post-login use the same readiness owner.
- Login/AuthLanding presentation does not query `public.users` or choose product destinations.
- Backend completion is published only after required onboarding owner persistence succeeds.
- Backend lookup failure is never treated as a new user.

### Mobile Visual Baseline Freeze

This is behavior/architecture work, not UI redesign.

- Preserve current Login, AuthLanding, Splash, Onboarding, Congratulations, and Home rendering.
- Preserve spacing, typography, colors, button geometry, assets, sizes, motion, and layout.
- Do not normalize current values to nearby design tokens.
- Functional changes may change destination/state, not destination styling.
- Unexplained visual diffs are regressions.

### Legal / Welcome Boundary

- `WelcomeScreen` intentionally has no Terms/Privacy footer. Do not restore it.
- `AuthLandingPage` intentionally renders `TioTermsDisclaimer`. Preserve it there.
- Do not add/move the disclaimer to `LoginPage` or `EmailLoginPage`.
- Welcome orphan disclaimer/state cleanup is separate.

### Scope

- auth-session/readiness composition;
- durable backend onboarding completion read/write contract;
- router as single product-destination owner;
- deterministic Splash ownership;
- AppMode decoupling from onboarding completion;
- removal of direct Supabase routing queries from auth presentation;
- final onboarding-completion publication boundary;
- focused regression tests.

### Non-Goals

- UI redesign or token migration;
- Welcome cleanup;
- `LoginPage` / `EmailLoginPage` consolidation;
- DB provisioning trigger implementation from issue #5;
- profile/account persistence defects tracked separately in issue #8;
- per-action loading/Truecaller unavailable behavior tracked separately in issue #9;
- broad Firebase legacy cleanup unrelated to this slice.

## 2. Codebase Exploration

### Verified Evidence

- `LoginPage` directly queries `public.users.is_onboarded` and navigates after auth.
- `AuthLandingPage` duplicates the same DB lookup/navigation and owns the legal footer that must remain.
- `router.dart` also navigates through `onSignInSuccess`, creating competing navigation ownership.
- Splash callback previously directly queried `public.users.is_onboarded`; Slice C removed that ownership.
- Auth domain already has `AuthSessionState`; do not create a duplicate auth-session hierarchy.
- Current production auth session adapter is Supabase-backed.
- Google sign-in attempts profile metadata upsert before onboarding, so raw row existence must not be the returning-user criterion.
- Live `public.users` has several NOT NULL profile fields; a first-time metadata-only upsert may fail until full onboarding data exists.
- `SupabaseProfileSetupRepository.saveProfileSetup()` previously published `is_onboarded: true` during Profile owner persistence; Slice B removed that early completion publication.
- `CompleteOnboardingUseCase` now owns durable backend completion publication after owner persistence and confirmed AppMode write, before local completion cache publication.

### Local Verification Completed

The local worktree was reported clean, synchronized, and on `codex/onboarding-mode-migration` using Flutter 3.44.6 / Dart 3.12.2.

## 3. Clarification

### Frozen Decisions

- Reuse existing `AuthSessionState`.
- `public.users.is_onboarded` is durable returning-user completion authority.
- Missing backend user row requires onboarding; backend lookup error is failure, never new-user classification.
- AppMode is shell/personalization state, not onboarding completion proof.
- Router is the single product-destination owner.
- Returning completed users go Home, never Congratulations.
- Congratulations is only for a fresh successful onboarding completion.
- DB-owned auth-user provisioning remains issue #5.
- AuthLanding keeps `TioTermsDisclaimer`; Welcome remains without it.

## 4. Architecture Design

```text
AuthSessionRepository
        +
OnboardingCompletionRepository
        +
local onboarding cache reconciliation
        ↓
AppSessionBootstrapController
        ↓
loading / unauthenticated / requiresOnboarding / ready / failure
        ↓
GoRouter bootstrap-first redirect
        ↓
AppMode shell policy only after ready
```

Fresh onboarding completion publishes owner data, confirmed AppMode, durable backend completion, local completion cache, then marks bootstrap ready and presents Congratulations.

## 5. Implementation Plan

### Slice A — AppMode/completion decoupling

- [x] completed onboarding remains completed when local AppMode is missing
- [x] completed + missing AppMode keeps Home accessible
- [x] mode-specific shell destinations fall back to Home when mode is missing
- [x] focused tests pass
- [x] app analyzer passes

### Slice B — Domain/data boundary

- [x] add `OnboardingCompletionRepository` + remote completion state
- [x] add Supabase implementation with focused tests
- [x] remove early `is_onboarded` publication from Profile owner save
- [x] inject backend completion publication into `CompleteOnboardingUseCase`
- [x] onboarding focused tests pass
- [x] onboarding/profile/app analyzers pass

### Slice C — App bootstrap/routing

- [x] add `AppSessionBootstrapController`
- [x] reconcile local onboarding status without AppMode coupling
- [x] stale async auth-user result cannot overwrite newer session state
- [x] wire controller into router `refreshListenable`
- [x] make router redirect bootstrap-first
- [x] remove Splash direct DB query/navigation ownership
- [x] make no-checker Splash passive while preserving rendered UI
- [x] publish bootstrap ready after fresh successful onboarding completion
- [x] focused app/Splash tests and analyzers pass locally

### Slice D — Auth presentation cleanup

- [ ] remove direct Supabase import/query/navigation from `LoginPage`
- [ ] remove direct Supabase import/query/navigation from `AuthLandingPage`
- [ ] remove router-owned `LoginPage.onSignInSuccess` destination navigation
- [ ] preserve AuthLanding `TioTermsDisclaimer`
- [ ] keep Login/AuthLanding visual output unchanged
- [ ] run focused auth tests/analyze + app analyze

### Slice E — Regression matrix

- [ ] existing completed Google user → Home
- [ ] existing completed email user → Home
- [ ] incomplete/uninitialized authenticated user → Onboarding
- [ ] `inProgress` current-user flow resumes Onboarding
- [x] completed cold start bootstrap policy → Home
- [ ] logout → same completed account → Home after sign-in
- [x] missing local AppMode does not restart onboarding
- [x] backend lookup error stays failure/Splash, not onboarding
- [x] stale user bootstrap result cannot win after auth state changes
- [x] completion owner failure does not publish backend/local completed state
- [ ] returning login never routes to Congratulations

## 6. Quality Review

### Validation Run

```text
Slice A — apps/app
- app_mode_route_policy_test.dart: 9 passed
- onboarding_status_controller_test.dart: 6 passed
- flutter analyze: No issues found

Slice B — apps/features/onboarding
- complete_onboarding_remote_completion_test.dart: 2 passed
- supabase_onboarding_completion_repository_test.dart: 3 passed
- complete_onboarding_use_case_test.dart: 13 passed
- flutter analyze: No issues found

Slice B — apps/features/profile
- flutter analyze: No issues found

Slice B regression — apps/app
- app_mode_route_policy_test.dart: 9 passed
- onboarding_status_controller_test.dart: 6 passed
- flutter analyze: No issues found

Slice C — apps/app
- app_session_bootstrap_controller_test.dart: 6 passed
- app_session_route_policy_test.dart: 4 passed
- app_mode_route_policy_test.dart: 9 passed
- onboarding_status_controller_test.dart: 6 passed
- flutter analyze: No issues found

Slice C — apps/features/splash
- splash_screen_test.dart: 5 passed
- flutter analyze: No issues found

Final local worktree after Slice C validation: clean and synchronized.
```

### Review Findings and Resolution

- Slice C router diff was audited and contained only bootstrap ownership changes.
- Splash rendered tree/style remains unchanged; only no-checker navigation ownership became passive.
- Login per-action loading and unavailable Truecaller behavior remain separately tracked in issue #9.

## 7. Final Handoff

### Actual Behavior

Slices A, B, and C are implemented and locally validated. Auth presentation still contains duplicate post-auth DB/navigation logic and is the current active Slice D.

### Known Limitations

- Durable cross-device AppMode persistence is not available today and is not invented in this task.
- DB-owned auth-user provisioning remains issue #5.
- Login loading/Truecaller interaction remains issue #9 and is intentionally not fixed inside Slice D except where navigation ownership must be removed.

### Final Status

`PARTIAL`
