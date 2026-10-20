# Pre-P9 — Supabase public inventory reconciliation (66 migrations)

**Status:** In Review — PR #640 Open / Ready for Review; Codex P2 documentation corrections staged, independent `im-tio` CHANGES_REQUESTED (one P2 validation blocker, one P3 terminology correction), not merge-ready
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
**Validation completed:** GitHub source/migration/tracker audit, live read-only pg_catalog and migration ledger
**Validation remaining:** Revalidate final PR HEAD, changed paths/links, required pinned attribution check and both inline P2 review threads; independent `im-tio` formal submission remains pending
**Current blocker:** Independent `im-tio` P2 requirement for guarded owner-local `git diff --check` at exact final base/head lacks a result receipt. Two Codex P2 corrections and independent P3 terminology correction need final-HEAD verification and inline disposition; `im-tio` CHANGES_REQUESTED remains active until reviewer reassessment. Table/column ACL metadata query was blocked; source-backed grant statements are not an independent live ACL PASS.
**Open review finding IDs:** Codex P2 `PRRT_kwDOTOXwB86uc4lZ` (retired Routine `UPDATE(name)`, corrected), Codex P2 `PRRT_kwDOTOXwB86uc4lf` (stale handoff state, corrected), independent P2 `PRRT_kwDOTOXwB86uc-oe` (owner-local guarded `git diff --check` receipt, **BLOCKED** in GitHub-only tools), independent P3 `PRRT_kwDOTOXwB86uc-oj` (catalog record terminology, corrected). Review threads remain until each finding disposition is posted.
**Next exact action:** Revalidate final PR #640 HEAD, post source-backed inline dispositions for three corrected documentation findings; do **not** resolve the P2 owner-local diff-check finding until a guarded exact-head command/exit receipt is supplied. Ask `im-tio` to re-review after receipt and updated checks. A separate owner `Go merge` is mandatory; do not merge under this review turn.

## 2026-10-20 Verified Evidence

- Root `AGENTS.md`, `.ai/workflow.md`, task template, canonical docs/ownership/architecture, GitHub #250/#568, Linear TNYX-193/TNYX-78 and current schema inventory inspected.
- **66** repository migration files match **66** deployed Tio-world migrations exactly by version and name, ending `20261019162535_w1_my_program_atomic_default_create.sql`. Earlier 62/62 (October 17) and 65/66 snapshots are history.
- Live `public`: **19** ordinary tables, all RLS enabled, **191** columns, **129** catalog constraint records (including two constraint-trigger records), **55** indexes. Current inventory's previous 190/190 columns and 54/54 index definitions match catalog; new `user_workout_programs.is_default boolean NOT NULL DEFAULT false` and unique partial index `idx_user_workout_programs_owner_default` are missing from document. All 129 prior catalog constraint-record names still exist (including two constraint-trigger records). Constraint definition formatting from `pg_get_constraintdef` varies with pretty-print argument; no unrelated constraint body change authorized.
- Seven Routine/Move/My Program RPC signatures exist: four former Routine CRUD/composition RPCs allow authenticated EXECUTE; three staged Move/Create+Move/first-Routine RPCs deny authenticated/anon/PUBLIC/service_role EXECUTE. All seven use SECURITY DEFINER and empty search_path.
- W1 checked-in migration revokes table-wide authenticated Program INSERT, granting only INSERT(id,user_id,name); old inventory's blanket Program INSERT statement is no longer source-correct. A separate read-only ACL-catalog query was blocked by platform checks, so the precise current live column-grant list is **not independently verified** in this audit.
- Read-only Set-position constraint catalog check remains `NOT VALID`. GitHub #568 Open, Linear TNYX-78 In Progress. Move/first-Routine release remains separately gated. No mutating SQL executed.

## Decisions, Validation, Handoff

Use one canonical readable inventory, with checked-in migrations and live metadata as executable truth. Do not extend this task into strategy/Workout status reconciliation, new feature wiring, app release, or migration deployment.

Verify three-path docs-only diff, Markdown hygiene, new link targets, full content, required attribution check and actual review outcomes. GitHub API validation **is not** the required owner-local guarded `git diff --check` receipt. Flutter/device QA is not applicable; no merge until required checks, review disposition and a separate owner `Go merge`.

### Review finding disposition — 2026-10-20

- **Codex P2 / Routine UPDATE grant (`PRRT_kwDOTOXwB86uc4lZ`):** Confirmed. Checked-in *applied* `20261017154241_retire_legacy_routine_name_update.sql` revokes `UPDATE(name)` and runs a fail-closed privilege-invariant block. Canonical inventory incorrectly repeated its October 17 pre-retirement grant; corrected to source/ledger-backed direct UPDATE denial and explained RLS policies vs table privileges. No separate live ACL introspection success is claimed.
- **Codex P2 / inconsistent task review state (`PRRT_kwDOTOXwB86uc4lf`):** Confirmed. This handoff now agrees with `.ai/tasks/README.md` that [PR #640](https://github.com/im-tnyx/tio-world/pull/640) is **Open / Ready for Review**, not Draft or not yet opened. Lists reviewed original HEAD and correction evidence while directing owner to live PR for final HEAD; does not manufacture a self-referential final commit SHA.
- **Independent review** by `im-tio` on original HEAD `72a597fa032450ce2ecb2c1892687daeed60e8ce` returned **CHANGES_REQUESTED**, not APPROVED. It confirmed the two Codex P2s plus a separate P2 guarded owner-local `git diff --check` receipt (not yet available) and P3 count terminology. Task index and this brief now consistently say **129 catalog constraint records**, including 2 constraint-trigger records.
- **Docs-only validation boundary:** Full-file and GitHub diff hygiene are inspected using GitHub APIs. A container attempt to contact the GitHub remote failed due to DNS; the owner Windows working tree is not connected. Neither is a successful guarded `git diff --check` and no receipt is invented. Request an exact-base/head, clean-local-tree PowerShell run from the owner when final SHA is settled.
- Review threads remain pending until updated PR HEAD, required checks and actual inline responses are checked. No independent approval is claimed.
