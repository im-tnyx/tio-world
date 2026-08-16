# Google Identity Ownership & Bootstrap Loading

**Status:** In progress — exact bootstrap provider self-disposal root cause fixed; local/device validation pending
**Primary owner:** `apps/features/auth` + `apps/app` + `apps/features/onboarding` + `apps/features/splash`
**Affected platforms:** Flutter phone app + Supabase/Firebase auth boundary
**Tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`

## 1. User-reported incident

A Google-created account can remain stuck in loading during sign-in. Reliability fixes removed the login-button infinite wait and an earlier disposed-controller exception, but real-device testing still reached Splash and remained on its spinner instead of routing Home.

## 2. Verified evidence

### Production identity path

- Current production Continue with Google is Supabase-first.
- `SupabaseAuthSignInRepository.signInWithGoogle()` establishes Supabase GoTrue auth.
- Firebase packages exist but Firebase is not initialized/configured as the active production auth capability.
- `firebase_uid` therefore remains non-canonical/unreliable and must not gate login.

### Live Supabase read-only evidence

The affected device attempt was checked read-only:

- the latest Google `auth.users.last_sign_in_at` updated at the device-test time;
- that authenticated Google identity has a matching `public.users` row;
- that row has `is_onboarded = true`;
- backend/account state is valid for returning-user Home routing;
- a second older Google auth identity still exists without a `public.users` row and remains a separate reconciliation concern.

No production DB mutation was performed.

### Decisive latest device evidence

After Slice B5, the fresh app run logged:

```text
[SessionBootstrap] start
[SessionBootstrap] auth event: AuthSessionAuthenticated
[SessionBootstrap] resolve generation=1 state=AuthSessionAuthenticated
[SessionBootstrap] completion lookup started generation=1
[SessionBootstrap] auth event: AuthSessionAuthenticated
[SessionBootstrap] duplicate authenticated event ignored for active user
[SessionBootstrap] completion lookup result: RemoteOnboardingCompletionState.completed
[SessionBootstrap] dispose
[SessionBootstrap] reconcile result ignored as stale generation=1
```

This is decisive:

- Google/Supabase authentication is already restored successfully;
- durable completion lookup succeeds and returns `completed`;
- the bootstrap controller is disposed **during its own `reconcileRemote()` path** before it can publish Ready;
- Splash therefore stays Loading even though backend state is correct.

The active root cause is provider ownership, not Google credentials, Supabase auth, onboarding completion data, or router redirect policy.

## 3. Frozen product decisions

- Do not delete/rewrite existing auth users during this task.
- Do not backfill `firebase_uid` until canonical auth ownership is explicitly chosen.
- Do not treat backend/network lookup failure as a new user.
- Preserve normal Login/AuthLanding/Splash visuals except explicit recovery/error states.
- #8 profile/account persistence stays paused while this P0 is active.

### Login account-admission rule

Login is **sign-in-only** and must not silently create a new Tio account.

```text
Google Login
→ existing Tio account check
→ account exists: continue login
→ no account: remain on Login
             show “No Tio account found for this Google account.
                   Create a Tio account first to continue.”
             do not create auth/application owner state
```

Account creation belongs only to explicit signup/onboarding creation intent.

## 4. Completed reliability slices

### Slice A — secondary post-auth work removed from critical path

Locally validated:

- device sync non-blocking;
- Google profile enrichment non-blocking;
- auth repo tests passed;
- AuthLanding/Login regressions passed;
- auth analyzer clean.

### Slice B — bootstrap timeout + recoverable Splash failure

Locally validated:

- completion lookup bounded to 8 seconds;
- lookup error/timeout becomes `AppSessionBootstrapFailure`;
- failure-only Splash feedback + Retry;
- bootstrap/controller/route-policy/Splash tests green;
- analyzers clean.

### Slice B2 — controller disposal safety

Locally validated:

- late async results cannot notify a disposed controller;
- in-flight generation invalidated on dispose;
- focused controller suite reached 9 passing tests;
- app analyzer clean;
- previous used-after-dispose exception no longer appears.

### Slice B3 — bounded Google auth critical path

Locally validated:

- native account selection bounded;
- Google credential read bounded;
- Supabase ID-token exchange bounded;
- stage-specific controlled failures added;
- `supabase_auth_sign_in_repository_test.dart`: 9 passed;
- `auth_landing_page_test.dart`: 2 passed;
- auth analyzer: No issues found.

### Slice B4 — coalesce duplicate same-user auth events

Locally validated:

- active authenticated user tracked;
- duplicate same-user auth events do not restart bootstrap;
- explicit refresh still force-resolves;
- `app_session_bootstrap_controller_test.dart`: 10 passed;
- `app_session_route_policy_test.dart`: 4 passed;
- app analyzer clean;
- AuthLanding regression 2 passed;
- auth analyzer clean.

### Slice B5 — stable GoRouter ownership + deterministic login handoff

Implemented:

- top-level auth-product `watch` removed from `goRouterProvider`;
- existing GoRouter remains the routing owner across auth transitions;
- Supabase `SignInSuccess` explicitly triggers bootstrap refresh;
- Splash listens directly to bootstrap state for failure/retry rendering;
- large router diff audited with no unrelated route/UI drift.

Local validation attempt exposed a **test-only compile error** in the new provider-stability regression because `TioThemeMode` was not imported. Existing controller/route/auth tests remained green.

The subsequent device run then exposed the deeper provider self-disposal root cause below.

## 5. Active Slice B6 — stable bootstrap provider ownership during reconciliation

### Exact root cause

`appSessionBootstrapControllerProvider` constructed the controller with watched dependencies:

```dart
authSessionRepository: ref.watch(authSessionRepositoryProvider),
onboardingCompletionRepository: ref.watch(onboardingCompletionRepositoryProvider),
onboardingStatusController: ref.watch(onboardingStatusControllerProvider),
```

During a successful completed-user resolution:

```text
completion lookup → completed
→ await OnboardingStatusController.reconcileRemote(completed)
→ reconcileRemote updates local status / notifyListeners()
→ watched onboardingStatusControllerProvider invalidates bootstrap provider
→ current AppSessionBootstrapController is disposed
→ in-flight generation becomes stale
→ Ready is never published
→ Splash remains Loading
```

A bootstrap controller that owns the auth-session subscription must not be reconstructed from notifications emitted by a collaborator it mutates during reconciliation.

### Implemented on branch

- [x] change bootstrap constructor dependencies from `ref.watch(...)` to stable `ref.read(...)` ownership;
- [x] keep auth-session changes owned by the controller's existing `sessionState` subscription;
- [x] prevent `OnboardingStatusController.notifyListeners()` from disposing/recreating bootstrap mid-resolution;
- [x] fix provider-stability test compile error by importing `tio_core/core.dart` for `TioThemeMode`;
- [x] extend provider-stability regression to assert both:
  - auth product invalidation does not replace the GoRouter instance;
  - onboarding-status notification does not replace the AppSessionBootstrapController instance;
- [x] production provider diff audited and isolated to ownership semantics.

### Expected runtime after B6

```text
[SessionBootstrap] completion lookup result: RemoteOnboardingCompletionState.completed
→ reconcileRemote completes
→ controller remains alive
→ [SessionBootstrap] state: AppSessionBootstrapLoading -> AppSessionBootstrapReady
→ stable GoRouter redirects /splash -> Home
```

The following sequence must **not** occur anymore:

```text
completion lookup result: completed
[SessionBootstrap] dispose
reconcile result ignored as stale
```

### Local/device validation pending

- [ ] `router_provider_stability_test.dart`: 1 passed;
- [ ] `app_session_bootstrap_controller_test.dart`: 10 passed;
- [ ] `app_session_route_policy_test.dart`: 4 passed;
- [ ] app analyzer: No issues found;
- [ ] fresh device launch reaches Home for the verified completed Google account;
- [ ] console shows `Loading -> Ready` before any controller dispose;
- [ ] cold reopen also reaches Home without permanent Splash.

## 6. Production auth source of truth / later account admission

Current schema and RLS strongly favor:

```text
Supabase-first
→ auth.users.id = canonical identity
→ firebase_uid = optional/legacy
```

Firebase-first/hybrid requires an explicit Firebase-to-Supabase session/RLS bridge and must not be partially enabled.

After login reliability is closed:

- implement the login-only existing-account admission contract;
- reconcile the older Google identity that lacks `public.users` safely;
- keep DB-owned auth-user provisioning under issue #5;
- resume issue #8 persistence work.

## 7. Next local validation gate

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/router_provider_stability_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_bootstrap_controller_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_route_policy_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

Expected:

```text
router_provider_stability_test.dart: 1 passed
app_session_bootstrap_controller_test.dart: 10 passed
app_session_route_policy_test.dart: 4 passed
app analyze: No issues found
worktree: clean
```

Then terminate any old `flutter run` process and perform a fresh device run. For the already verified completed account, expected console tail is:

```text
[SessionBootstrap] completion lookup result: RemoteOnboardingCompletionState.completed
[SessionBootstrap] state: AppSessionBootstrapLoading -> AppSessionBootstrapReady
```

followed by Home.
