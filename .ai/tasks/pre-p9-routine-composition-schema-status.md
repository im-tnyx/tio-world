# Pre-P9 — Routine Composition Schema-Status Drift

**Status:** In progress
**Primary owner:** repository documentation governance (`docs/data/`)
**Affected platforms:** Documentation only; Flutter/Supabase behavior unchanged

## Owner Approval and Scope Boundary

**Trigger:** None — bounded docs-only correction following the owner's read-only GitHub #250 audit.
**Approval status:** Approved for this docs-only slice via user's `Go` on 2026-10-11.
**Approved boundaries:** Correct the one stale Flutter Routine composition adapter status sentence in `docs/data/SUPABASE_SCHEMA.md`, preserving the verified live schema/RPC text and unactivated builder boundary. Maintain this compact execution handoff and task index.
**Explicit non-changes:** No Supabase schema/migration/RLS/RPC/security modification, Flutter implementation, provider/controller or UI builder activation, CI workflow, dependency/lockfile, P9 initiation, GitHub #250 acceptance-checkbox changes, or broader status-document rewrite. No merge without separate explicit authorization.

## Discovery and Evidence

- Fresh base: `main@3b98b293b1e602ebaed08e20838e61809698ea42` (2026-10-11, PR #517 merged).
- GitHub #250 remains open, P1–P8 completed and P9 Not started.
- The schema inventory's `Routine Composition RPC` section correctly documents the verified hosted RPC but incorrectly ends: `The Flutter composition adapter and visible builder remain pending.`
- PR #513 (`feat(flutter): add Routine composition persistence adapter`) is merged as `dfe9cee7389165f0a485623a1e3e69477eb1dc37`.
- Runtime source contains `apps/features/workout/lib/src/domain/repositories/routine_composition_repository.dart` and `apps/features/workout/lib/src/data/repositories/supabase_routine_composition_repository.dart`, including revision-validated reads, owner-scoped data requests and RPC save/reconciliation.
- `docs/screens/routine-library.md` and `docs/data/SUPABASE_STRATEGY.md` already distinguish the implemented adapter from unactivated provider/controller/builder; older embedded PR-pending statements in other handoffs/docs are follow-up drift outside this approved correction.
- GitHub #509 issue is currently **closed** although its dated body still says `open`; this task does not reconcile or reopen its tracker history.
- The Linear connector is unavailable in this session; **TNYX-193/TNYX-78 were not re-queried**, so no fresh Linear status claim is made.

## Scope and Validation

1. Replace only the stale adapter/builder status sentence in the canonical schema inventory with grounded merged-state wording.
2. Keep verified migration count, tables, structural metadata, security claims, and RPC description unchanged.
3. Index this bounded execution handoff in `.ai/tasks/README.md`.
4. Review exact `main...HEAD` changed files, patch hygiene and reference correctness; request Codex exact-head review, inspect published required checks and unresolved threads.
5. Stop before merge.

**Local validation limitation:** Work uses connected GitHub APIs rather than a local checked-out repository; `git status -sb`, `git diff --check`, Flutter tests and Supabase commands have not run here. Do not claim they passed. No Supabase live read/write is needed for this docs-only status correction.

## Handoff

**Branch:** `docs/pre-p9-routine-composition-schema-status`
**Implementation owner:** repository docs-governance slice
**Review owner:** Codex and exact-head gate audit
**Current state:** scoped docs-only patch in progress; awaiting review/merge gate
**Next action:** finish bounded patch, verify current PR head + source evidence, stop before owner-authorized merge. Archive only after validated merge in a separate lifecycle step.
