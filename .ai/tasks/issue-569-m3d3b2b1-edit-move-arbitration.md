# #569 M3D3B2b1 — Routine Edit versus Move/Delete write arbitration

**Status:** In progress
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
**Review owner:** GitHub CI/Codex after implementation; independent formal approval not claimed
**Ownership state:** Active
**Repository state last verified:** Protected remote `main@7801502a1d85670bc17b22d8a07a5aebd6f6b339`; merged #609; [post-merge Flutter CI #39202873606](https://github.com/im-tnyx/tio-world/actions/runs/39202873606) SUCCESS 5/5; no open PRs on starting audit. Local `G:\projects\Tio-World` unavailable to connector, so local status/worktree not verified.
**Branch:** `tnyx/issue-569-m3d3b2b1-edit-move-arbitration`.
**PR:** [Draft #610](https://github.com/im-tnyx/tio-world/pull/610) on active branch; merge not authorized.
**Validation:** Exact source HEAD `4a46ccb82ddeefc0f1af17584e28a7f01c98e0a8` [Flutter #39204273039](https://github.com/im-tnyx/tio-world/actions/runs/39204273039) still running at checkpoint (analyzer PASS); attribution two checks SUCCESS. Final full outcome not yet claimed. No local Flutter execution.

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
- [ ] Review exact-head CI, attribution, diff scope, Codex findings.
- [ ] Stop at review gate; separate owner `Go merge`.

## 6. Quality Review
**Validation:** Flutter CI #39204273039 analyzer PASS at checkpoint, other shards running; required attribution guard 2/2 SUCCESS.
**Review findings:** None asserted.

## 7. Final Handoff
**Actual behavior:** Source implementation complete in Draft PR #610 for Edit/Move/Delete same-Routine guard, including composition Save, aggregate Update and metadata Rename; CI final result pending.
**Known limitations:** No Create vs Move arbitration yet; cross-device and DB CAS still authoritative; actual Move release OFF.
**Final status:** PARTIAL — code/5 tests ready in Draft PR #610; exact-head full CI and review pending. No merge.
