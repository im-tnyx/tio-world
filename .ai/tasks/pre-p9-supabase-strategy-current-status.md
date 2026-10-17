# Pre-P9 — Supabase strategy current-state reconciliation

**Status:** In progress — docs-only factual correction staged, exact-head PR review and separate merge authorization required
**Primary owner:** Supabase data documentation + repository governance
**Affected platforms:** Canonical Supabase strategy status only; no production/runtime/database or mobile/wearable implementation

## Owner Approval and Scope Boundary

**Trigger:** No new product task/feature/UI/data-shape approval trigger; documentation-only correction within the owner-authorized continuing [GitHub #250](https://github.com/im-tnyx/tio-world/issues/250) / [Linear TNYX-193](https://linear.app/tnyx/issue/TNYX-193) canonical-contradiction effort.
**Approval status:** Owner said `Go next with frash audit` after merged #584 on 2026-10-17; this authorizes one smallest drift slice, not merging it.
**Approved boundary:** Correct only the dated current-state bullets and verification date in [`docs/data/SUPABASE_STRATEGY.md`](../../docs/data/SUPABASE_STRATEGY.md), preserving its architecture and future services/connector/security/storage/AI policy unchanged. Index this execution brief in `.ai/tasks/README.md`.
**Explicit non-changes:** No `supabase/` SQL, migration, RLS, RPC, Storage or secrets change; no app/watch/Flutter source, release, UI redesign, schema inventory duplication, CI or lockfiles; no P9 start, broad #250 acceptance checkbox or other stale active-task cleanups.

## Verified source, migrations, trackers (2026-10-17)

- Protected remote `main@7f5f49ebdd7c699fc1977931e15fad65ee427324` is merged #584; the canonical [current schema inventory](../../docs/data/SUPABASE_SCHEMA.md) was corrected on `main` by #584. No open GitHub PR before this branch. GitHub #250 **Open**, final no-contradiction acceptance unchecked; Linear TNYX-193 **In Progress**.
- `supabase/migrations/` contains **62** files, and connected `tio-world` live Supabase lists exactly **62** applied migrations with the same ordered version+name through `20261016220000_prevent_deleted_routine_resurrection`. No migration or database write performed. Read-only live catalog: **19** ordinary `public` tables, **19/19** RLS enabled; all four Routine Create/Save/Name+composition Update/Delete RPCs exist with SECURITY DEFINER, empty search_path, `authenticated` EXECUTE and no `anon`/`PUBLIC` EXECUTE.
- Actual Flutter shell `apps/app/lib/app/routing/shell/shell_route.dart` wires auth- and owner/session-guarded `CreateRoutinePage` and full Edit/Detail/Library access using `routineCompositionRepositoryProvider`, catalog, and Profile weight-unit gate. `apps/features/workout/lib/src/presentation/library/routines/routine_composer_screen.dart` is the single shared Create/Edit presentation. No active Workout session or Move/Delete UI launch is established by these reads.
- Relevant upstream GitHub PRs: #551, #570, #577 and #581 all **merged**; #584 current schema docs **merged**. Canonical [Routine screen](../../docs/screens/routine-library.md) documents current Create/Edit/Set persistence and Core 3-dot sheet, with Move/Delete and Workout Start separately gated; it distinguishes checked-in implementation from distributed release.
- Live Linear [TNYX-78](https://linear.app/tnyx/issue/TNYX-78) **In Progress**, [TNYX-81](https://linear.app/tnyx/issue/TNYX-81) **Backlog**. Neither proves app delivery. Existing 2026-10-11/12 Supabase strategy status still says 55 migrations/current read-only-only Flutter; stale against the verified main and deployed migration state.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** Isolated GitHub-connected docs-only branch; no access to local Windows git worktree
**Review owner:** Source-backed exact-head manual/independent PR review
**Implementation ownership state:** Active (documentation only)
**Ownership transition:** Not applicable
**Repository state last verified:** Remote protected `main@7f5f49ebdd7c699fc1977931e15fad65ee427324`; local `G:\projects\Tio-World` unavailable and untouched
**Branch:** `docs/pre-p9-supabase-strategy-current-status`
**Observed working-tree state:** Not accessible; GitHub repository API read/write only
**Observed uncommitted/dirty files:** Not assertable without local Windows `git status`
**PR / tracker:** Draft PR pending; GitHub #250 / Linear TNYX-193 open work
**Current implementation state:** Correct dated current-status paragraphs while keeping policy/architecture text untouched
**Relevant execution surface:** `docs/data/SUPABASE_STRATEGY.md`, this focused task brief, task index
**Validation completed:** Read-only GitHub PR/source, tracker, repo and Supabase migration/RPC/metadata audit.
**Validation remaining:** Final SHA Markdown/relative-link/three-file diff audit; required protected attribution check; review threads; owner merge gate.
**Current blocker:** None in the bounded audit; review and merge remain separate gates
**Open review finding IDs:** None at task start
**Next exact action:** Complete docs-only patch; open Draft PR; do not merge on `Go next`.
