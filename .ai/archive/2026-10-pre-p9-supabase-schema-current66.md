# Pre-P9 — Supabase public inventory reconciliation (66 migrations)

**Status:** Validated historical snapshot — PR #640 approved and squash-merged on 2026-10-20; this file preserves the 66/66 documentation slice and is no longer an active implementation handoff.
**Primary owner:** Supabase data documentation governance
**Affected platforms:** Canonical public schema inventory only

## Final disposition — 2026-10-22 archive review

- [PR #640](https://github.com/im-tnyx/tio-world/pull/640) is **merged** (squash [`da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79`](https://github.com/im-tnyx/tio-world/commit/da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79)); exact final PR head `98f41428c4b40a0be7d55dc5b67cdbeeba45185e` had independent `im-tio` GitHub **APPROVED** review, 10/10 review threads resolved, required app-pinned attribution guard and runner SUCCESS, and an owner-executed guarded Windows `git diff --check` **PASS / exit 0** against `main@9e1b96f4cc5d8928887b2be5c99ec41a3692ab6f`. Owner explicitly authorized `Go merge with gate`; protected `main` contained the resulting squash commit. Later owner-local main sync to that SHA reported clean.
- **This is a historical 66/66 inventory reconciliation.** After later separately authorized #568/#569 migrations, the current `docs/data/SUPABASE_SCHEMA.md` and `docs/data/SUPABASE_STRATEGY.md` record a separately verified **68/68 hosted migration checkpoint** (2026-10-21). The two migrations modify existing RPC body/privilege boundaries, not the previously measured 19-table/191-column/55-index structure. Source, verified live schema, current canonical docs and linked GitHub/Linear trackers override older status claims below.
- **Historical record boundary:** sections below are the preserved pre-merge execution and reviewer handoff. Any references below to PR Open, `CHANGES_REQUESTED`, waiting for local validation, or 66/66 as the most recent live count are **past checkpoints, not current blockers**. Do not mutate these dated evidentiary statements merely to imply fresh measurement.
- GitHub [#250](https://github.com/im-tnyx/tio-world/issues/250) stays **Open**, Linear [TNYX-193](https://linear.app/tnyx/issue/TNYX-193) stays **In Progress**, because whole-catalog contradiction acceptance is unchecked; P9 is not started. This archive does not authorize feature deployment, RPC grants, production Workout activation or a broad documentation sweep.

## Owner Approval and Scope Boundary

**Trigger:** None — continuing approved GitHub #250 / Linear TNYX-193 documentation governance slice.
**Approval status:** Approved for bounded documentation correction by owner `Next go @GitHub @Linear follow agent.md` (2026-10-20).
**Approved scope:** Correct dated migration count, one deployed Program column, one index, three newly deployed dormant RPCs and stale Program INSERT prose in `docs/data/SUPABASE_SCHEMA.md`. Add this focused handoff and task index row.
**Explicit non-changes:** No SQL migration, live database write, grant/RLS modification, Flutter/UI, AI/connector, service, CI, lockfile, strategy or Routine screen edit. No feature/release activation, P9 start or broad #250 acceptance promotion.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** Isolated GitHub docs-only branch
**Review owner:** Independent `im-tio` CHANGES_REQUESTED on exact `d6d35d51` review `5589937670`; handoff/index consistency P2 acknowledged in its inline thread, fresh formal review pending
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
**Validation completed:** Prior read-only source/live-schema audit and GitHub patch/full-file hygiene. The owner supplied guarded Windows PowerShell `git diff --check` **PASS / exit 0** for `origin/main@9e1b96f4cc5d8928887b2be5c99ec41a3692ab6f` versus exact PR HEAD `d6d35d51a204992807895f42e092869e350b52e0` (clean tree, fetch, ancestor and three-file scope gates). Exact `d6d35d51` GitHub check-runs: App-pinned Commit attribution guard (App 5032971) and Attribution guard runner (App 15368) both SUCCESS. [Owner-local exact-HEAD receipt in PR review thread](https://github.com/im-tnyx/tio-world/pull/640); prior `d0a8a5d3` and `e2af0c96` receipts remain historical.
**Validation remaining:** Independent `im-tio` formal re-review/approval and separate owner merge authorization remain outstanding. A task brief cannot self-validate the commit containing its own update: read the live PR HEAD and its SHA-specific Windows diff-check receipt and GitHub check-runs at final gate; never transfer the historical `d6d35d51` PASS to a later commit. No other CI or live ACL result is presumed.
**Current blocker:** Independent `im-tio` review `5589937670` confirmed exact `d6d35d51` owner-local PASS, but P2 `PRRT_kwDOTOXwB86ueQRf` found this handoff and the task index still called that receipt pending. Those two documents are being corrected in this same bounded slice; formal `CHANGES_REQUESTED` remains until reviewer disposition. Granular live table/column ACL metadata remained unavailable and is not claimed PASS.
**Review finding disposition:** Eight earlier review threads resolved, including owner-local validation `PRRT_kwDOTOXwB86uc-oe`, task-status `PRRT_kwDOTOXwB86udYgd`, and previous handoff P2 `PRRT_kwDOTOXwB86ud_qN`. **Open independent P2** `PRRT_kwDOTOXwB86ueQRf` (review `5589937670`): this brief and `.ai/tasks/README.md` contradicted the verified `d6d35d51` receipt. Both corrections must be inspected in a subsequent exact-head reviewer pass; replying alone is not resolution.
**Next exact action:** After this two-file reconciliation, verify PR #640's latest HEAD and exact-head checks, obtain a guarded owner-local Windows `git diff --check` receipt on that latest SHA, then have `im-tio` independently re-review this P2 and issue a formal updated review. Resolve the inline thread only after verified disposition; separate owner `Go merge` after clean gate.

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
- **Independent review:** `im-tio` returned **CHANGES_REQUESTED**, not APPROVED, on exact `d6d35d51` in review `5589937670`, after acknowledging its guarded Windows diff-check PASS / exit 0. The remaining P2 `PRRT_kwDOTOXwB86ueQRf` requires the task brief and task index to reflect this known receipt. Earlier Codex/status, grant and count terminology issues were corrected; the present two-file reconciliation must receive fresh exact-head re-review. The catalog count remains **129 catalog constraint records**, including 2 constraint-trigger records.
- **Docs-only validation boundary:** GitHub API hygiene checks are separate from owner-local `git diff --check`. The owner **provided** a guarded Windows PowerShell transcript for base `origin/main@9e1b96f4...` and reviewed PR HEAD `d6d35d51...`: clean tree, fetch, ancestry and exact three-file scope, with `git diff --check` **PASS / exit 0**. This exact-HEAD evidence was posted in inline thread `PRRT_kwDOTOXwB86ud_qN` and acknowledged by independent review `5589937670`. Earlier `d0a8a5d3` receipt remains historical; no receipt is extrapolated across commits.
- GitHub check-runs for exact `d6d35d51` show App-pinned Commit attribution guard (App 5032971) and Attribution guard runner (App 15368) both SUCCESS. This is direct evidence for those named check-runs only; empty workflow/status API results are not a pass, and new commits need their own verification. No formal independent APPROVED review or merge is claimed; `im-tio` handoff-consistency P2 requires re-review.
