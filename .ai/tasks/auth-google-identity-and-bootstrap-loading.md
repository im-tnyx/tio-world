# Google Identity Ownership & Bootstrap Loading

**Status:** In progress — P0 reliability slice active
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

- after Supabase auth succeeds, Google/email flows await device sync;
- Google sign-in also awaits optional `public.users` profile enrichment;
- these secondary operations are not required to establish the authenticated session;
- `SupabaseOnboardingCompletionRepository.readCurrent()` has no timeout;
- bootstrap `failure` and `loading` both route to passive Splash, whose normal UI is only a spinner.

## 3. Frozen decisions

- Do not delete/rewrite existing auth users during this task.
- Do not backfill `firebase_uid` until production identity ownership is explicitly chosen.
- Do not treat readiness lookup failure as a new user.
- Normal AuthLanding/Login/Splash visuals remain unchanged.
- Failure-only recovery UI is allowed if needed to prevent an endless loader.
- #8 profile/account persistence is paused while this P0 incident is active.

## 4. Architecture split

### Slice A — Login must not wait on secondary sync

- [ ] make device sync best-effort/non-blocking after Supabase auth success
- [ ] make Google profile enrichment best-effort/non-blocking after auth success
- [ ] retain logging for secondary sync failures
- [ ] add focused auth regression coverage

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

### Slice D — Existing-account reconciliation

Only after Slice C is chosen:

- reconcile the extra Supabase Google identity / missing public row safely;
- add DB-owned auth.users -> public.users provisioning under issue #5;
- backfill Firebase mapping only if Firebase-first/hybrid is selected.

## 5. Validation gates

For every implementation slice:

```text
focused auth/app tests
flutter analyze for touched packages
cold-start persisted-session regression
worktree clean
```

## 6. Current status

Investigation complete. Slice A is the first safe implementation because it does not require choosing Firebase vs Supabase ownership and directly removes unnecessary blockers from successful authentication.
