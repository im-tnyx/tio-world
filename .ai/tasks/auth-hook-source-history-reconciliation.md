# Auth Hook Source-History Reconciliation

**Status:** Validated
**Primary owner:** `supabase/*` migration history and Auth configuration
**Affected platforms:** Hosted Supabase Auth/Postgres; repository migration source
**Related trackers:** #34, #120; stacked PR #123

## 1. Discovery

### User Outcome

Keep the already-enabled hosted `Before User Created` hook reproducible from
one canonical Git source without reapplying, duplicating, or altering the live
Auth/database behavior.

### Success Criteria

- the canonical source contains the same migration identities recorded by the
  hosted project, or an approved documented reconciliation explains each ID;
- the hosted Dashboard binding remains
  `public.before_user_created_canonical_email_guard`;
- no duplicate migration is applied to the hosted project;
- no user-data, Auth-user, RLS, grant, or hook behavior change occurs during
  source reconciliation.

### Scope

- compare hosted migration history, Dashboard binding, and Git branch history;
- select the safe canonical source adoption method before changing migration
  filenames or branch ancestry;
- record validation and the handoff boundary.

### Non-Goals

- applying/replaying a migration, changing the Dashboard hook, or creating a
  test Auth user;
- merging, rebasing, force-pushing, or deleting a branch;
- changing Flutter/Auth client behavior or starting #118.

## 2. Codebase Exploration

### Verified Evidence

- Chrome Dashboard shows an enabled `Before User Created` Postgres hook with
  schema `public` and function
  `before_user_created_canonical_email_guard`.
- Live function body delegates from `public` to
  `private.before_user_created_canonical_email_guard(event)`; both functions
  are `SECURITY INVOKER`, executable by `supabase_auth_admin`, and not
  executable by `anon`.
- Hosted migration history records these Auth migrations:
  `20260826112650`, `20260826112754`, `20260826114935`, and
  `20260826121524` (public wrapper).
- `main` does not contain this hook source. The current branch
  `agent/auth-canonical-email-admission` contains the private guard under
  source ID `20260826104000` and local private-hook wiring.
- `origin/agent/auth-email-canonical-signup` contains the equivalent public
  wrapper under source ID `20260826123000`; its wrapper body and grants match
  the live function, but its full Auth migration ID sequence differs from the
  hosted sequence.
- Reconciliation source now uses the hosted IDs above; each renamed source
  retained byte-identical SQL content.

## 3. Clarification

### Decision Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Canonical reconciliation method | Chosen | Adopt the hosted IDs in source; do not replay live SQL. | Auth/Data owner |
| Branch/PR that owns the consolidated source | Chosen | Existing Auth admission branch receives the source-history reconciliation. | Repository owner |

## 4. Architecture Design

### Guardrail

```text
Hosted migration record + enabled Dashboard binding
        -> source-history reconciliation decision
        -> one canonical Git migration lineage
        -> optional, explicitly approved real Auth smoke test
```

The hosted project is behavior truth. The reconciliation must adopt that truth
in source without applying a duplicate migration or changing the enabled hook.

## 5. Implementation Plan

- [x] Capture hosted hook/function/migration evidence read-only.
- [x] Locate equivalent Git source and identify migration-ID divergence.
- [x] Adopt the hosted migration IDs without changing SQL content.
- [x] Make the smallest source-only reconciliation on the existing Auth branch.
- [x] Run source-history and security validation.
- [ ] Run a real Auth smoke test only after explicit approval to create a
  controlled Auth user.

## 6. Quality Review

### Validation Run

```text
Read-only Chrome Dashboard verification: completed.
Read-only Supabase function/ACL and migration-history queries: completed.
Read-only Git/GitHub branch and source comparison: completed.
Six migration source files were renamed to their hosted IDs. All six contents
were byte-identical to their pre-rename versions. `git diff --check` passed.
Migration apply, hook update, user creation, merge, and rebase: not run.
```

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-hook-source-history-reconciliation.md`

### Known Limitations

The current checkout has unrelated uncommitted onboarding/core UI work. It is
not included in this Auth source-history commit.

### Final Status

`PASS`
