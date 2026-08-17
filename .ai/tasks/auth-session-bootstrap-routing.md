# Auth Session Bootstrap Routing

**Status:** Complete
**Primary owner:** `apps/app` + `apps/features/auth` + `apps/features/onboarding`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #7
**Source branch:** `codex/onboarding-mode-migration`

## 1. Discovery

### User Outcome

Authentication success and product onboarding completion now resolve through one app-level bootstrap state.

```text
unauthenticated → Auth
authenticated + remote uninitialized/incomplete → Onboarding
authenticated + remote completed → Home
backend readiness failure → Splash/failure
```

### Guardrails

- Phone UI styling/layout remained frozen.
- `AuthLandingPage` keeps `TioTermsDisclaimer` exactly where it was.
- Welcome legal footer remains removed.
- DB-owned auth-user provisioning trigger remains issue #5.
- Profile/account persistence defects remain issue #8.
- Per-action loading and unavailable Truecaller behavior remain issue #9.

## 2. Verified Root Causes Resolved

- AppMode is no longer proof of onboarding completion.
- Local completed state is no longer downgraded because AppMode is missing.
- Durable `public.users.is_onboarded` read/write ownership is isolated behind `OnboardingCompletionRepository`.
- Profile owner save no longer publishes `is_onboarded=true` early.
- Completion is published only after required owner persistence + confirmed AppMode.
- `AppSessionBootstrapController` composes auth session + durable completion + local cache reconciliation.
- Stale async results from an older user/session cannot overwrite a newer auth state.
- GoRouter is bootstrap-first, then AppMode shell policy only when ready.
- Splash no longer queries Supabase or chooses product destination.
- Login/AuthLanding no longer query `public.users` or choose Home/Onboarding/Congratulations.
- Router no longer supplies competing `LoginPage.onSignInSuccess` destination navigation.

## 3. Frozen Architecture

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

Remote completion is routing authority. SharedPreferences onboarding/AppMode state is cache/flow/shell state only.

Fresh successful onboarding completion order:

```text
validate draft
→ persist owner data
→ non-completion finalization
→ persist confirmed AppMode
→ publish backend is_onboarded=true
→ publish local completed cache
→ clear draft best-effort
→ mark bootstrap ready
→ Congratulations (fresh completion only)
```

Returning completed users route Home and never use Congratulations as a login-success destination.

## 4. Implementation Status

### Slice A — AppMode/completion decoupling

- [x] completed remains completed with missing AppMode
- [x] Home remains available with completed + no AppMode
- [x] mode-specific shell paths fall back Home when mode is missing

### Slice B — Durable completion boundary

- [x] remote completion state + repository contract
- [x] Supabase completion repository
- [x] early profile-owned completion publication removed
- [x] `CompleteOnboardingUseCase` publishes backend completion before local completed cache

### Slice C — App bootstrap/router

- [x] `AppSessionBootstrapController`
- [x] local cache reconciliation
- [x] stale-session generation guard
- [x] bootstrap-first router redirect
- [x] passive Splash with rendered UI preserved
- [x] post-completion ready publication

### Slice D — Auth presentation cleanup

- [x] Login direct Supabase completion query/navigation removed
- [x] AuthLanding direct Supabase completion query/navigation removed
- [x] AuthLanding post-signup product-destination handling removed
- [x] router `LoginPage.onSignInSuccess` destination callback removed
- [x] AuthLanding legal disclaimer preserved
- [x] Login/AuthLanding visual composition preserved

## 5. Regression Coverage

Provider-specific authentication now feeds the same provider-independent bootstrap policy, so Google/email route outcomes do not have separate destination code paths.

- [x] completed authenticated state → Home
- [x] incomplete/uninitialized authenticated state → Onboarding
- [x] local in-progress flow remains onboarding flow state while remote completion is incomplete
- [x] completed cold-start bootstrap → Home
- [x] missing AppMode cannot restart completed onboarding
- [x] backend lookup error → failure/Splash, never classify as new
- [x] stale old-user lookup cannot overwrite newer auth state
- [x] completion failure cannot publish local completed after backend failure
- [x] returning auth presentation does not route Congratulations
- [x] Login/AuthLanding do not own direct DB navigation decisions

DB-owned first-auth provisioning/idempotent trigger work is intentionally not claimed here and continues under issue #5.

## 6. Local Validation Evidence

```text
Slice A — apps/app
app_mode_route_policy_test.dart: 9 passed
onboarding_status_controller_test.dart: 6 passed
flutter analyze: No issues found

Slice B — apps/features/onboarding
complete_onboarding_remote_completion_test.dart: 2 passed
supabase_onboarding_completion_repository_test.dart: 3 passed
complete_onboarding_use_case_test.dart: 13 passed
flutter analyze: No issues found

Slice B — apps/features/profile
flutter analyze: No issues found

Slice C — apps/app
app_session_bootstrap_controller_test.dart: 6 passed
app_session_route_policy_test.dart: 4 passed
app_mode_route_policy_test.dart: 9 passed
onboarding_status_controller_test.dart: 6 passed
flutter analyze: No issues found

Slice C — apps/features/splash
splash_screen_test.dart: 5 passed
flutter analyze: No issues found

Slice D — apps/features/auth
login_page_test.dart: 6 passed
auth_landing_page_test.dart: 1 passed
flutter analyze: No issues found

Slice D regression — apps/app
app_session_bootstrap_controller_test.dart: 6 passed
app_session_route_policy_test.dart: 4 passed
flutter analyze: No issues found

Final reported worktree: clean and synchronized.
```

Auth test runner emitted existing non-failing package/SVG warnings (`uses-material-design` mismatch and SVG `<style/>` notice); tests and analyzer remained green.

## 7. Final Handoff

### Actual Behavior

Cold start and post-auth now consume one readiness owner. Returning completed users resolve Home, incomplete/uninitialized users resolve Onboarding, and backend lookup failures remain controlled failure rather than false new-user classification.

### Deferred / Related

- Issue #5: DB-owned auth-user provisioning and broader production hardening.
- Issue #8: profile/account persistence consistency.
- Issue #9: action-scoped Login loading + unavailable Truecaller informational message.

### Final Status

`COMPLETE`
