# Google Identity Ownership & Bootstrap Loading

**Status:** In progress — lifecycle crash locally validated; Google critical-path timeout diagnostics implemented
**Primary owner:** `apps/features/auth` + `apps/app` + `apps/features/onboarding` + `apps/features/splash`
**Affected platforms:** Flutter phone app + Supabase/Firebase auth boundary
**Tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`

## 1. User-reported incident

A Google-created account can remain stuck in loading during sign-in. Reopening the app can still show loading. The corresponding `public.users.firebase_uid` is not populated.

Real-device logs exposed an additional concrete lifecycle failure:

```text
Unhandled Exception: A AppSessionBootstrapController was used after being disposed.
AppSessionBootstrapController._setState
AppSessionBootstrapController._resolve
```

That failure reproduced around app background/hot-restart lifecycle while an asynchronous bootstrap resolution was still in flight. The lifecycle patch is now locally validated and the latest device run no longer shows that exception, but the Google button still remains loading. The remaining spinner is therefore inside the Google authentication critical path itself.

## 2. Verified evidence

### Production identity path

- `AuthLandingPage` prefers `SignInWithGoogleUseCase` when provided.
- The configured app path provides `SupabaseAuthSignInRepository`.
- Supabase Google sign-in establishes a Supabase GoTrue session with `auth.users.id` as the app session ID.
- The dormant `GoogleAuthUseCase` is the path that signs into Firebase and obtains `firebaseUser.uid`, but it is shadowed by the configured Supabase path.

### Firebase capability

- Firebase packages are present.
- `main.dart` does not initialize Firebase.
- Android app Gradle does not apply Google Services.
- no generated `DefaultFirebaseOptions` implementation was found.
- `authCapabilityProvider` is explicitly unavailable pending Firebase client configuration.

### Live Supabase read-only audit

- 2 Google identities exist in Supabase auth.
- only 1 has a matching `public.users` row.
- 0 `public.users` rows have a non-empty `firebase_uid`.
- no personal names/emails were inspected or recorded.

### Loading hazards

- after Supabase auth succeeds, Google/email flows previously awaited device sync;
- Google sign-in also previously awaited optional `public.users` profile enrichment;
- these secondary operations are not required to establish the authenticated session;
- `SupabaseOnboardingCompletionRepository.readCurrent()` is bounded by the app bootstrap controller timeout;
- bootstrap `failure` stays on Splash but is visually distinguishable and retryable instead of being an endless normal spinner;
- late bootstrap results after controller disposal are now ignored;
- after those fixes, real-device testing still shows the Google action spinner remaining active;
- `SupabaseAuthSignInRepository.signInWithGoogle()` still had three unbounded awaited stages: native account selection, Google credential read, and Supabase ID-token exchange.

## 3. Frozen decisions

- Do not delete/rewrite existing auth users during this task.
- Do not backfill `firebase_uid` until production identity ownership is explicitly chosen.
- Do not treat readiness lookup failure as a new user.
- Normal AuthLanding/Login/Splash visuals remain unchanged except explicit error/recovery feedback.
- #8 profile/account persistence is paused while this P0 incident is active.

### Login account-admission rule

Login is **sign-in-only**. It must not silently create a new Tio account.

For a Google identity that does not belong to an existing Tio account:

```text
Google Login
→ verify identity/account eligibility without creating a new application account
→ no account found
→ remain on Login
→ no onboarding/navigation success
→ show existing Login/Auth feedback surface:
   “No Tio account found for this Google account. Create a Tio account first to continue.”
```

Guardrails:

- no implicit `auth.users` creation from a login-only intent;
- no implicit `public.users` provisioning from a login-only intent;
- account creation must occur only through an explicit signup/onboarding account-creation flow;
- do not expose an unauthenticated account-enumeration endpoint without appropriate server-side validation/rate limiting;
- current Supabase Dart `signInWithIdToken()` does not expose a per-call `shouldCreateUser: false` switch, so this cannot be solved safely by a UI-only change;
- disabling Supabase “Allow new users to sign up” globally would also affect explicit signup flows, so use it only if the final product deliberately disables all client signup.

## 4. Architecture split

### Slice A — Login must not wait on secondary sync

Implemented and locally validated:

- [x] make device sync best-effort/non-blocking after Supabase auth success
- [x] make Google profile enrichment best-effort/non-blocking after auth success
- [x] retain logging for secondary sync failures
- [x] apply non-blocking device sync consistently to Google/email/OTP/signup auth success paths
- [x] add regression proving a pending device sync cannot hold successful sign-in open
- [x] `supabase_auth_sign_in_repository_test.dart`: 5 passed
- [x] `auth_landing_page_test.dart`: 1 passed
- [x] `login_page_test.dart`: 9 passed
- [x] auth `flutter analyze`: No issues found

### Slice B — Bootstrap must be bounded and recoverable

Implemented and locally validated:

- [x] add configurable bounded timeout to remote completion lookup; production default 8 seconds
- [x] timeout/error resolves `AppSessionBootstrapFailure`
- [x] add controller regression for pending lookup -> timeout failure
- [x] add controller regression proving explicit refresh can recover failure -> ready
- [x] keep normal Splash loading UI unchanged
- [x] add failure-only Splash message + Retry action
- [x] wire Retry to `AppSessionBootstrapController.refresh()`
- [x] add Splash widget coverage for failure feedback + Retry callback
- [x] app bootstrap controller tests: 8 passed
- [x] app route policy regression: 4 passed
- [x] app `flutter analyze`: No issues found
- [x] Splash tests: 7 passed
- [x] Splash `flutter analyze`: No issues found
- [x] final reported worktree clean and synchronized

### Slice B2 — Bootstrap lifecycle/disposal safety

Implemented and locally validated:

- [x] add explicit disposed-state guard to `AppSessionBootstrapController`
- [x] invalidate in-flight resolution generation during `dispose()`
- [x] ignore late stream errors/results after disposal
- [x] prevent `refresh()`, `start()`, completion publication, and `_setState()` from acting after disposal
- [x] add regression: pending authenticated completion lookup -> dispose controller -> lookup completes -> no exception/no late mutation
- [x] `app_session_bootstrap_controller_test.dart`: 9 passed
- [x] `app_session_route_policy_test.dart`: 4 passed
- [x] app `flutter analyze`: No issues found
- [x] final reported worktree clean and synchronized
- [x] latest device run does not show the previous disposed-controller exception

### Slice B3 — Bound and trace the Google critical path

Implemented, awaiting local validation:

- [x] bound native Google account selection; production timeout 30 seconds
- [x] bound Google credential/token read; production timeout 15 seconds
- [x] bound Supabase Google ID-token exchange/OAuth fallback; production timeout 15 seconds
- [x] return controlled `SignInFailure` with stage-specific error codes instead of infinite loading
- [x] emit non-PII debug diagnostics for each Google auth stage start/completion/timeout/failure
- [x] add regression for account-selection timeout
- [x] add regression for credential-read timeout
- [x] add regression for Supabase token-exchange timeout
- [x] add regression for successful Google completion through all critical stages
- [ ] `supabase_auth_sign_in_repository_test.dart` passes locally (expected 9 total)
- [ ] auth `flutter analyze` passes locally
- [ ] real-device console identifies the last completed Google auth stage
- [ ] real-device Google spinner either succeeds or returns a controlled error; never stays indefinite

Expected diagnostics:

```text
[GoogleAuth] account selection started
[GoogleAuth] account selected
[GoogleAuth] credential read started
[GoogleAuth] credential read completed
[GoogleAuth] Supabase ID-token exchange started
[GoogleAuth] Supabase ID-token exchange completed
[GoogleAuth] sign-in completed successfully
```

If a stage stalls, the corresponding timeout log/error identifies it without exposing email/name/token values.

### Slice C — Production auth source of truth + login-only admission

Before implementation, define one production source of truth:

```text
A) Supabase-first
   auth.users.id = canonical identity
   firebase_uid = optional/legacy

B) Firebase-first/hybrid
   Firebase UID/token = primary identity proof
   explicit mapping into Supabase session/RLS ownership
```

Do not partially enable both.

Whichever source is chosen must support two different intents explicitly:

```text
LOGIN intent
→ existing Tio account only
→ unknown identity returns No Tio account feedback
→ must not create account

SIGNUP intent
→ explicit account creation flow only
→ creates/provisions canonical auth + application owner state
```

Current schema/RLS strongly favors Supabase-first because public owner rows reference `auth.users(id)` and client RLS is based on `auth.uid()`. Firebase-first/hybrid therefore requires an explicit bridge/session strategy rather than simply writing `firebase_uid`.

### Slice D — Existing-account reconciliation

Only after Slice C is chosen:

- reconcile the extra Supabase Google identity / missing public row safely;
- add DB-owned auth.users -> public.users provisioning under issue #5;
- backfill Firebase mapping only if Firebase-first/hybrid is selected;
- ensure reconciliation does not mistakenly convert a login-only unknown identity into a newly created account.

## 5. Validation evidence

### Slice A local evidence

```text
apps/features/auth
supabase_auth_sign_in_repository_test.dart: 5 passed
auth_landing_page_test.dart: 1 passed
login_page_test.dart: 9 passed
flutter analyze: No issues found
```

### Slice B / B2 local evidence

```text
apps/app
app_session_bootstrap_controller_test.dart: 9 passed
app_session_route_policy_test.dart: 4 passed
flutter analyze: No issues found

apps/features/splash
splash_screen_test.dart: 7 passed
flutter analyze: No issues found

final git status: clean and synchronized
```

## 6. Next validation gate

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\features\auth"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/data/supabase_auth_sign_in_repository_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/presentation/auth_landing_page_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

Expected:

```text
supabase_auth_sign_in_repository_test.dart: 9 passed
auth_landing_page_test.dart: 1 passed
auth flutter analyze: No issues found
worktree: clean
```

After this gate, run the real-device Google flow with the console attached and capture the `[GoogleAuth]` lines. Do not proceed to account-admission/identity migration until the hanging critical stage is identified or Google login completes successfully.

## 7. Current status

Slices A, B, and B2 are locally green. Real-device testing proves the spinner still exists but no longer shows the previous bootstrap disposal crash. Slice B3 now makes the Google critical path bounded and observable. Login-only account admission is frozen as a required product rule for Slice C. `firebase_uid` reconciliation remains deferred until the canonical auth source of truth is selected.
