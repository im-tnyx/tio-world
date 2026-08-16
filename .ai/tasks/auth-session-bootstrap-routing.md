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
- broad Firebase legacy cleanup unrelated to this slice.

## 2. Codebase Exploration

### Verified Evidence

- `LoginPage` directly queries `public.users.is_onboarded` and navigates after auth.
- `AuthLandingPage` duplicates the same DB lookup/navigation and owns the legal footer that must remain.
- `router.dart` also navigates through `onSignInSuccess`, creating competing navigation ownership.
- Splash callback directly queries `public.users.is_onboarded`.
- `appModeRoutePolicy` currently defines completion as `OnboardingStatus.completed && selectedMode != null`.
- `OnboardingStatusController` currently downgrades completed status when AppMode is missing and can infer completion from legacy AppMode alone.
- Auth domain already has `AuthSessionState`; do not create a duplicate auth-session hierarchy.
- Current production auth session adapter is Supabase-backed.
- Google sign-in attempts profile metadata upsert before onboarding, so raw row existence must not be the returning-user criterion.
- Live `public.users` has several NOT NULL profile fields; a first-time metadata-only upsert may fail until full onboarding data exists.
- `SupabaseProfileSetupRepository.saveProfileSetup()` currently writes `is_onboarded: true` during Profile owner persistence, before Workout/Targets persistence necessarily succeeds.
- `CompleteOnboardingUseCase` is the existing completion coordinator and should own final completion publication sequencing.

### Tests Already Relevant

- `apps/app/test/app/app_mode_route_policy_test.dart`
- `apps/app/test/app/onboarding_status_controller_test.dart`
- auth presentation tests
- onboarding completion/use-case tests

Current tests that expect `completed + selectedMode == null → onboarding/notStarted` must be deliberately revised.

### Local Verification Completed

The local worktree was reported clean, synchronized, and on:

```text
codex/onboarding-mode-migration
```

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Authentication state source | Made | Reuse existing `AuthSessionState` | Auth |
| Durable onboarding truth | Made | `public.users.is_onboarded` is returning-user completion authority | Onboarding |
| Missing backend user row | Made | Requires onboarding; not completed and not an error | App/Onboarding |
| Backend lookup error | Made | Bootstrap failure/Splash retry; never classify as new user | App |
| AppMode semantics | Made | Shell/personalization preference, not completion proof | App |
| Missing local AppMode for completed user | Made | Allow Home; do not restart onboarding | App |
| Durable AppMode recovery | Deferred | No current user-associated durable source exists; do not invent one in #7 | App |
| Product navigation owner | Made | Router consumes one app bootstrap state | App |
| Returning completed user | Made | Home, never Congratulations | App |
| Congratulations ownership | Made | Fresh successful onboarding completion only | Onboarding/App |
| Client-side app-user provisioning | Rejected | #5 owns DB provisioning trigger; #7 handles missing row safely | Supabase/App |
| Legal footer ownership | Made | Preserve AuthLanding placement; Welcome remains without footer | Auth/Welcome |

## 4. Architecture Design

### Chosen Approach

Reuse existing auth-session contracts, add one onboarding-owned remote completion repository, and compose both in one app-level bootstrap controller.

#### Auth identity

```text
AuthSessionRepository
→ AuthSessionState
```

`LoginPage` and `AuthLandingPage` authenticate and emit success/failure only. They do not read `public.users` and do not choose Home/Onboarding/Congratulations.

#### Durable onboarding completion contract

Add under `apps/features/onboarding`:

```text
RemoteOnboardingCompletionState
- uninitialized
- incomplete
- completed

OnboardingCompletionRepository
- readForUser(userId)
- markCompleted(userId)
```

Supabase implementation owns only the `public.users.is_onboarded` read/write boundary.

A missing row is `uninitialized` and routes to onboarding. The repository does not provision users.

#### App bootstrap state

Add under `apps/app/lib/app/session/`:

```text
loading
unauthenticated
requiresOnboarding
ready
failure
```

`AppSessionBootstrapController` composes:

```text
AuthSessionRepository
+ OnboardingCompletionRepository
+ local OnboardingStatusController/Repository for cache reconciliation
→ AppSessionBootstrapState
```

Rules:

- auth unresolved → loading;
- unauthenticated → unauthenticated;
- authenticated + remote uninitialized/incomplete → requiresOnboarding;
- authenticated + remote completed → ready;
- remote timeout/error → failure;
- stale in-flight result from an older user/session cannot overwrite a newer auth state.

Remote completion is authoritative for routing. Local SharedPreferences onboarding state becomes cache/flow state only.

#### Local onboarding reconciliation

`OnboardingStatusController` must stop deriving completion from AppMode and stop downgrading completion because AppMode is missing.

When remote state resolves:

- remote completed → reconcile local status to completed;
- remote uninitialized/incomplete → ensure stale local completed state cannot bypass onboarding;
- local `inProgress` may remain useful only for the currently authenticated onboarding flow.

No route decision may depend on AppMode to determine completion.

#### Router precedence

```text
1. AppSessionBootstrapState
2. AppMode shell policy after bootstrap == ready
```

Behavior:

```text
loading/failure
→ Splash

unauthenticated
→ existing public auth/welcome routes

requiresOnboarding
→ Onboarding

ready
→ Home for Splash/Auth/Login/Onboarding entry routes
→ then enforce mode-specific shell restrictions
```

`Congratulations` is not a generic ready destination.

#### AppMode policy

Change completion semantics from:

```text
completed && selectedMode != null
```

to:

```text
completed
```

If completed but `selectedMode == null`:

- Home remains accessible;
- mode-specific shell destinations fall back to Home;
- profile/settings must not force full onboarding;
- no completion mutation occurs.

Durable cross-device AppMode recovery is intentionally deferred because no current backend source exists.

#### Splash ownership

Preserve Splash visual tree exactly. Remove Splash-owned product navigation/query logic and let router redirects react to bootstrap state.

#### Completion publication order

Remove `is_onboarded: true` from `SupabaseProfileSetupRepository.saveProfileSetup()`.

Required completion sequence:

```text
1. validate final onboarding draft
2. persist all required owner data
3. run any configured non-completion finalization
4. persist confirmed local AppMode
5. mark backend onboarding completed (`is_onboarded = true`)
6. update local onboarding completed cache
7. clear obsolete draft best-effort
8. caller navigates to Congratulations
```

If backend completion publication fails, local completion must not be published. If local cache write fails after backend completion, next bootstrap recovers from backend truth.

### Ownership and Data Flow

```text
LoginPage / AuthLandingPage
        |
        | authentication only
        v
AuthSessionRepository ───────────────┐
                                     v
                         AppSessionBootstrapController
                                     ^
                                     |
OnboardingCompletionRepository ──────┘
        |
        v
public.users.is_onboarded

AppSessionBootstrapController
        |
        v
GoRouter redirect
        |
        +--> Auth / Welcome
        +--> Onboarding
        +--> Home

Fresh onboarding finish
        |
        v
CompleteOnboardingUseCase
        |
        +--> Profile owner persistence
        +--> Workout owner persistence when active
        +--> Targets/Nutrition owner persistence
        +--> confirmed AppMode
        +--> backend completion publication
        +--> local completed cache
        v
Congratulations
```

### Alternative Rejected

- DB queries in auth widgets: duplicated data/routing authority.
- Row existence as returning-user proof: incompatible with provisioning/profile-enrichment flows.
- AppMode as completion proof: local preference can be absent/stale.
- Another auth-session state hierarchy: existing `AuthSessionState` already owns identity lifecycle.
- Client provisioning in #7: conflicts with #5 DB-owned direction.
- Backend lookup failure → onboarding: transient failure would misclassify returning users.

### Failure and Accessibility States

- Backend readiness failure stays on the existing Splash surface rather than presenting false onboarding.
- Existing auth error UI remains sign-in failure surface.
- No auth/splash/onboarding visual hierarchy, focus order, semantics, legal text, labels, sizes, spacing, or assets change.

## 5. Implementation Plan

### Slice A — Tests first

- [ ] existing completed Google user → Home
- [ ] existing completed email user → Home
- [ ] incomplete/uninitialized authenticated user → Onboarding
- [ ] `inProgress` current-user flow resumes Onboarding
- [ ] completed cold start → Home
- [ ] logout → same completed account → Home after sign-in
- [ ] missing local AppMode does not restart onboarding
- [ ] backend lookup error stays failure/Splash, not onboarding
- [ ] stale user bootstrap result cannot win after auth state changes
- [ ] completion owner failure does not publish backend/local completed state
- [ ] returning login never routes to Congratulations

### Slice B — Domain/data boundary

- [ ] add `OnboardingCompletionRepository` + remote completion state
- [ ] add Supabase implementation with focused tests
- [ ] remove early `is_onboarded` publication from Profile owner save
- [ ] inject backend completion publication into `CompleteOnboardingUseCase`

### Slice C — App bootstrap/routing

- [ ] add `AppSessionBootstrapController`
- [ ] reconcile local onboarding status without AppMode coupling
- [ ] wire controller into router `refreshListenable`
- [ ] make router redirect bootstrap-first
- [ ] remove Splash direct DB query/navigation ownership

### Slice D — Auth presentation cleanup

- [ ] remove direct Supabase import/query/navigation from `LoginPage`
- [ ] remove direct Supabase import/query/navigation from `AuthLandingPage`
- [ ] preserve AuthLanding `TioTermsDisclaimer`
- [ ] keep Login/AuthLanding visual output unchanged

### Slice E — Quality review

- [ ] targeted tests pass
- [ ] relevant analyzer passes
- [ ] auth/splash rendering tests remain green
- [ ] no unintended visual changes
- [ ] no issue #8 persistence work accidentally bundled
- [ ] no unrelated local changes staged

## 6. Quality Review

### Validation Run

```text
Not run yet. Architecture is frozen; production implementation has not started.
```

### Review Findings and Resolution

- Local branch/worktree verification completed before design freeze.
- Read-only live Supabase inspection used only to verify schema assumptions; no DB writes were made.
- Profile/account persistence defects discovered during this work are tracked separately in issue #8 / `.ai/tasks/profile-account-data-persistence.md`.

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/auth-session-bootstrap-routing.md
```

### Actual Behavior

No runtime behavior changed yet.

### Known Limitations

- Durable cross-device AppMode persistence is not available today and is not invented in this task.
- DB-owned auth-user provisioning remains issue #5.

### Final Status

`REVIEW`
