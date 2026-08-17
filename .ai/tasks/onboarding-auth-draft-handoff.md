# Onboarding Pre-Auth Draft Persistence

**Status:** Implemented — automated validation green; real-device validation pending
**Tracking:** GitHub issue #13 (related to #10)
**Source branch:** `codex/onboarding-mode-migration`
**Primary owner:** `apps/app` + `apps/features/onboarding`

## User-reported regression

```text
Get Started / onboarding
-> choose App Mode
-> complete Profile (name/height/weight/etc.)
-> Google auth checkpoint
-> select a fresh Google account
-> bootstrap requires onboarding
-> app returns to App Mode (incorrect)
```

## Verified root cause

Before authentication there is no Supabase `user_id`, so `SupabaseOnboardingDraftRepository` cannot own or persist the draft. App Mode/Profile answers therefore existed only in the auto-disposed onboarding controller. Google authentication can rebuild `/onboarding` before the original controller continuation resumes, losing those answers and restarting the plan at App Mode.

The first in-memory one-shot handoff implementation was covered by unit tests but failed the real-device gate, so it is no longer the production source of truth for this transition.

## Frozen ownership contract

```text
SIGNED OUT
-> onboarding draft stays device-local only
-> no onboarding/profile draft writes to Supabase

AUTH CHECKPOINT
-> keep current signed-out draft unchanged
-> store a separate resume-after-auth checkpoint locally

AUTHENTICATED
-> bind local record to the selected Supabase user id
-> existing remote onboarding draft wins when present
-> otherwise migrate the matching local resume checkpoint to onboarding_drafts
-> clear the local temporary copy after successful migration

COMPLETED EXISTING ACCOUNT
-> bootstrap routes Home
-> local bound pre-auth draft is not consumed by another identity
-> bound local draft is cleared on sign-out
```

## Local data protection

Pre-auth onboarding can include profile/health-adjacent fields such as date of birth, height, weight, goals, and health conditions. The production local adapter therefore uses platform secure storage rather than plain SharedPreferences. A process-memory fallback exists only for tests/platform storage failure.

## Resume semantics

The local record intentionally stores two snapshots:

- `draft`: the signed-out screen state. App restart or cancelled auth resumes here, so authentication cannot be skipped.
- `resumeAfterAuth`: the first valid post-Profile onboarding state. Only an authenticated matching identity may consume/migrate it.

This separation also protects the resume checkpoint from a late pre-auth autosave of the Profile screen.

## Guardrails

- No Supabase write before authentication.
- No rendered UI/layout changes.
- No Supabase schema migration.
- No account row deletion/mutation.
- Existing remote user-owned draft remains authoritative.
- Local draft cannot cross authenticated identities.
- A stale bound draft is cleared after sign-out.
- Remote read failures are not treated as confirmed "row missing"; they propagate to the controller fallback instead of triggering an unsafe overwrite.
- Onboarding completion continues to clear obsolete remote draft data; migrated local temporary data is already cleared after ownership transfer.

## Implementation

- [x] Add encrypted device-local onboarding draft store.
- [x] Add auth-aware local/remote repository boundary.
- [x] Keep all signed-out autosaves local.
- [x] Bind the local record to the selected authenticated identity.
- [x] Migrate local resume state only when remote draft is truly missing.
- [x] Keep remote draft authoritative when it exists.
- [x] Add separate signed-out and post-auth resume snapshots.
- [x] Prevent late stale Profile autosave from replacing the post-auth resume checkpoint.
- [x] Clear mismatched/bound stale local state safely.
- [x] Stop swallowing Supabase draft read errors as `null`.
- [x] Add regression tests for local-only writes, height/weight retention, migration, remote precedence, identity isolation, lifecycle clear, and auth checkpoint resume.
- [x] CI analyzer + targeted test validation.
- [ ] Real-device fresh Google signup resumes after Profile instead of App Mode.

## Automated validation

GitHub Actions run #72 on code commit `6348478a58dfbfe00bce0de1a4b333fbb264d418`:

- workspace bootstrap: passed, including `flutter_secure_storage` resolution
- Flutter analyzers: all Flutter packages passed
- Dart analyzer: passed
- `apps/app/test/app/onboarding_auth_draft_handoff_test.dart`: all new local-first persistence tests passed
  - signed-out save stays local and never calls remote
  - fresh authenticated user migrates the post-auth resume draft
  - existing remote user draft remains authoritative
  - mismatched identity cannot consume/migrate the local draft
  - auth lifecycle binds and clears stale bound data on sign-out
  - Profile data including height/weight is retained while staging the post-auth resume checkpoint

The workspace Flutter test step remains red with the same 10 pre-existing app test failures in Welcome accessibility, avatar expectations, and AppMode router `pumpAndSettle` coverage. This slice introduces no new failing test class.

## Current commits

- `aecfec8946fe143755c9624479662b792b7b88be` — local-first encrypted onboarding draft persistence.
- `6348478a58dfbfe00bce0de1a4b333fbb264d418` — analyzer lint cleanup.

## Device gate

```text
Get Started
-> App Mode
-> Profile
-> fill name / height / weight / remaining Profile fields
-> Continue / Google auth checkpoint
-> select fresh Google account
-> bootstrap
-> resume at first post-Profile onboarding step
```

Must not repeat App Mode or Profile, and the values entered before auth must remain intact.
