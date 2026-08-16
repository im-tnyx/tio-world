# Google Identity Ownership & Bootstrap Loading

**Status:** In progress — Google auth succeeds; client bootstrap/Splash handoff is active P0
**Primary owner:** `apps/features/auth` + `apps/app` + `apps/features/onboarding` + `apps/features/splash`
**Affected platforms:** Flutter phone app + Supabase/Firebase auth boundary
**Tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`

## 1. User-reported incident

A Google-created account can remain stuck in loading during sign-in. Later fixes removed the login-button infinite wait and a disposed-controller crash, but real-device testing now reaches Splash and remains on its spinner instead of routing Home.

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

The latest device log shows Android Google `SignInHubActivity` opens and returns to `MainActivity`. The app then reaches Splash but does not leave the spinner.

Combined with the live Supabase state above, the active failure is now client-side bootstrap/router propagation, not Google credential rejection and not missing onboarding completion data.

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

## 4. Implemented slices

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

The latest device run proves Google native selection returns and Supabase records a successful sign-in, so the remaining blocker has moved past Google auth itself.

## 5. Active Slice B4 — prevent bootstrap reset loops after successful login

Implemented on branch, local validation pending:

- [x] add debug-only `[SessionBootstrap]` stage/state diagnostics;
- [x] track the active authenticated Supabase user id;
- [x] ignore duplicate authenticated events for the same active user while bootstrap is Loading/Ready/RequiresOnboarding;
- [x] explicit `refresh()` still force-resolves for Retry/manual recovery;
- [x] prevent `signedIn` / `tokenRefreshed` style duplicate events from repeatedly pushing Ready back to Loading;
- [x] add regression proving duplicate same-user auth events do not restart completion lookup or downgrade Ready;
- [x] expose Supabase `SignInSuccess` callback from `AuthLandingPage` for a later explicit router handoff if still needed;
- [ ] `app_session_bootstrap_controller_test.dart` passes locally (expected 10 total);
- [ ] app analyzer passes locally;
- [ ] auth landing regression remains green;
- [ ] real-device Splash reaches Home for the latest completed Google account.

Expected debug sequence for this existing completed account:

```text
[SessionBootstrap] auth event: AuthSessionAuthenticated
[SessionBootstrap] completion lookup started ...
[SessionBootstrap] completion lookup result: RemoteOnboardingCompletionState.completed
[SessionBootstrap] state: AppSessionBootstrapLoading -> AppSessionBootstrapReady
```

Duplicate same-user events should log:

```text
[SessionBootstrap] duplicate authenticated event ignored for active user
```

and must not restart Splash loading.

## 6. If B4 still reproduces

Next narrow follow-up, without redesign:

1. Wire `AuthLandingPage.onSignInSuccess` and existing `LoginPage.onSignInSuccess` to an explicit `AppSessionBootstrapController.refresh()` in the app router.
2. Make the `/splash` builder directly listen to `AppSessionBootstrapController` so a same-location Failure state cannot remain visually stuck on an old spinner frame.
3. Add router-level regression for `SignInSuccess -> completed remote -> Home`.

Do this only if B4 diagnostics show the controller is not reaching Ready or the router fails to react to Ready.

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
app_session_bootstrap_controller_test.dart: 10 passed
app_session_route_policy_test.dart: 4 passed
app analyze: No issues found
auth_landing_page_test.dart: 2 passed
auth analyze: No issues found
worktree: clean
```
