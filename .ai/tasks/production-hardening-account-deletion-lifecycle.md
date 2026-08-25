# Production Hardening — Account Deletion Lifecycle

## Status

**AUDIT COMPLETE / IMPLEMENTATION REQUIRED.**

Fresh audit head:

```text
1e4702215dfbbedd14d83766ce09e611e378dd15
```

Owner tracker: #5 P1 item 14.

## Goal

Make Delete Account failure-safe and complete across Supabase Storage, Postgres/Auth ownership, local session cleanup, and navigation without false success or destructive test-data shortcuts.

## Fresh findings

### Live backend state

Connected project `oykupyiitspujzpwwvuj` currently has no `public.delete_user_account()` function.

Live FK audit shows the intended cascade graph already exists:
- `public.users.id -> auth.users.id ON DELETE CASCADE`;
- `user_devices`, `onboarding_drafts`, nutrition/workout profile rows also reference `auth.users` with `ON DELETE CASCADE`;
- Body/Profile/App Preferences/Wellness/Nutrition Targets/Workout Targets reference `public.users` with `ON DELETE CASCADE`.

Therefore database deletion can be one authenticated `auth.users` delete and should not manually enumerate current canonical tables.

### Historical migration is unsafe to deploy

Repository migration `20260815000003_delete_user_account_rpc.sql` is not live and directly executes `DELETE FROM storage.objects`.

Current Supabase Storage guidance requires object deletion through the Storage API `remove`; direct SQL metadata deletion can orphan physical files. Do not edit the historical migration; supersede it with a new forward migration.

### Current app/backend boundary

`SupabaseAccountDeletionRepository.deleteCurrentAccount()` currently calls RPC `delete_user_account` only.

Current router callback then signs out and navigates immediately after repository completion.

Current delete overlay:
- correctly does not show `Account Deleted` until the callback returns;
- still allows Close / Keep Account / system Back while deletion is in flight;
- dismisses the overlay on backend failure instead of preserving a recoverable retry state;
- has no explicit duplicate-submit regression.

### Session semantics

Deleting `auth.users` cascades Auth session rows, but an already-issued JWT can remain cryptographically valid until expiry. Client local auth state must therefore be cleared after confirmed server deletion; no success navigation is allowed before server deletion succeeds.

### Test-data guardrail

All current live user rows/identities are user-owned testing data. No existing test identity may be deleted merely to validate this slice.

## Architecture

### A. Storage cleanup owner

Before irreversible Auth deletion, the client account-deletion repository must remove the current user's owned objects from every currently supported user-owned Storage bucket via the Supabase Storage API.

Current owned bucket in scope: `avatars`.

- list only the authenticated user's folder;
- remove returned object paths through Storage API;
- Storage cleanup failure is a deletion failure: do not proceed to Auth deletion and do not show success;
- an empty/missing user folder is success;
- do not delete external/provider URLs directly.

Future user-media buckets must be added deliberately to the repository-owned bucket list when introduced.

### B. Database/Auth deletion owner

Create a new forward migration that defines `public.delete_user_account()` as a tightly scoped `SECURITY DEFINER` RPC:
- require `auth.uid()`;
- delete only `auth.users.id = auth.uid()`;
- rely on reviewed FK cascades for public/domain/Auth child rows;
- no Storage SQL;
- `search_path = ''`;
- revoke PUBLIC/anon; grant authenticated only;
- verify the delete affected exactly one Auth row or fail.

### C. UI lifecycle

- block system Back, top Close, Keep Account, and duplicate destructive interaction while `_isDeleting`;
- on backend failure, stay on the destructive step with a visible recoverable error and allow retry/cancel afterward;
- only transition to `Account Deleted` after Storage + RPC succeed;
- completed Close returns `true` to Account Settings.

### D. Local finalization/navigation

The destructive callback owns server deletion only.

After the overlay returns `deleted == true`, Account Settings/router finalization must:
- clear local Supabase session best-effort;
- refresh/clear bootstrap and user-scoped app state;
- navigate to Auth exactly once;
- never sign out/navigate on server deletion failure.

## Implementation scope

- [ ] Add Storage API cleanup to `SupabaseAccountDeletionRepository`.
- [ ] Add focused repository tests for signed-out, empty folder, cleanup failure, RPC failure, and ordering.
- [ ] Add forward-only replacement RPC migration; do not edit `20260815000003`.
- [ ] Apply/verify live migration without deleting an existing user.
- [ ] Run Supabase security/performance advisors after DDL.
- [ ] Harden delete overlay in-flight controls, Back handling, retry failure state, and duplicate submission.
- [ ] Add focused widget regressions.
- [ ] Move sign-out/navigation finalization to confirmed overlay success path.
- [ ] Exact-head Flutter/Dart + Android CI.

## Out of scope

- Deleting any current live test identity for acceptance.
- Bulk historical Storage orphan sweeper.
- Future meal/workout/progress media buckets that do not yet exist.
- General Auth provider linking/recovery (#34).
- Visual redesign of the delete flow.

## Acceptance

- [ ] Failed Storage cleanup never deletes Auth/DB account data and never shows success.
- [ ] Failed RPC never signs out/navigates/shows `Account Deleted`.
- [ ] Successful server deletion uses FK cascades and no Storage SQL.
- [ ] In-flight deletion cannot be dismissed/backed out or submitted twice.
- [ ] Failure remains recoverable in-place.
- [ ] Confirmed success clears local auth state and navigates exactly once.
- [ ] Existing live test identities remain untouched.
- [ ] Live RPC exists with restricted grants and secure search path.
- [ ] Exact-SHA CI green.

## Guardrails

- No applied migration edits.
- No `CASCADE` DDL.
- No direct SQL deletes from `storage.objects`.
- No fake success.
- PR #50 remains Draft/open/unmerged unless separately authorized.
