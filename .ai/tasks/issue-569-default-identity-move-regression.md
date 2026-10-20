# GitHub #569 — Canonical default identity survives Move

**Status:** Merged — disposable SQL regression on `main`
**Primary owner:** Workout / Supabase test matrix
**Affected platforms:** Disposable Supabase database CI

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Chat-only owner approval of the test-only scope (Santosh, 2026-10-20). Not recorded on GitHub #569.
**Approval evidence:** GitHub #569 owner-approved Move acceptance (2026-10-15 and 2026-10-17): a new destination is a normal user-created Program, not the special default My Program, and Move must not create a duplicate default Program. Canonical identity is `ProgramId` / `is_default`, not a display-name match. Linear TNYX-81 remains the parent Backlog. GitHub #568 / PR #620 already approved and merged the `user_workout_programs.is_default` column; this slice does not change that shape.
**Approved product/UI/data-shape boundaries:** Disposable SQL regression only. Existing and atomic Move must leave exactly one owner default Program, must insert Create & Move destinations with `is_default = false`, and must not let an authenticated client flip `is_default`.
**Explicit non-changes:** No production Move release, no `routineMoveReleaseEnabledProvider` change, no client `EXECUTE` grant, no hosted migration or hosted write, no new table/column, no Flutter UI, no real five-second Undo, no duplicate Program creation, no #568 RPC activation.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81
**Implementation owner:** Complete for the disposable-SQL slice (historical PR #626). This post-merge docs reconcile only updates tracker wording.
**Review owner:** Not assigned for the merged SQL slice. Historical limitation: GitHub formal reviews remained 0; chat-only bot audits are not independent APPROVED reviews. Self-review is not an independent review.
**Implementation ownership state:** Complete
**Ownership transition:** Historical: no previous active #569 Implementation owner when the SQL branch started from `main@59155cc7db7e29eab7d601e8a22e6d337fdd824a`.
**Repository state last verified:** `main@9c3330e85fea63bcc769d137c0551d46b4b7f1f2` (includes merged [PR #628](https://github.com/im-tnyx/tio-world/pull/628) stale-handoff docs after [PR #626](https://github.com/im-tnyx/tio-world/pull/626))
**Branch:** Historical feature branch `tnyx/issue-569-default-identity-move-regression-fb6f` merged via [PR #626](https://github.com/im-tnyx/tio-world/pull/626)
**HEAD SHA:** SQL behaviour last changed in `c7081b37b41072c3e5a10c7c32875ccd7996935c`. Final pre-squash PR head was `d66cc57e9d68307a00f83ee1650e3e3d1df2972f`, proven by exact-head Supabase Database CI [run 39381841484](https://github.com/im-tnyx/tio-world/actions/runs/39381841484) SUCCESS and Commit attribution guard [run 39381839072](https://github.com/im-tnyx/tio-world/actions/runs/39381839072) SUCCESS. Squash merge commit on `main` is `fbf132841597bae8ff41aac3e2d8d1b922b49d35`.
**Observed working-tree state:** Post-merge reconcile uses a clean worktree from `origin/main`; primary checkouts left untouched
**Observed uncommitted/dirty files:** None in this docs worktree. Unrelated dirty generated/tooling files in other checkouts must not be modified for this slice.
**PR / tracker:** [PR #626](https://github.com/im-tnyx/tio-world/pull/626) **MERGED** 2026-10-20T06:56:06Z as squash `main@fbf132841597bae8ff41aac3e2d8d1b922b49d35`. GitHub #569 remains Open. Linear TNYX-81 remains Backlog. Production Move remains OFF. Prior archived `#569` child headers that still say unmerged are historical snapshots; live GitHub merge state wins.
**Current implementation state:** Disposable SQL matrices are on `main` via PR #626. SQL behaviour last changed in `c7081b37b41072c3e5a10c7c32875ccd7996935c` and is proven by exact-head Database CI on final PR head `d66cc57e`. The deleted-source savepoint moves the canonical default from 011 to 013 before deleting 011 so the canonical default stays present while proving 031 is not promoted. A zero-default owner is a separate #568 lazy-resolver state and is not covered here.
**Relevant execution surface:** `supabase/tests/database/tnyx_569_existing_program_routine_move.test.sql`, `supabase/tests/database/tnyx_569_atomic_create_program_move.test.sql`
**Validation completed at SHA:** Exact-head Database CI on final [PR #626](https://github.com/im-tnyx/tio-world/pull/626) head `d66cc57e9d68307a00f83ee1650e3e3d1df2972f` proves the SQL behaviour last changed in `c7081b37b41072c3e5a10c7c32875ccd7996935c` ([DB CI run 39381841484](https://github.com/im-tnyx/tio-world/actions/runs/39381841484) SUCCESS; attribution [run 39381839072](https://github.com/im-tnyx/tio-world/actions/runs/39381839072) SUCCESS). Chat-only bot audit verdicts APPROVE at `56029459dfafe3038a0a7441a179a9415986a811`: Security #05, Engineering Auditor #01, and QA #04, with no P1/P2. Those verdicts are not GitHub APPROVED reviews. GitHub shows 0 formal reviews (historical review limitation). Local Supabase CLI was not available.
**Validation remaining:** None for this disposable-SQL slice. EXECUTE grant, hosted deploy, production Move flag flip, and real five-second Undo remain separately gated and are not claimed complete here.
**Current blocker:** None for this slice source. Hosted ledger is 65 applied through `20261018100000`; repository migration `20261019162535` (#568) is not hosted. This slice does not deploy it. Production Move remains OFF.
**Open review finding IDs:** None open for the merged SQL slice. Historical P3 proof-wording / fixture polish was corrected before merge on PR #626.
**Next exact action:** Independent review of this post-merge docs reconciliation only. Do not grant EXECUTE, deploy hosted migrations, or enable production Move.

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
- [x] SQL behaviour last changed in `c7081b37`; proof is exact-head Database CI on final PR #626 head `d66cc57e` ([run 39381841484](https://github.com/im-tnyx/tio-world/actions/runs/39381841484))
- [x] P3: move the default to 013 before deleting source 011
- [x] P3: relabel post-rollback default checks as sanity checks
- [x] [PR #626](https://github.com/im-tnyx/tio-world/pull/626) **MERGED** as squash `main@fbf132841597bae8ff41aac3e2d8d1b922b49d35` (2026-10-20T06:56:06Z)
- [x] Post-merge docs reconcile: replace stale Ready-for-Review / No-Merge tracker wording (this docs-only follow-up)

## 6. Quality Review

### Validation Run

```text
Historical PR #626 exact-head proof (preserved):
- SQL behaviour last changed in c7081b37b41072c3e5a10c7c32875ccd7996935c.
- Final PR head d66cc57e9d68307a00f83ee1650e3e3d1df2972f:
  Supabase Database CI run 39381841484 SUCCESS
  Commit attribution guard run 39381839072 SUCCESS
- Chat-only bot audit verdicts APPROVE at 56029459dfafe3038a0a7441a179a9415986a811:
  Security #05, Engineering Auditor #01, QA #04. No P1/P2.
  These are not GitHub APPROVED reviews. GitHub shows 0 formal reviews.
- Owner approval of the test-only scope is chat-only (Santosh, 2026-10-20)
  and is not recorded on GitHub #569.
- No Flutter files changed in the SQL slice, so Flutter CI did not run for it.
- No hosted SQL executed. Production Move remains OFF.

Post-merge docs reconcile validation:
- git diff --check on the docs-only reconcile branch
- git merge-base --is-ancestor origin/main HEAD
- Changed-file scope limited to .ai/tasks handoff wording
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| SHA/CI | P3 | Corrected (pre-merge) | Brief and index said SQL was proven at `6e1d6f7a` | `6e1d6f7a` | SQL behaviour last changed in `c7081b37`. Proof is exact-head Database CI on final PR #626 head `d66cc57e` ([run 39381841484](https://github.com/im-tnyx/tio-world/actions/runs/39381841484)) |
| Approval | P3 | Corrected (pre-merge) | Approval status said Not required, then read as a GitHub record | `6e1d6f7a` | Chat-only owner approval (Santosh, 2026-10-20), not recorded on GitHub #569. Chat-only bot audit verdicts Security #05, Engineering Auditor #01, QA #04 APPROVE at `56029459`. Not GitHub APPROVED reviews; GitHub shows 0 formal reviews |
| Deleted source | P3 | Corrected (pre-merge) | Savepoint deleted the only default and the comment treated zero defaults as invalid | `6e1d6f7a` | Fixture still moves the default 011 → 013 before delete. Comment now says that keeps the canonical default present while proving 031 is not promoted. Zero-default is a separate #568 lazy-resolver state and is not covered here |
| Sanity labels | P3 | Corrected (pre-merge) | Post-`expect_state` default asserts cannot observe a committed rejection | `6e1d6f7a` | Atomic messages already say post-rollback sanity. The existing-move message and comment now say post-rollback sanity check. Predicates unchanged |
| Post-merge status | P3 | Corrected (this docs slice) | Index/brief still said Ready for review / No merge after PR #626 landed | `main@9c3330e8` | Record MERGED squash `fbf132841597bae8ff41aac3e2d8d1b922b49d35`, preserved CI SHAs, Production Move OFF |

## 7. Final Handoff

### Changed Files

Historical SQL slice (merged in PR #626):

- `supabase/tests/database/tnyx_569_existing_program_routine_move.test.sql`
- `supabase/tests/database/tnyx_569_atomic_create_program_move.test.sql`
- `.ai/tasks/issue-569-default-identity-move-regression.md`
- `.ai/tasks/README.md`

Post-merge docs reconcile only:

- `.ai/tasks/issue-569-default-identity-move-regression.md`
- `.ai/tasks/README.md`
- `.ai/tasks/issue-569-stale-handoff-reconcile.md` (one QA evidence cell that still called #626 unmerged)

### Actual Behavior

Disposable tests on `main` require one canonical `is_default` Program to survive existing Move, Create & Move, replay, and a later Move. The deleted-source savepoint moves that default to 013 before deleting 011 and checks that 031 is not promoted. Authenticated clients still cannot write `is_default`. The RPCs themselves are unchanged. Production Move remains OFF.

### Known Limitations

Local Supabase runner was unavailable for the SQL slice. Hosted #568 migration remains unapplied. Production Move stays OFF. SQL behaviour last changed in `c7081b37b41072c3e5a10c7c32875ccd7996935c` and is proven by exact-head Database CI on final PR #626 head `d66cc57e` ([run 39381841484](https://github.com/im-tnyx/tio-world/actions/runs/39381841484)). Chat-only bot audit verdicts (Security #05, Engineering Auditor #01, QA #04) APPROVE at `56029459`. They are not GitHub APPROVED reviews. GitHub shows 0 formal reviews. Owner approval of the test-only scope is chat-only (Santosh, 2026-10-20) and is not recorded on GitHub #569. This handoff does not claim production activation, EXECUTE grants, hosted deploy, or real Undo.

### Final Status

`MERGED` — disposable SQL regression via [PR #626](https://github.com/im-tnyx/tio-world/pull/626) squash `main@fbf132841597bae8ff41aac3e2d8d1b922b49d35`. Production Move OFF.