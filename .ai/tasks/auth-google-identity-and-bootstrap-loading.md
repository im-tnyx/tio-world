# Google Identity Ownership & Bootstrap Loading

**Status:** In progress — Slice A implemented, local validation pending
**Primary owner:** `apps/features/auth` + `apps/app` + `apps/features/onboarding`
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

- after Supabase auth succeeds, Google/email flows awaited device sync;
- Google sign-in also awaited optional `public.users` profile enrichment;
- these secondary operations are not required to establish the authenticated session;
- `SupabaseOnboardingCompletionRepository.readCurrent()` still has no timeout;
- bootstrap `failure` and `loading` still both route to passive Splash, whose normal UI is only a spinner.

## 3. Frozen decisions

- Do not delete/rewrite existing auth users during this task.
- Do not backfill `firebase_uid` until production identity ownership is explicitly chosen.
- Do not treat readiness lookup failure as a new user.
- Normal AuthLanding/Login/Splash visuals remain unchanged.
- Failure-only recovery UI is allowed if needed to prevent an endless loader.
- #8 profile/account persistence is paused while this P0 incident is active.

## 4. Architecture split

### Slice A — Login must not wait on secondary sync

Implemented, awaiting local validation:

- [x] make device sync best-effort/non-blocking after Supabase auth success
- [x] make Google profile enrichment best-effort/non-blocking after auth success
- [x] retain logging for secondary sync failures
- [x] apply non-blocking device sync consistently to Google/email/OTP/signup auth success paths
- [x] add regression proving a pending device sync cannot hold successful sign-in open
- [ ] focused auth test passes locally
- [ ] auth analyzer passes locally

Changed files:

```text
apps/features/auth/lib/src/data/repositories/supabase_auth_sign_in_repository.dart
apps/features/auth/test/data/supabase_auth_sign_in_repository_test.dart
.ai/tasks/auth-google-identity-and-bootstrap-loading.md
```

### Slice B — Bootstrap must be bounded and recoverable

- [ ] add a bounded timeout to remote completion lookup
- [ ] ensure timeout/error becomes `AppSessionBootstrapFailure`
- [ ] make failure distinguishable/retryable instead of permanent spinner
- [ ] add bootstrap/Splash regression coverage

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

### Slice A local gate

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\features\auth"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/data/supabase_auth_sign_in_repository_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

Do not treat Slice A alone as proof that cold-start loading is fixed. The persisted-session/Splash symptom belongs to Slice B.

## 6. Current status

Investigation complete. Slice A removes secondary synchronization from the login critical path. Slice B is queued immediately after local validation and owns the persisted-session/bootstrap infinite-loader recovery.
