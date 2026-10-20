# Pre-P9 — Supabase public inventory reconciliation (66 migrations)

**Status:** In progress — PR #640 Open / Ready for Review; independent `im-tio` CHANGES_REQUESTED on reviewed `d0a8a5d3`. Owner-local guarded `git diff --check` **PASS (exit 0)** was received at exact `d0a8a5d3`; this subsequent handoff correction requires fresh final-HEAD validation/re-review. No merge authorization.
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
**Review owner:** Independent `im-tio` CHANGES_REQUESTED on exact `d0a8a5d3` for this stale validation handoff; previous content findings fixed, fresh review pending after correction
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
**Validation completed:** Prior read-only source/live-schema audit; GitHub full-file/patch hygiene; App-pinned Commit attribution guard and runner SUCCESS at reviewed `d0a8a5d353da39e44caf81692b085a1904e0f670`; **owner-executed guarded Windows PowerShell `git diff --check` PASS exit `0` on exact `origin/main@9e1b96f4cc5d8928887b2be5c99ec41a3692ab6f` to PR HEAD `d0a8a5d353da39e44caf81692b085a1904e0f670`**, clean tree, fetch, ancestry and three expected Markdown paths confirmed. [Owner receipt and thread disposition](https://github.com/im-tnyx/tio-world/pull/640) were recorded; earlier `e2af0c96` PASS is historical.
**Validation remaining:** This handoff correction creates a later PR HEAD; re-check its CI and obtain a **new guarded owner-local `git diff --check` PASS for that subsequent final HEAD**. The `d0a8a5d3` receipt is valid only for its exact SHA, not for this subsequent commit. Obtain independent `im-tio` formal re-review; no APPROVED vote or merge authorization yet.
**Current blocker:** Independent `im-tio` verified the `d0a8a5d3` exact-head owner-local PASS but requested reconciliation of the stale handoff/PR checklist (`PRRT_kwDOTOXwB86ud_qN`). That documentation correction is now scoped here; `CHANGES_REQUESTED` persists until fresh post-correction CI/local validation and independent review. Prior content/Codex task-status threads were resolved. Granular live table/column ACL metadata query was blocked and is not claimed PASS.
**Review finding disposition:** Seven earlier review threads resolved, including guarded diff receipt `PRRT_kwDOTOXwB86uc-oe` and canonical `In progress` status `PRRT_kwDOTOXwB86udYgd`. **Open independent P2** `PRRT_kwDOTOXwB86ud_qN`: brief and PR checklist still described the now-verified `d0a8a5d3` receipt as missing; this handoff reconciles that historical exact-HEAD receipt. The new commit will still need its own final-HEAD validation and reviewer disposition.
**Next exact action:** Reconcile the PR #640 body checklist to the `d0a8a5d3` PASS receipt. Validate the new final GitHub HEAD and required checks, then obtain guarded owner-local Windows `git diff --check` PASS for that new HEAD; request independent `im-tio` review and resolve the new P2 thread only after confirmed disposition. Separate owner `Go merge` only after clean gate.

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
- **Independent review:** `im-tio` returned **CHANGES_REQUESTED**, not APPROVED, on exact `d0a8a5d3`, after acknowledging the owner-local guarded diff receipt **PASS exit 0** for that exact SHA. The remaining P2 requests that this active brief and PR checklist stop representing that specific receipt as missing. Earlier Codex/status, grant and terminology issues were corrected and their seven threads resolved; the new correction must undergo fresh exact-HEAD re-review. The catalog count remains **129 catalog constraint records**, including 2 constraint-trigger records.
- **Docs-only validation boundary:** GitHub API hygiene scans do not replace `git diff --check`. The owner **provided** a guarded Windows PowerShell transcript for `origin/main@9e1b96f4...` and exact PR HEAD `d0a8a5d3...`, checking clean working tree, fetch, ancestry, exact three-file scope and `git diff --check` **PASS exit 0**. Receipt posted to and resolved in independent validation thread `PRRT_kwDOTOXwB86uc-oe`. That PASS belongs to `d0a8a5d3`, not to any later documentation correction SHA.
- App-pinned Commit attribution guard and runner completed SUCCESS on `d0a8a5d3`; re-verify on this subsequent commit. The owner-local `d0a8a5d3` receipt **passed** and is recorded without claiming coverage of future SHAs. No formal independent APPROVED review or merge is claimed; new `im-tio` handoff-consistency P2 requires re-review.
