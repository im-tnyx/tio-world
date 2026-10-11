# GitHub #528 — Routine card opens owner-scoped read-only Routine Detail

**Status:** In progress; implementation on stacked child PR #530, validation/review pending  
**Primary owner:** `apps/features/workout` (Routine presentation/read controller), `apps/app` only for provider/navigation composition  
**Affected platforms:** Flutter phone; no watch, Supabase schema or backend changes

## Owner Approval and scope boundary
**Trigger:** Owner-approved bounded UI slice.
**Approval:** User 2026-10-11 `Go` directly following recommendation: existing GitHub #528 owner-scoped read-only Routine Detail, before full W4B builder; first preserve active #527 anchored popup ownership.
**In:** Program Detail and expanded Library Routine-card *primary tap* → selected Routine read-only detail, using exactly owning ProgramId and RoutineId. Separate Routine overflow **Edit** → existing Rename; no primary Rename. Revision-validated composition read, canonical catalog/user ExerciseRef lookup, ordered entry/set values, counts, missing/empty/failure/permission/retry/back, focused tests. Preserve popup geometry/behavior from owner-approved #527.
**Out:** Workout Start, prescribed duration/cardio/warmup without data, exercise/set editor or picker, inferred imagery, media Storage, delete/archive, Default My Program, new schema/RPC/RLS, release or production writes; broad W1/W3/W4 acceptance.

## Current truthful handoff
**Previous Implementation owner:** Previous #528 child-branch GitHub connector session (paused with handoff pending, last source head `7a38daf29148e66320a6ceea241f3bba525cd349`).
**Receiving Implementation owner:** Current GitHub-connected session, 2026-10-12 (review findings repair inside the existing #528 approved scope only).
**Review owner:** Prior independent read-only PR review #5484665302; receiving implementation owner is not its own independent reviewer.
**Implementation ownership state:** Takeover recorded after reconstructing unchanged PR head and three unresolved review threads; no evidence of concurrent branch implementation in current GitHub history. Owner's Windows working tree unavailable, so local `git status`/Flutter execution cannot be claimed. Stop on any conflicting source movement.
**Open finding continuity:** P1 auth/session identity change while Detail is ready or loading (thread `PRRT_kwDOTOXwB86rQ1y9`, Open); P2 unconditional catalog load on empty/custom-only composition (thread `PRRT_kwDOTOXwB86rQ1zD`, Open); P2 eager rendering of large Exercise/Set composition (thread `PRRT_kwDOTOXwB86rQ1zH`, Open). All findings observed at `7a38daf2`, not resolved. Parent #527 still open; child CI not available until main-target reconciliation.
**Original verified source:** protected main `83e6fb813fc64b13b5bacc9863f67ab9ee9b8cbc`, PR #525 merged. PR #527 OPEN with independent implementation owner: `tnyx/issue-524-routine-popup-card@54758eaca923ed7da7e6544e54592e4a73ad5b56`, Flutter CI/attribution PASS; Codex quota limitation. Docs-only #523 OPEN and unrelated.
**Child branch:** `tnyx/issue-528-routine-detail-read-only` forked from exact #527 head `54758eaca923ed7da7e6544e54592e4a73ad5b56`. Open **stacked PR base = #527 branch**, NOT main; after parent merges reconcile base. No force-push or history rewrite.
**Local working tree:** User Windows checkout not accessible; GitHub API compares substitute for local git. No claim of local Flutter tests. No source changes to parent #527 branch.
**Planning dependencies:** [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81) Backlog blocked by TNYX-78/W1 and TNYX-80/W3; TNYX-267 Backlog blocked by TNYX-266/TNYX-81. #528 is scoped carve-out and does not lift these gates.
**Current implementation state:** Owner-scoped RoutineDetailController/Page, canonical Exercise resolution, existing app composition provider, Library/Program Detail routing and popup Edit separation implemented on child branch. Regression tests authored for owner association, repeated/archived/missing Exercise refs, error/empty/retry, Program/Library navigation and distinct popup Edit; **not executed locally**.
**Observed uncommitted files:** Remote branch equals approved parent SHA, no connector-local checkout.
**Relevant code:** Workout-owned `RoutineCompositionRepository` and `SupabaseRoutineCompositionRepository` have read-only, revision-bracketed, owner-filtered snapshot reads; `RoutineRepository.list(ProgramId)` validates metadata owner association. `ExerciseCatalogRepository.load()` resolves canonical `ex_*`; `UserExerciseRepository.list(includeArchived: true)` resolves user UUID; unresolved refs show explicitly unavailable. Existing `RoutineMetadataCard` in #527 is a Core `TioCard` with anchored Edit-only popup; decouple `onTap` from `onEdit` on child only.
**Validation:** No Flutter/Dart executable in connected session; no local tests run. GitHub PR #530 targets `tnyx/issue-524-routine-popup-card`; current repository `flutter-ci.yml` uses `pull_request.branches: [main]`, likewise required attribution workflow. Therefore the stacked PR has **no CI checks**, not a PASS; after PR #527 merges, safely retarget/reconcile #530 to fresh main, then run exact-head checks/review. Codex bot reported code review usage quota on PR #530, not an approval. No direct repository CI policy changes were authorized.
**Next exact action:** Secure independent review of current source and inspect gaps; wait for separately authorized PR #527 merge/reconciliation. Retarget #530 onto fresh main (if parent commits are contained), run exact-head Flutter/attribution checks, repair scoped findings; STOP before #530 merge unless explicitly approved.

## Boundary and rejected alternatives
- Reject clicking a Routine card to open Rename (owner-reported bug), opening a fake empty preview or showing enabled Start Workout before session engine exists.
- Reject a second independent Routine/Exercise truth: use canonical IDs and existing owner-safe repositories, never clone catalog or user-created Exercise.
- Reject changing #527 implementation branch, which is under a different implementation owner.
- Data access checks selected Routine belongs to selected Program via metadata before reading composition; auth changes/errors fail closed and never retain stale data.
