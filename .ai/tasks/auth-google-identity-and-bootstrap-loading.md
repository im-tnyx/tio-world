# Google Identity Ownership & Bootstrap Loading

**Status:** In progress — Google auth/backend state verified; router ownership/handoff fix implemented, local validation pending
**Primary owner:** `apps/features/auth` + `apps/app` + `apps/features/onboarding` + `apps/features/splash`
**Affected platforms:** Flutter phone app + Supabase/Firebase auth boundary
**Tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`

## 1. User-reported incident

A Google-created account can remain stuck in loading during sign-in. Later fixes removed the login-button infinite wait and a disposed-controller crash, but real-device testing still reaches Splash and remains on its spinner instead of routing Home.

## 2. Verified evidence

### Production identity path

- Current production Continue with Google is Supabase-first.
- `SupabaseAuthSignInRepository.signInWithGoogle()` establishes Supabase GoTrue auth.
- Firebase packages exist but Firebase is not initialized/configured as the active production auth capability.
- `firebase_uid` therefore remains non-canonical/unreliable and must not gate login.

### Live Supabase read-only evidence

Latest device attempt was checked read-only after the reported Splash hang:

- latest Google `auth.users.last_sign_in_at` updated at the time of the device test;
- the latest authenticated Google identity has a matching `public.users` row;
- that row has `is_onboarded = true`;
- therefore the backend/account state for this attempt is valid for returning-user Home routing;
- a second older Google auth identity still exists without a `public.users` row and remains a separate reconciliation concern.

No production DB mutation was performed.

### Real-device lifecycle evidence

An earlier device log showed:

```text
Unhandled Exception: A AppSessionBootstrapController was used after being disposed.
```

The lifecycle guard fix is locally validated and subsequent device runs no longer show this exception.

### Current real-device evidence

The latest device log shows Android Google `SignInHubActivity` opens and returns to `MainActivity`. Supabase records the sign-in, and the canonical owner row is completed. The app nevertheless remains on Splash.

Therefore the active P0 is client-side bootstrap/router ownership and handoff, not Google credential rejection and not missing onboarding completion data.

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
- disposed-controller device exception no longer appears.

### Slice B3 — bounded Google auth critical path

Locally validated:

- native account selection bounded;
- Google credential read bounded;
- Supabase ID-token exchange bounded;
- stage-specific controlled failures added;
- `supabase_auth_sign_in_repository_test.dart`: 9 passed;
- `auth_landing_page_test.dart`: 2 passed;
- auth analyzer: No issues found;
- worktree clean.

The device run proves Google native selection returns and Supabase records a successful sign-in, so the blocker has moved past Google auth itself.

### Slice B4 — coalesce duplicate same-user auth events

Locally validated:

- [x] add debug-only `[SessionBootstrap]` stage/state diagnostics;
- [x] track active authenticated Supabase user id;
- [x] ignore duplicate authenticated events for the same active user while bootstrap is Loading/Ready/RequiresOnboarding;
- [x] explicit `refresh()` force-resolves for Retry/manual recovery;
- [x] prevent signed-in/token-refresh style duplicate events from restarting completion lookup or downgrading Ready;
- [x] regression proves duplicate same-user events do not restart bootstrap;
- [x] expose Supabase `SignInSuccess` callback from `AuthLandingPage`;
- [x] `app_session_bootstrap_controller_test.dart`: 10 passed;
- [x] `app_session_route_policy_test.dart`: 4 passed;
- [x] app analyzer: No issues found;
- [x] `auth_landing_page_test.dart`: 2 passed;
- [x] auth analyzer: No issues found;
- [x] final reported worktree clean and synchronized.

Despite B4 being green, the real device still remains on Splash, so the issue is now router ownership/handoff rather than controller duplicate-event churn.

## 5. Active Slice B5 — stable GoRouter ownership + deterministic post-login bootstrap handoff

### Root cause found

`goRouterProvider` was directly watching `authProductStateProvider`:

```text
Google/Supabase auth event
→ authSessionStateProvider changes
→ authProductStateProvider changes
→ goRouterProvider invalidates/rebuilds
→ old GoRouter is disposed
→ new GoRouter starts at initialLocation /splash
```

This violates router ownership: an authentication state transition should refresh redirects through the existing router/bootstrap listenables, not recreate the router object itself.

### Implemented on branch

- [x] remove top-level `ref.watch(authProductStateProvider)` from `goRouterProvider`;
- [x] use stable `ref.read(supabaseClientProvider)` for the client object;
- [x] resolve dynamic auth readiness inside onboarding callbacks with `ref.read(authProductStateProvider)` at invocation time;
- [x] preserve dynamic `SupabaseClient.auth.currentUser` checks instead of freezing auth readiness at router construction;
- [x] wire `AuthLandingPage.onSignInSuccess` to explicit `AppSessionBootstrapController.refresh()`;
- [x] wire `LoginPage.onSignInSuccess` to explicit bootstrap refresh for email/social login consistency;
- [x] make `/splash` directly listen to `AppSessionBootstrapController` so Failure/Retry state cannot remain visually stale while staying on the same route;
- [x] add focused `router_provider_stability_test.dart`: invalidating auth product state must not replace the `GoRouter` instance;
- [x] audit large `router.dart` commit diff: only intended auth/session hunks changed; no unrelated route/UI drift.

### Expected runtime for the currently verified account

```text
Continue with Google
→ Supabase SignInSuccess
→ explicit bootstrap refresh
→ current auth user read
→ public.users.is_onboarded == true
→ AppSessionBootstrapReady
→ existing GoRouter redirect
→ Home
```

There must be no new router construction/reset to `/splash` during the auth transition.

### Local validation pending

- [ ] `router_provider_stability_test.dart`: 1 passed;
- [ ] `app_session_bootstrap_controller_test.dart`: 10 passed;
- [ ] `app_session_route_policy_test.dart`: 4 passed;
- [ ] app analyzer: No issues found;
- [ ] auth landing regression: 2 passed;
- [ ] real-device existing completed Google account reaches Home;
- [ ] cold reopen reaches Home without permanent Splash.

## 6. Expected diagnostics after B5

For the verified completed account:

```text
[GoogleAuth] sign-in completed successfully
[SessionBootstrap] refresh requested
[SessionBootstrap] refresh auth state: AuthSessionAuthenticated
[SessionBootstrap] completion lookup started ...
[SessionBootstrap] completion lookup result: RemoteOnboardingCompletionState.completed
[SessionBootstrap] state: AppSessionBootstrapLoading -> AppSessionBootstrapReady
```

Duplicate same-user auth events may additionally log:

```text
[SessionBootstrap] duplicate authenticated event ignored for active user
```

They must not restart Splash loading.

## 7. Production auth source of truth / later account admission

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

## 8. Next local validation gate

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/router_provider_stability_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_bootstrap_controller_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_route_policy_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World\apps\features\auth"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/presentation/auth_landing_page_test.dart"
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
auth_landing_page_test.dart: 2 passed
auth analyze: No issues found
worktree: clean
```
