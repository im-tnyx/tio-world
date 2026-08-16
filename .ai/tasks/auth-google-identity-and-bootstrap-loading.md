# Google Identity Ownership & Bootstrap Loading

**Status:** In progress — Slice A locally validated; Slice B implemented, local validation pending
**Primary owner:** `apps/features/auth` + `apps/app` + `apps/features/onboarding` + `apps/features/splash`
**Affected platforms:** Flutter phone app + Supabase/Firebase auth boundary
**Tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`

## 1. User-reported incident

A Google-created account can remain stuck in loading during sign-in. Reopening the app can still show loading. The corresponding `public.users.firebase_uid` is not populated.

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
- `SupabaseOnboardingCompletionRepository.readCurrent()` is now bounded by the app bootstrap controller timeout;
- bootstrap `failure` stays on Splash but is now visually distinguishable and retryable instead of being an endless normal spinner.

## 3. Frozen decisions

- Do not delete/rewrite existing auth users during this task.
- Do not backfill `firebase_uid` until production identity ownership is explicitly chosen.
- Do not treat readiness lookup failure as a new user.
- Normal AuthLanding/Login/Splash visuals remain unchanged.
- Failure-only recovery UI is allowed to prevent an endless loader.
- #8 profile/account persistence is paused while this P0 incident is active.

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

Changed files:

```text
apps/features/auth/lib/src/data/repositories/supabase_auth_sign_in_repository.dart
apps/features/auth/test/data/supabase_auth_sign_in_repository_test.dart
.ai/tasks/auth-google-identity-and-bootstrap-loading.md
```

### Slice B — Bootstrap must be bounded and recoverable

Implemented, awaiting local validation:

- [x] add configurable bounded timeout to remote completion lookup; production default 8 seconds
- [x] timeout/error resolves `AppSessionBootstrapFailure`
- [x] add controller regression for pending lookup -> timeout failure
- [x] add controller regression proving explicit refresh can recover failure -> ready
- [x] keep normal Splash loading UI unchanged
- [x] add failure-only Splash message + Retry action
- [x] wire Retry to `AppSessionBootstrapController.refresh()`
- [x] add Splash widget coverage for failure feedback + Retry callback
- [x] audit large `router.dart` replacement; commit diff contains only intended Splash-route hunk
- [ ] app bootstrap controller tests pass locally
- [ ] app route policy regression passes locally
- [ ] app analyzer passes locally
- [ ] Splash tests pass locally
- [ ] Splash analyzer passes locally
- [ ] real-device persisted-session cold reopen no longer remains on permanent spinner

Slice B changed files:

```text
apps/app/lib/app/session/app_session_bootstrap_controller.dart
apps/app/lib/app/router.dart
apps/app/test/app/session/app_session_bootstrap_controller_test.dart
apps/features/splash/lib/src/presentation/screen/splash_screen.dart
apps/features/splash/test/presentation/screen/splash_screen_test.dart
.ai/tasks/auth-google-identity-and-bootstrap-loading.md
```

Expected runtime:

```text
persisted/authenticated session
→ bootstrap completion read
→ <= 8 seconds
   completed   → Home
   incomplete  → Onboarding
   lookup fail → Splash recovery state
                 “Couldn't finish signing you in. Check your connection and try again.”
                 Retry → bootstrap refresh
```

### Slice C — Production auth source of truth

Decision required before implementation:

```text
A) Supabase-first
   auth.users.id = canonical identity
   firebase_uid = optional/legacy

B) Firebase-first/hybrid
   Firebase UID/token = primary identity proof
   explicit mapping into Supabase session/RLS ownership
```

Do not partially enable both.

Current schema/RLS strongly favors Supabase-first because public owner rows reference `auth.users(id)` and client RLS is based on `auth.uid()`. Firebase-first/hybrid therefore requires an explicit bridge/session strategy rather than simply writing `firebase_uid`.

### Slice D — Existing-account reconciliation

Only after Slice C is chosen:

- reconcile the extra Supabase Google identity / missing public row safely;
- add DB-owned auth.users -> public.users provisioning under issue #5;
- backfill Firebase mapping only if Firebase-first/hybrid is selected.

## 5. Validation gates

### Slice A local evidence

```text
apps/features/auth
supabase_auth_sign_in_repository_test.dart: 5 passed
auth_landing_page_test.dart: 1 passed
login_page_test.dart: 9 passed
flutter analyze: No issues found
```

The reported local worktree contained an unrelated/generated-looking modification at `apps/features/settings/pubspec.lock`; it must be inspected before the next pull rather than blindly discarded.

### Slice B local gate

```powershell
Set-Location "G:\projects\Tio-World"
git diff -- "apps/features/settings/pubspec.lock"

# After deciding whether that local lockfile change is intentional, make the
# worktree safe for pull, then:
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_bootstrap_controller_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/app/session/app_session_route_policy_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World\apps\features\splash"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/presentation/screen/splash_screen_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

## 6. Current status

Slice A is locally green and removes secondary synchronization from the login critical path. Slice B is implemented and owns the persisted-session/bootstrap infinite-loader recovery. Identity ownership and `firebase_uid` reconciliation remain intentionally deferred to Slice C/D after reliability is validated.
