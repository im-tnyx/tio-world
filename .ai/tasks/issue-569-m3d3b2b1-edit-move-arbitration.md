# #569 M3D3B2b1 — Routine Edit versus Move/Delete write arbitration

**Status:** Review handoff (Ready for Review, unmerged; owner explicitly requests NO MERGE)
**Primary owner:** Workout data adapters + apps/app composition root
**Affected platforms:** Flutter Android/iOS (behavior-preserving, no visible UI change)

## Owner Approval and Scope Boundary
**Trigger:** None — normal correctness implementation subtask within approved GitHub #569, reiterated owner's 2026-10-19 `Next work go with audit move routine`.
**Approval status:** Approved existing bounded capability; *no new independently scoped product feature or table/column shape.*
**Evidence:** GitHub #569 acceptance explicitly requires concurrent Edit/Delete/Create safety; Linear TNYX-81; previous #609 M3D3B2a merged.
**In scope:** Existing canonical Routine Edit Save (composition-only and atomic Name+composition Update) must share owner/Routine process-local Move/Delete reservation for the exact interval of its RPC/reconciliation. Existing shared guard fails closed when another operation in-flight or an unknown previous CAS remains viable. Fresh owner-verified bracket read of a later revision may retire only a superseded UNKNOWN; preserve one-use Move/Delete token invalidation. Add tests.
**Out of scope:** New Routine creation / Program-level pending Create coordination (M3D3B2b2 audit after this slice); Library/Program refresh (M3D3B3), 5-second real post-commit Undo, UI layout or copy, new SQL, Supabase grants, atomic Create+Move migration, release flag, iOS/watch changes, broader architecture.

## Active Handoff
**Planning owner:** GitHub #569 + Linear TNYX-81
**Implementation owner:** This single active feature slice
**Review owner:** Codex exact source-head review complete, 0 findings; manual review COMMENTED. Independent formal APPROVED not recorded.
**Ownership state:** Source implementation complete / review gate, unmerged
**Repository state last verified:** Protected remote `main@7801502a1d85670bc17b22d8a07a5aebd6f6b339`; merged #609; [post-merge Flutter CI #39202873606](https://github.com/im-tnyx/tio-world/actions/runs/39202873606) SUCCESS 5/5; no open PRs on starting audit. Local `G:\projects\Tio-World` unavailable to connector, so local status/worktree not verified.
**Branch:** `tnyx/issue-569-m3d3b2b1-edit-move-arbitration`.
**PR:** [#610](https://github.com/im-tnyx/tio-world/pull/610) **OPEN / Ready for Review / UNMERGED**. Owner explicitly said merge gate, NOT merge.
**Validation:** Source + tests and initial handoff exact HEAD `3497607a7e77e84f0486a606120d42e0a21545ff`: [Flutter CI #39204558404](https://github.com/im-tnyx/tio-world/actions/runs/39204558404) **5/5 SUCCESS** and [attribution #39204554521](https://github.com/im-tnyx/tio-world/actions/runs/39204554521) **2/2 SUCCESS**. Any later documentation-only HEAD requires separate exact-head check verification. Local Flutter execution not claimed.

## 1. Discovery
Safely serialize Edit and Move/Delete for the same owner/Routine without broadening client table privileges.

## 2. Codebase Exploration
- Runtime `RoutineEditorController.update()` calls one of `RoutineCompositionRepository.save` or `RoutineAggregateUpdateRepository.updateAggregate` via `SupabaseRoutineCompositionRepository`.
- Both paths use owner-bound RPC/CAS and read reconciliation; a timeout can resolve to `RoutineCompositionSaveOutcomeUnknown`.
- M3D3B2a provides `RoutineMoveDeleteAttemptGate` (per owner/Routine in-flight, unknown revision, dispatch generation) consumed by Move and Delete. App composition currently does not inject this gate into composition Edit.
- Editor source is guarded by live Auth/login-cycle in apps/app; Supabase adapter retains owner checks, authorizations still server-authoritative.
- Hosted Tio Supabase read-only verified 2026-10-19: `move_user_workout_routine` security definer, authenticated EXECUTE=false; `delete_user_workout_routine` authenticated EXECUTE=true; atomic Create+Move function absent. 64 applied migrations. No migrations/grants changed in this slice.

## 3. Clarification
Split M3D3B2b into B2b1 existing Routine Edit vs Move/Delete and B2b2 new Routine Create coordination because Create uses distinct program-keyed pending-command lifecycle and a different immutable new RoutineId. Do not prematurely add a Program-global gate.

## 4. Architecture Design
- Reuse same gate from existing app `routineMoveDeleteAttemptGateProvider`, inject into composition repo. Do not create a second gate or a second persisted data source.
- Reserve synchronously before composition Save/atomic Update RPC, release after definite completion/failure; mark UNKNOWN at frozen expected revision before releasing if reconciliation uncertain. Deny conflicting mutation without RPC dispatch.
- Owner-validated bracketed Edit reads may clear unknown only on a newer observed revision, never on same revision, absence, wrong-owner read or timeout.
- Existing Move/Delete inspect generations invalidate stale targets even when concurrent Edit dispatch is eventually denied/failed (safe reinspection).
- Auth revocation must not release a dispatched UNKNOWN for a later login cycle. Retain server CAS/ownership as ultimate authority.
- Avoid altering shared Core UI, composing scripts, server API, or app release-gated Move toggle.

## 5. Implementation Plan
- [x] Feature composition adapter optional injected coordinator for isolated tests; production fromClient composition consumes app singleton gate.
- [x] Both Edit write variants guarded; owner-read later-revision resolution, plus alternate metadata Rename aggregate path.
- [x] Five focused fake-gateway tests for in-flight/UNKNOWN/owner isolation/read revision; app provider injection established in source. Additional widget/provider regression remains a review consideration.
- [x] Source/test HEAD `3497607a` 7/7 required checks, 7 scoped paths/0 behind; Codex [summary](https://github.com/im-tnyx/tio-world/pull/610#issuecomment-6260487254) completed with no findings, 0 unresolved threads. Later documentation-only HEAD must be checked.
- [x] Stop at Ready-for-Review gate; owner requested explicitly NOT to merge.

## 6. Quality Review
**Validation:** Exact source/test HEAD `3497607a` [Flutter CI #39204558404](https://github.com/im-tnyx/tio-world/actions/runs/39204558404) 5/5 PASS + [attribution #39204554521](https://github.com/im-tnyx/tio-world/actions/runs/39204554521) 2/2 PASS. Prior source-only run #39204273039 was cancelled by a later docs commit after its analyzer/app-workout/core-wear shards passed; do not report that cancelled run as a pass. Codex completed no findings at 3497607a; [manual scoped review #5567361049](https://github.com/im-tnyx/tio-world/pull/610#pullrequestreview-5567361049) COMMENTED, no confirmed P1/P2; no formal GitHub APPROVED. Branch protection details 403 to connector, effective GitHub mergeability clean.
**Review findings:** Exact source/test-head Codex has zero findings and 0 unresolved threads; manual scoped review no confirmed P1/P2. No independent formal APPROVED claimed.

## 7. Final Handoff
**Actual behavior:** Existing shared same-owner Routine gate now guards composition Save, atomic Name+Sets Update and alternate metadata Rename in Ready-for-Review PR #610; source/test CI green. No UI or backend changes.
**Known limitations:** No Create vs Move arbitration yet; cross-device and DB CAS still authoritative; actual Move release OFF.
**Final status:** REVIEW — PR #610 open Ready for Review. Source/test HEAD green, Codex no findings; documentation-only handoff checks pending final verification. Separate formal approval/branch policy and explicit owner instruction still gate any future merge. User explicitly prohibited merge.
