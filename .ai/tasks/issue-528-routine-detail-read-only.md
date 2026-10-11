# GitHub #528 — Routine card opens owner-scoped read-only Routine Detail

**Status:** In progress; validation/review pending  
**Primary owner:** `apps/features/workout` (Routine presentation/read controller), `apps/app` only for provider/navigation composition  
**Affected platforms:** Flutter phone; no watch, Supabase schema or backend changes

## Owner Approval and scope boundary
**Trigger:** Owner-approved bounded UI slice.
**Approval:** User 2026-10-11 `Go` directly following recommendation: existing GitHub #528 owner-scoped read-only Routine Detail, before full W4B builder; first preserve active #527 anchored popup ownership.
**In:** Program Detail and expanded Library Routine-card *primary tap* → selected Routine read-only detail, using exactly owning ProgramId and RoutineId. Separate Routine overflow **Edit** → existing Rename; no primary Rename. Revision-validated composition read, canonical catalog/user ExerciseRef lookup, ordered entry/set values, counts, missing/empty/failure/permission/retry/back, focused tests. Preserve popup geometry/behavior from owner-approved #527.
**Out:** Workout Start, prescribed duration/cardio/warmup without data, exercise/set editor or picker, inferred imagery, media Storage, delete/archive, Default My Program, new schema/RPC/RLS, release or production writes; broad W1/W3/W4 acceptance.

## Current truthful handoff
**Implementation owner:** This #528 child-branch GitHub connector session; does not write parent #527.
**Review owner:** Independent reviewer/Codex/manual, not implementation author sign-off.
**Implementation ownership state:** Active.
**Original verified source:** protected main `83e6fb813fc64b13b5bacc9863f67ab9ee9b8cbc`, PR #525 merged. PR #527 OPEN with independent implementation owner: `tnyx/issue-524-routine-popup-card@54758eaca923ed7da7e6544e54592e4a73ad5b56`, Flutter CI/attribution PASS; Codex quota limitation. Docs-only #523 OPEN and unrelated.
**Child branch:** `tnyx/issue-528-routine-detail-read-only` forked from exact #527 head `54758eaca923ed7da7e6544e54592e4a73ad5b56`. Open **stacked PR base = #527 branch**, NOT main; after parent merges reconcile base. No force-push or history rewrite.
**Local working tree:** User Windows checkout not accessible; GitHub API compares substitute for local git. No claim of local Flutter tests. No source changes to parent #527 branch.
**Planning dependencies:** [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81) Backlog blocked by TNYX-78/W1 and TNYX-80/W3; TNYX-267 Backlog blocked by TNYX-266/TNYX-81. #528 is scoped carve-out and does not lift these gates.
**Current implementation state:** Brief and child branch created, source work pending.
**Observed uncommitted files:** Remote branch equals approved parent SHA, no connector-local checkout.
**Relevant code:** Workout-owned `RoutineCompositionRepository` and `SupabaseRoutineCompositionRepository` have read-only, revision-bracketed, owner-filtered snapshot reads; `RoutineRepository.list(ProgramId)` validates metadata owner association. `ExerciseCatalogRepository.load()` resolves canonical `ex_*`; `UserExerciseRepository.list(includeArchived: true)` resolves user UUID; unresolved refs show explicitly unavailable. Existing `RoutineMetadataCard` in #527 is a Core `TioCard` with anchored Edit-only popup; decouple `onTap` from `onEdit` on child only.
**Validation:** Not yet run for #528. Before PR merge require focused tests, exact-head Flutter analyze/test, required attribution, review. Parent merge gate independent.
**Next exact action:** Implement feature read-only controller/page and app/feature navigation with focused tests; open stacked PR, stop before merge.

## Boundary and rejected alternatives
- Reject clicking a Routine card to open Rename (owner-reported bug), opening a fake empty preview or showing enabled Start Workout before session engine exists.
- Reject a second independent Routine/Exercise truth: use canonical IDs and existing owner-safe repositories, never clone catalog or user-created Exercise.
- Reject changing #527 implementation branch, which is under a different implementation owner.
- Data access checks selected Routine belongs to selected Program via metadata before reading composition; auth changes/errors fail closed and never retain stale data.
