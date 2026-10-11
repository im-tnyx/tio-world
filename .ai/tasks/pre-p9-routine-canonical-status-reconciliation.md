# Pre-P9 — Routine Composition Canonical Status Reconciliation

**Status:** In progress
**Primary owner:** Repository documentation governance; `docs/data/` and `docs/screens/` (Workout-owned contract)
**Affected platforms:** Documentation only; no production behavior change

## Owner Approval and Scope Boundary

**Trigger:** None — bounded documentation correction after a read-only GitHub #250 canonical-contradiction audit.
**Approval status:** Approved for this documentation slice by the owner's `Go` on 2026-10-11.
**Approved boundaries:** Reconcile the merged Routine composition Flutter adapter and closed GitHub #509 statuses in `docs/data/SUPABASE_STRATEGY.md` and `docs/screens/routine-library.md`. Keep this short task handoff and its index.
**Explicit non-changes:** No Flutter source, application provider/controller or builder activation, UI/navigation, Supabase schema/RLS/RPC/grants, migrations, server credentials, CI workflows, lockfile, P9 routing map, GitHub #250 acceptance-checkbox edit, or lifecycle archive of older execution records. Separate owner authorization is required for merge.

## Verified Current Truth

- Audit baseline: protected `main@e0a340dd902f0490cc819343858db3dabf7f92b4`, after merged PR #518 corrected `docs/data/SUPABASE_SCHEMA.md`.
- GitHub #250: **Open**, acceptance criterion 1 checked; criterion 2 (canonical contradictions) unchecked; P9 **Not started**. Linear TNYX-193 remains **In Progress**.
- GitHub #509: **Closed**. Its dated body still says it remains open; that is historical/stale tracker prose, not live issue state.
- PR #513: **Merged** at `dfe9cee7389165f0a485623a1e3e69477eb1dc37` after review.
- Source: Workout-owned `RoutineCompositionRepository` and `SupabaseRoutineCompositionRepository` exist under `apps/features/workout`, with owner-scoped complete reads and RPC save/reconciliation. No Routine builder/page or app provider/controller activation was identified in the current repository tree. This is not an app-release claim.
- Linear TNYX-78: **In Progress** for broader W1 work. Routine creation via direct Library entry remains subject to a separate stable default `My Program` identity decision, not part of the merged adapter.
- Existing `docs/data/SUPABASE_SCHEMA.md` already distinguishes merged adapter and pending builder. Existing historical `.ai/tasks/issue-509-routine-composition-persistence.md` and `.ai/tasks/pre-p9-routine-composition-schema-status.md` still include dated review-state language; they need separately authorized lifecycle reconciliation and are not modified in this slice.

## Implementation and Review Gate

1. Correct only status sentences in `docs/data/SUPABASE_STRATEGY.md` and `docs/screens/routine-library.md`, preserving architectural ownership and actual database/RPC security claims.
2. Add one focused task-index entry in `.ai/tasks/README.md`.
3. Inspect `main...HEAD` for exact four-path docs-only scope, branch drift, link integrity, unintended history, whitespace errors and required checks.
4. Request Codex review of exact final PR head; address actionable findings and recheck gates.
5. Stop before merge, awaiting the owner's explicit `Go merge`. Archive the validated handoff separately after merge, not in this PR.

**Validation limits:** Work is through the connected GitHub API, without a local checkout. Local `git status -sb`, `git diff --check`, Flutter tests and Supabase commands were not run in this slice; no pass claim is made. GitHub patch inspection is not a substitute for executing `git diff --check`.

## Handoff

**Planning:** GitHub #250 / Linear TNYX-193.
**Implementation:** Docs-only status reconciliation.
**Review:** Codex exact-head PR review plus mandatory GitHub attribution check.
**Branch:** `docs/pre-p9-routine-canonical-status-reconciliation`
**Baseline:** `main@e0a340dd902f0490cc819343858db3dabf7f92b4`
**Current checkpoint:** Documentation correction branch in progress.
**Next exact action:** Verify PR diff, required checks and exact-head Codex review; do not merge without owner authorization.
