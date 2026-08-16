# Auth Session Bootstrap Routing

**Status:** In progress
**Primary owner:** `apps/app` + `apps/features/auth`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #7
**Source baseline:** `codex/onboarding-mode-migration` (start from current branch head; original verified code findings were against `53b6879e15d96686b50cd08162fdcd521f9c8653`)

## 1. Discovery

### User Outcome

Separate authentication success from product onboarding completion.

```text
unauthenticated
→ Auth

authenticated + new/uninitialized app account
→ idempotent account bootstrap
→ Onboarding

authenticated + existing + onboarding notStarted/inProgress
→ Onboarding / Resume Onboarding

authenticated + existing + onboarding completed
→ Home
```

### Success Criteria

- Existing completed Google user goes directly to Home.
- Existing incomplete user resumes onboarding.
- First-time Google user is bootstrapped idempotently and enters onboarding.
- Google auth success never implies onboarding completion.
- `AppMode` is not an implicit substitute for onboarding completion.
- Cold start and post-login callback use the same readiness/routing decision.
- Backend completion is published only after required onboarding persistence succeeds.

### Mobile Visual Baseline Freeze

This is a behavior/architecture task, not a UI redesign.

- Preserve current Login, AuthLanding, Onboarding, Congratulations, and Home rendering.
- Preserve spacing, typography, colors, button geometry, assets, sizes, and layout unless a functional change explicitly requires otherwise.
- Do not normalize values to nearby design tokens in this task.
- Functional changes may change the destination, not the visual styling of the destination.
- Unexplained visual diffs are regressions.

### Legal / Welcome Boundary

- `WelcomeScreen` intentionally has no Terms/Privacy footer. Do not restore it.
- `AuthLandingPage` intentionally renders `TioTermsDisclaimer`. Preserve it there.
- Do not automatically add/move the disclaimer to `LoginPage` or `EmailLoginPage`.
- Welcome orphan disclaimer/state cleanup is a separate task.

### Scope

- auth session/account bootstrap resolution;
- existing vs new/uninitialized app-user resolution;
- authoritative onboarding readiness resolution;
- AppMode reconciliation without using missing local mode as proof of incomplete onboarding;
- one navigation owner after auth success;
- cold-start and login-callback routing consistency;
- idempotent account bootstrap;
- final onboarding-completion publication boundary;
- focused regression tests.

### Non-Goals

- UI redesign or design-system/token migration;
- Welcome cleanup;
- `LoginPage` / `EmailLoginPage` consolidation;
- unrelated #5 startup/realtime/avatar/Wear work;
- unrelated dirty/untracked worktree changes.

## 2. Codebase Exploration

### Verified Evidence

Previously verified against the branch source:

- `apps/features/auth/lib/src/presentation/login/pages/login_page.dart`
  - directly queries `public.users.is_onboarded` after auth and owns navigation decisions.
- `apps/features/auth/lib/src/presentation/landing/auth_landing_page.dart`
  - also owns post-auth account/onboarding lookup/navigation and renders the legal disclaimer that must remain.
- `apps/app/lib/app/router.dart`
  - also navigates after sign-in success, creating competing navigation ownership.
- `apps/app/lib/app/onboarding/onboarding_status_controller.dart`
  - currently downgrades completed state when confirmed local AppMode is missing.
- `apps/app/lib/app/app_mode/app_mode_route_policy.dart`
  - currently couples completed onboarding to non-null AppMode.
- SharedPreferences onboarding/AppMode state is local-device state and not a safe sole returning-user authority.
- Google sign-in currently performs client-side `public.users` upsert/enrichment before returning success, so raw row existence alone cannot safely distinguish new vs returning product user.
- `SupabaseProfileSetupRepository.saveProfileSetup()` currently writes `is_onboarded = true` during Profile owner persistence, before all onboarding owners necessarily succeed.

### Tests Already Relevant

- `apps/app/test/app/app_mode_route_policy_test.dart`
- `apps/app/test/app/app_mode_router_test.dart`
- `apps/app/test/app/onboarding_status_controller_test.dart`
- `apps/features/auth/test/presentation/login_page_test.dart`

Some existing tests intentionally encode `completed + selectedMode == null → onboarding` and will need deliberate revision after the new source-of-truth contract is defined.

### Local Verification Required Before Production Source Changes

Run in the local `G:\projects\Tio-World` worktree:

```bash
git status --short --branch
git branch --show-current
rg -n "_navigateOnAuthSuccess|onSignInSuccess|is_onboarded|OnboardingStatus|selectedMode" apps/
```

Required branch:

```text
codex/onboarding-mode-migration
```

Preserve all unrelated dirty/untracked work. Do not stage, delete, overwrite, or reformat unrelated files.

## 3. Clarification

### Decisions

| Decision | Status | Rationale |
|---|---|---|
| Auth and onboarding completion are separate | Approved | Identity success is not product readiness |
| Existing completed user → Home | Approved | Required returning-user behavior |
| New/uninitialized user → bootstrap → Onboarding | Approved | Account bootstrap is separate from identity |
| One navigation owner after auth success | Approved | Prevents page/router races |
| Missing local AppMode must not downgrade authoritative completion | Approved | AppMode is not completion |
| Welcome legal footer remains absent | Approved | Intentional product UI |
| AuthLanding legal footer remains present | Approved | Intentional legal placement |
| Login vs EmailLogin consolidation | Deferred | Separate reference-audited task |
| Durable user-associated AppMode source/recovery strategy | Needs verification | Current local cache may be absent/stale |
| Exact idempotent account provisioning/bootstrap mechanism | Needs verification | Must align with current Supabase schema and #5 provisioning direction |

Do not start production source edits until the two `Needs verification` items are resolved from current runtime/schema/contracts.

## 4. Architecture Design

### Chosen Direction

Evolve existing providers/repositories into one authoritative bootstrap/readiness result. Do not create a parallel architecture unless the existing structure cannot support the contract.

```text
Auth identity/session
        ↓
Account/bootstrap resolver
        ↓
App user + onboarding readiness
        ↓
Router redirect
        ↓
UI renders destination
```

UI must not query Supabase tables to decide Home vs Onboarding.

Conceptual states may be:

```text
loading
unauthenticated
newUserRequiresOnboarding
existingUserRequiresOnboarding
ready
error
```

Exact names must follow existing architecture after exploration.

## 5. Implementation Plan

### Slice A — Verification only

- [ ] Confirm local branch is `codex/onboarding-mode-migration`.
- [ ] Record `git status --short --branch` and protected unrelated changes.
- [ ] Re-run auth/onboarding/AppMode reference trace locally.
- [ ] Inspect current Supabase user provisioning/bootstrap path.
- [ ] Determine durable/recoverable confirmed AppMode source for returning users.
- [ ] Freeze exact routing matrix and failure behavior in this task.

### Slice B — Tests first

- [ ] existing Google user + completed onboarding → Home
- [ ] existing Google user + incomplete onboarding → Onboarding
- [ ] existing `inProgress` → resume Onboarding
- [ ] first-time Google user → idempotent bootstrap → Onboarding
- [ ] first-time user cannot reach Home before completion
- [ ] completed cold start → Home
- [ ] logout → same Google account → Home
- [ ] Google callback retry does not duplicate account bootstrap
- [ ] missing AppMode does not downgrade authoritative completed onboarding
- [ ] completion failure does not publish backend completed flag
- [ ] router decision matrix direct coverage

### Slice C — Minimal implementation

- [ ] Introduce/evolve one bootstrap/readiness owner.
- [ ] Move app-user/onboarding lookup out of auth widgets.
- [ ] Remove competing navigation ownership after auth success.
- [ ] Make cold start and login callback consume the same readiness result.
- [ ] Separate AppMode recovery from onboarding completion.
- [ ] Make account bootstrap retry-safe/idempotent.
- [ ] Move backend completion publication to the true final success boundary.

### Slice D — Quality review

- [ ] targeted auth/app/onboarding tests pass
- [ ] relevant analyzer passes
- [ ] existing Login/AuthLanding rendering tests remain green
- [ ] no unintended mobile visual changes
- [ ] diff contains no unrelated worktree changes

## 6. Quality Review

### Validation Run

```text
Not run yet. Step 1 task brief only.
```

### Review Findings And Resolution

- Production source has not been changed by this task brief creation.
- Next action is local read-only Slice A verification on `codex/onboarding-mode-migration`.

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/auth-session-bootstrap-routing.md
```

### Actual Behavior

No runtime behavior changed in Step 1.

### Known Limitations

Local worktree status and current post-doc-commit source references still need to be checked before production edits.

### Final Status

`REVIEW`
