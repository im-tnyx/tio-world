# GitHub #569 — Canonical default identity survives Move

**Status:** Ready for review
**Primary owner:** Workout / Supabase test matrix
**Affected platforms:** Disposable Supabase database CI

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Owner-approved test-only scope. Santosh, 2026-10-20 (GitHub #569 / chat).
**Approval evidence:** GitHub #569 owner-approved Move acceptance (2026-10-15 and 2026-10-17): a new destination is a normal user-created Program, not the special default My Program, and Move must not create a duplicate default Program. Canonical identity is `ProgramId` / `is_default`, not a display-name match. Linear TNYX-81 remains the parent Backlog. GitHub #568 / PR #620 already approved and merged the `user_workout_programs.is_default` column; this slice does not change that shape.
**Approved product/UI/data-shape boundaries:** Disposable SQL regression only. Existing and atomic Move must leave exactly one owner default Program, must insert Create & Move destinations with `is_default = false`, and must not let an authenticated client flip `is_default`.
**Explicit non-changes:** No production Move release, no `routineMoveReleaseEnabledProvider` change, no client `EXECUTE` grant, no hosted migration or hosted write, no new table/column, no Flutter UI, no real five-second Undo, no duplicate Program creation, no #568 RPC activation.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81
**Implementation owner:** This cloud session, exclusive for this slice
**Review owner:** Not assigned. Self-review is not an independent review.
**Implementation ownership state:** Active
**Ownership transition:** No previous active #569 Implementation owner. Open PRs were 0 and no `issue-569` remote branch existed at `main@59155cc7db7e29eab7d601e8a22e6d337fdd824a` before this branch.
**Repository state last verified:** `main@59155cc7db7e29eab7d601e8a22e6d337fdd824a`
**Branch:** `tnyx/issue-569-default-identity-move-regression-fb6f`
**HEAD SHA:** SQL behavior was reviewed and CI-proven at `6e1d6f7ab45b8e5328132e1fe50185252fe2c94b` ([Supabase Database CI #39378392950](https://github.com/im-tnyx/tio-world/actions/runs/39378392950) SUCCESS, [Commit attribution guard #39378389864](https://github.com/im-tnyx/tio-world/actions/runs/39378389864) SUCCESS). This P3 follow-up does not store its own commit SHA. Read [PR #626](https://github.com/im-tnyx/tio-world/pull/626) for the latest exact-head runs that cover this docs-and-fixture commit.
**Observed working-tree state:** Clean `main` at takeover
**Observed uncommitted/dirty files:** None at takeover
**PR / tracker:** GitHub #569 Open. Linear TNYX-81 Backlog, blocked by TNYX-78 and TNYX-80 (both In Progress). TNYX-267 Backlog. Prior `.ai/tasks/issue-569-m3*` headers that still say unmerged are historical snapshots; live GitHub merge state wins. Do not bulk-rewrite them in this slice.
**Current implementation state:** Default-identity assertions proven at `6e1d6f7ab45b8e5328132e1fe50185252fe2c94b`. The deleted-source savepoint now moves the canonical default from 011 to 013 before deleting 011.
**Relevant execution surface:** `supabase/tests/database/tnyx_569_existing_program_routine_move.test.sql`, `supabase/tests/database/tnyx_569_atomic_create_program_move.test.sql`
**Validation completed at SHA:** [Supabase Database CI #39378392950](https://github.com/im-tnyx/tio-world/actions/runs/39378392950) SUCCESS and [Commit attribution guard #39378389864](https://github.com/im-tnyx/tio-world/actions/runs/39378389864) SUCCESS at `6e1d6f7ab45b8e5328132e1fe50185252fe2c94b`. Independent Security, Engineering Auditor, and QA reviews APPROVE that head with no P1/P2. Local Supabase CLI was not available.
**Validation remaining:** None recorded here. The P3 fixture follow-up is evidenced by the latest exact-head runs on PR #626.
**Current blocker:** None for source. Hosted ledger is 65 applied through `20261018100000`; repository migration `20261019162535` (#568) is not hosted. This slice does not deploy it.
**Open review finding IDs:** None open. P3 SHA/CI, approval wording, deleted-source default, and sanity labels are corrected in this follow-up.
**Next exact action:** Independent review of PR #626. Do not merge, grant EXECUTE, or deploy.

## 1. Discovery

### User Outcome

Moving a Routine, including Create & Move into a new Program, does not create or retarget the owner's canonical default Program.

### Success Criteria

- Authenticated `INSERT`/`UPDATE` of `is_default` stays denied inside the Move matrices.
- Existing-Program A→B and B→A leave the original default flag on that Program.
- Atomic Create & Move inserts the new Program with `is_default = false` and does not clear or duplicate the existing default.
- Idempotent replay and a later ordinary Move keep that same single default.
- The deleted-source savepoint first moves the canonical default from 011 to 013, then deletes 011. Replay does not promote 031. Exactly one default remains, and it is 013.

### Scope

Two existing disposable #569 SQL tests, this brief, and the task index row.

### Non-Goals

Production activation, EXECUTE grants, hosted `db push`, Flutter selector changes, Undo, and #568 first-Routine RPC work.

## 2. Codebase Exploration

### Verified Evidence

- `routineMoveReleaseEnabledProvider` is hard `false`.
- Checked-in Move and atomic RPCs `REVOKE` EXECUTE from `public`, `anon`, `authenticated`, and `service_role`.
- Live read-only catalog on `oykupyiitspujzpwwvuj` (2026-10-20): 65 migrations; both Move functions `SECURITY DEFINER`, empty `search_path`, EXECUTE false for those four roles.
- Atomic INSERT is `(id, user_id, name)` only, so `is_default` stays the column default `false`. No function change is required.
- `ProgramRepository` selects `id, name` only. This slice does not make the client depend on a column that hosted Postgres does not have yet.

### Existing pattern to follow

`tnyx_569_*` transactional tests with `pg_temp.assert_true` / `expect_state`, grants rolled back by `rollback`.

### Tests or validation already present

Privilege and identity checks for `is_default` live in `tnyx_568_w1_my_program_atomic_default_create.test.sql`. They do not run a Move or Create & Move.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Test-only regression, no new migration | Made | Current RPC already omits `is_default`. A migration would be a new hosted ledger entry and is out of scope. | This slice |
| Do not SELECT `is_default` from Flutter | Made | Hosted database has not applied `20261019162535`. | This slice |

## 4. Architecture Design

### Chosen Approach

Extend the two existing Move SQL matrices. Fixture role sets one canonical default before `set local role authenticated`.

### Ownership and Data Flow

```text
Disposable CI test -> existing dormant RPC -> user_workout_programs.is_default
```

### Alternative Rejected

A new migration that writes `is_default = false` explicitly. The column default already does that, and this task must not add or deploy SQL.

### Failure and Accessibility States

Not a UI slice. Failed Move requests must leave the single default unchanged.

## 5. Implementation Plan

- [x] Confirm exclusive ownership
- [x] Add default-identity assertions to both #569 SQL matrices
- [x] Record exact-head CI for `6e1d6f7ab45b8e5328132e1fe50185252fe2c94b`
- [x] P3: move the default to 013 before deleting source 011
- [x] P3: relabel post-rollback default checks as sanity checks

## 6. Quality Review

### Validation Run

```text
git diff --check: pass on the staged implementation diff at the proven SQL head.
git merge-base --is-ancestor origin/main HEAD: pass at 6e1d6f7ab45b8e5328132e1fe50185252fe2c94b.
Local supabase/psql/docker: not installed.
Supabase Database CI #39378392950 SUCCESS at 6e1d6f7ab45b8e5328132e1fe50185252fe2c94b.
Commit attribution guard #39378389864 SUCCESS at the same SHA.
Independent reviews APPROVE that head: Security, Engineering Auditor, QA. No P1/P2.
This P3 follow-up does not embed its own SHA. PR #626 lists the latest exact-head runs.
No Flutter files changed, so Flutter CI did not run.
No hosted SQL executed.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| SHA/CI | P3 | Corrected | Brief and index cited `ccd96a2f` / `397d9f15` and said head CI was still pending | `6e1d6f7a` | Proven head and runs recorded above. This follow-up points at the PR for its own exact-head runs |
| Approval | P3 | Corrected | Approval status said Not required | `6e1d6f7a` | Owner-approved test-only scope, Santosh, 2026-10-20 |
| Deleted source | P3 | Corrected | Savepoint deleted the only default and asserted zero defaults | `6e1d6f7a` | Fixture moves the default 011 → 013 before delete; 031 stays false and 013 is the one default |
| Sanity labels | P3 | Corrected | Post-`expect_state` default asserts cannot observe a committed rejection | `6e1d6f7a` | Messages and comments now say post-rollback sanity. Asserts kept |

## 7. Final Handoff

### Changed Files

- `supabase/tests/database/tnyx_569_existing_program_routine_move.test.sql`
- `supabase/tests/database/tnyx_569_atomic_create_program_move.test.sql`
- `.ai/tasks/issue-569-default-identity-move-regression.md`
- `.ai/tasks/README.md`

### Actual Behavior

Disposable tests now require one canonical `is_default` Program to survive existing Move, Create & Move, replay, and a later Move. The deleted-source savepoint moves that default to 013 before deleting 011 and checks that 031 is not promoted. Authenticated clients still cannot write `is_default`. The RPCs themselves are unchanged.

### Known Limitations

Local Supabase runner was unavailable. Hosted #568 migration remains unapplied. Production Move stays OFF. Database CI and attribution passed at `6e1d6f7ab45b8e5328132e1fe50185252fe2c94b`. The P3 fixture follow-up is covered by the latest exact-head runs on PR #626. Prior APPROVE reviews apply to `6e1d6f7a`, not automatically to this follow-up.

### Final Status

`REVIEW`
