# Pre-P9 — Supabase public inventory reconciliation (66 migrations)

**Status:** In progress — PR #640 Open / Ready for Review; independent `im-tio` CHANGES_REQUESTED. Documentation review fixes are staged; owner-local `git diff --check` passed at prior HEAD `e2af0c96`, but must be rerun on this new HEAD. No merge authorization.
**Primary owner:** Supabase data documentation governance
**Affected platforms:** Canonical public schema inventory only

## Owner Approval and Scope Boundary

**Trigger:** None — continuing approved GitHub #250 / Linear TNYX-193 documentation governance slice.
**Approval status:** Approved for bounded documentation correction by owner `Next go @GitHub @Linear follow agent.md` (2026-10-20).
**Approved scope:** Correct dated migration count, one deployed Program column, one index, three newly deployed dormant RPCs and stale Program INSERT prose in `docs/data/SUPABASE_SCHEMA.md`. Add this focused handoff and task index row.
**Explicit non-changes:** No SQL migration, live database write, grant/RLS modification, Flutter/UI, AI/connector, service, CI, lockfile, strategy or Routine screen edit. No feature/release activation, P9 start or broad #250 acceptance promotion.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** Isolated GitHub docs-only branch
**Review owner:** Independent `im-tio` CHANGES_REQUESTED on initial PR HEAD; Codex COMMENTED two P2 documentation findings; manual corrected-head review/disposition pending
**Implementation ownership state:** Active — limited review-finding corrections
**Ownership transition:** Not applicable
**Repository state last verified:** Protected remote `main@9e1b96f4cc5d8928887b2be5c99ec41a3692ab6f`
**Branch:** `docs/issue-250-supabase-public-inventory-66`
**HEAD SHA:** Original Codex-reviewed PR head `72a597fa032450ce2ecb2c1892687daeed60e8ce`; correction commit for the Routine UPDATE paragraph `de00cdfe75db0086997d5567d9f865479629ba08`. The final reviewed head must always be read from live PR #640 (this brief is within the same branch and cannot self-pin its final commit SHA).
**Observed working-tree state:** Local Windows checkout inaccessible; GitHub branch only
**Observed uncommitted/dirty files:** Unknown locally
**PR / tracker:** [PR #640](https://github.com/im-tnyx/tio-world/pull/640) Open / Ready for Review / unmerged; GitHub #250 Open; Linear TNYX-193 In Progress
**Current implementation state:** Current-state correction of one canonical inventory
**Relevant execution surface:** `docs/data/SUPABASE_SCHEMA.md`, this handoff, `.ai/tasks/README.md`
**Validation completed:** GitHub source/migration/tracker audit, live read-only pg_catalog and migration ledger; App-pinned Commit attribution guard and runner SUCCESS at reviewed HEADs; full-file and patch text hygiene; owner-supplied Windows PowerShell `git diff --check` PASS exit `0` with guarded base/head at **prior** PR HEAD `e2af0c96b6d3bedf0fa3e9b2b5d37b13e7ecd680` (receipt posted in [PR #640 inline review](https://github.com/im-tnyx/tio-world/pull/640)).
**Validation remaining:** Verify exact latest HEAD and required checks again, then obtain **new guarded owner-local `git diff --check` result for the final PR HEAD**, since the owner's validated `e2af0c96` receipt was superseded by the later task-status correction. Reconcile Codex task-status P2 with independent reviewer; no APPROVED vote or merge authorization yet.
**Current blocker:** Independent `im-tio` P2 requires a **fresh final-HEAD** owner-local guarded diff-check receipt; prior `e2af0c96` PASS is historical, not transferable to subsequent commits. `im-tio` CHANGES_REQUESTED remains pending updated-head re-review. Earlier content threads were resolved; newly filed Codex task-status P2 has now been corrected to permitted `In progress` (final disposition pending). Granular table/column ACL metadata query remained blocked and is not claimed PASS.
**Review finding disposition:** Resolved content P2 threads `PRRT_kwDOTOXwB86uc4lZ` and `PRRT_kwDOTOXwB86uc4lf`, independent P3 `PRRT_kwDOTOXwB86uc-oj`, and independent wording P2 threads `PRRT_kwDOTOXwB86udHHn` / `PRRT_kwDOTOXwB86udHH7`. **Open independent P2** `PRRT_kwDOTOXwB86uc-oe`: guarded `git diff --check` PASS received at prior head `e2af0c96`, requires repeat on latest corrected HEAD. **Open Codex P2** `PRRT_kwDOTOXwB86udYgd`: standardized task status fix now applied; reply/review disposition pending.
**Next exact action:** Verify current PR #640 HEAD + required attribution checks and the single permitted task-status correction; reply to Codex task-status thread and resolve only if fixed. Require guarded Windows `git diff --check` PASS at **that final exact head**, then resolve the independent validation thread and request `im-tio` formal re-review. Separate owner `Go merge` only after clean gate.

## 2026-10-20 Verified Evidence

- Root `AGENTS.md`, `.ai/workflow.md`, task template, canonical docs/ownership/architecture, GitHub #250/#568, Linear TNYX-193/TNYX-78 and current schema inventory inspected.
- **66** repository migration files match **66** deployed Tio-world migrations exactly by version and name, ending `20261019162535_w1_my_program_atomic_default_create.sql`. Earlier 62/62 (October 17) and 65/66 snapshots are history.
- Live `public`: **19** ordinary tables, all RLS enabled, **191** columns, **129** catalog constraint records (including two constraint-trigger records), **55** indexes. Current inventory's previous 190/190 columns and 54/54 index definitions match catalog; the W1 `user_workout_programs.is_default boolean NOT NULL DEFAULT false` column and unique partial index `idx_user_workout_programs_owner_default` **were absent from the previous 62-migration inventory and are now documented in this PR's updated canonical inventory**. All 129 prior catalog constraint-record names still exist (including two constraint-trigger records). Constraint definition formatting from `pg_get_constraintdef` varies with pretty-print argument; no unrelated constraint body change authorized.
- Seven Routine/Move/My Program RPC signatures exist: four former Routine CRUD/composition RPCs allow authenticated EXECUTE; three staged Move/Create+Move/first-Routine RPCs deny authenticated/anon/PUBLIC/service_role EXECUTE. All seven use SECURITY DEFINER and empty search_path.
- W1 checked-in migration revokes table-wide authenticated Program INSERT, granting only INSERT(id,user_id,name); old inventory's blanket Program INSERT statement is no longer source-correct. A separate read-only ACL-catalog query was blocked by platform checks, so the precise current live column-grant list is **not independently verified** in this audit.
- Read-only Set-position constraint catalog check remains `NOT VALID`. GitHub #568 Open, Linear TNYX-78 In Progress. Move/first-Routine release remains separately gated. No mutating SQL executed.

## Decisions, Validation, Handoff

Use one canonical readable inventory, with checked-in migrations and live metadata as executable truth. Do not extend this task into strategy/Workout status reconciliation, new feature wiring, app release, or migration deployment.

Verify three-path docs-only diff, Markdown hygiene, new link targets, full content, required attribution check and actual review outcomes. GitHub API validation **is not** the required owner-local guarded `git diff --check` receipt. Flutter/device QA is not applicable; no merge until required checks, review disposition and a separate owner `Go merge`.

### Review finding disposition — 2026-10-20

- **Codex P2 / Routine UPDATE grant (`PRRT_kwDOTOXwB86uc4lZ`):** Confirmed. Checked-in *applied* `20261017154241_retire_legacy_routine_name_update.sql` revokes `UPDATE(name)` and runs a fail-closed privilege-invariant block. Canonical inventory incorrectly repeated its October 17 pre-retirement grant; corrected to source/ledger-backed direct UPDATE denial and explained RLS policies vs table privileges. No separate live ACL introspection success is claimed.
- **Codex P2 / inconsistent task review state (`PRRT_kwDOTOXwB86uc4lf`):** Confirmed. This handoff now agrees with `.ai/tasks/README.md` that [PR #640](https://github.com/im-tnyx/tio-world/pull/640) is **Open / Ready for Review**, not Draft or not yet opened. Lists reviewed original HEAD and correction evidence while directing owner to live PR for final HEAD; does not manufacture a self-referential final commit SHA.
- **Independent review:** `im-tio` returned **CHANGES_REQUESTED**, not APPROVED. The two original Codex P2s, count-terminology P3, and subsequent handoff wording P2s have had verified source-backed fixes and their threads resolved. A guarded owner-local diff receipt was subsequently provided for head `e2af0c96` (PASS/exit 0), but **not for the later amended task-status HEAD**. The newly filed Codex P2 requiring one of the canonical task status values is now corrected to `In progress`. Catalog count label is **129 catalog constraint records**, including 2 constraint-trigger records.
- **Docs-only validation boundary:** GitHub API full-file/diff hygiene scans do not replace `git diff --check`. The owner **provided** a guarded Windows PowerShell transcript for the exact `origin/main@9e1b96f4...` and `origin/docs/issue-250-supabase-public-inventory-66@e2af0c96...` comparison: clean working tree, fetch, ancestry checks, and `git diff --check` **PASS exit 0**. That historical receipt is recorded in the independent validation thread. Since the Codex task-status correction changed the PR SHA afterward, rerun on the **new** final SHA before declaring that gate complete.
- App-pinned Commit attribution guard and runner completed SUCCESS on previously checked PR heads; verify the newest HEAD again. The owner-local `e2af0c96` receipt **passed** but is now superseded by the task-status update. No formal independent APPROVED review or merge is claimed; leave the guarded-diff review thread open until the new exact-head receipt is supplied.
