# #569 M3B2B1 — Dormant Move to New Program selection UI

**Status:** In progress, review-only branch; no live Move activation.
**Primary owner:** Workout feature/presentation, single implementation owner for this bounded slice.
**Affected platforms:** Flutter phone, both Program Detail and expanded Library once later app shell wiring enables Move.

## Owner Approval and Scope Boundary
**Trigger:** Existing owner-approved Move Routine #569 first-row `+ New Program` and canonical Create Program name flow; user said "Go with follow agent.md" following #599 merge.
**Approval status:** Approved for this existing bounded feature.
**Approval evidence:** GitHub #569 owner 2026-10-17; Linear TNYX-81/TNYX-267; user current Go.
**Approved product/UI:** `+ New Program` first selectable row; source-only destination list shows that entry, no fake empty rows; reuse existing Create Program name editor without premature program INSERT; explicit `Create & Move` confirmation; app remains dormant until owner-safe atomic client capability and app-shell integration are independently delivered.
**Explicit non-changes:** No database migration/deployment, no `EXECUTE` grant, no standalone Routine truth, no new Create Program editor design or tokens, no #568 My Program identity, no Change Picture/Duplicate, no live app shell wiring, no merge.

## Active Handoff
**Planning owner:** Workout architecture.
**Implementation owner:** Workout feature.
**Review owner:** independent PR review pending.
**Implementation ownership state:** Active.
**Repository state last verified:** protected `main@2c5a2638fdb3eba7daef27a91eb09415fda9543b` after merged #599; zero open PRs at start; hosted Supabase 64 migrations, atomic Create+Move function not deployed; existing Move EXECUTE revoked.
**Branch:** `tnyx/issue-569-m3b2b-dormant-new-program-selector`.
**Observed working-tree state:** GitHub connector branch only; local Windows `git status` unavailable. No assumption of local worktree cleanliness.
**PR / tracker:** GitHub #569, Linear TNYX-81, TNYX-267, #568 separately gated.
**Current implementation state:** Before source edit; current Move modal only lists existing owner Programs and errors when none available.
**Validation completed at SHA:** None for this slice.
**Validation remaining:** Focused Flutter widget tests, analyzer, exact-head Flutter CI, independent security/UI review.
**Current blocker:** Actual protected Create+Move client gateway/app shell and Supabase release remain separate.
**Open review finding IDs:** None at start.
**Next exact action:** Introduce capability-gated dormant New Program path that reuses Create Program name input and makes no premature ProgramRepository.create write.

## 1. Discovery
User outcome: Saved Routine Move can choose either another existing owner Program or the first-row `+ New Program` and edit `Program N` name before explicit Create & Move.
Success: No empty destination artifact, no writes on cancel, same protected source Routine target, new name submitted only to future atomic callback; original existing Program Move path unchanged.
Non-goals: No production unlock or hosted mutation.

## 2. Codebase Exploration
`RoutineMoveFlow` from merged #598 provides existing target select and confirmation. `RoutineMoveDestinationController` revalidates persisted eligible Programs, one-use source. `ProgramsSurface._CreateProgramSheet` is canonical generated-name UI, presently performs `ProgramsController.create` standalone INSERT. `ProgramsController.suggestedName` enumerates Program N. Reuse that UI but use name-only mode for Move; never call standalone Program create in Move.

## 3. Clarification
Approved via #569: source-only Move list shows New Program only, no phantom My Program. The M3B2A SQL RPC is merged dormant, but has no deployed permissions. Keep `+ New Program` in the feature's dormant flow only when a real injectable atomic capability exists; do not wire it in apps/app for now.

## 4. Architecture Design
`RoutineMoveFlow` manages modal and draft name. Existing `ProgramsSurface` owns the name editor and a reusable name-only prompt. `RoutineMoveDestinationController` remains the owner read/revalidation for existing destinations. New Program destination sends a single frozen source/ProgramID/mutation tuple to an injected future server-atomic callback only after confirmation. Server remains sole mutation authority. No two-call ProgramRepository.create then Move.

## 5. Implementation Plan
- [ ] Reuse canonical program name modal without creating a Program before confirmation.
- [ ] Add optional dormant New Program row before real existing owner Program destinations.
- [ ] Confirm explicit Create & Move, freeze generated UUIDs and mutation ID for dispatched attempt, honor session checks.
- [ ] Focused no-write/cancel/source-only/real-destination widget tests.
- [ ] Exact-head CI and independent review; merge separately.

## 6. Quality Review
Validation not run. Do not claim it passed until actual CI logs verify.

## 7. Final Handoff
Actual behavior and validation to be filled after review. **Merge is not authorized by this handoff.**
