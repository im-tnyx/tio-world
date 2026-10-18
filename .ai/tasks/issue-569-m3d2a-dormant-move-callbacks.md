# #569 M3D2A — Dormant Move callback plumbing

**Status:** In Review — [Draft PR #603](https://github.com/im-tnyx/tio-world/pull/603) Open/unmerged. Source+tests HEAD `155a0febf498667cf451f37824dc04e0acbff45f`: [Flutter CI #39133824837](https://github.com/im-tnyx/tio-world/actions/runs/39133824837) 5/5 PASS + attribution 2/2 PASS = **7/7 SUCCESS**. Subsequent handoff-only HEAD needs separate CI.
**Primary owner:** Workout feature presentation (`apps/features/workout`)
**Affected platforms:** Flutter phone shared Routine cards in Program Detail and expanded Library

## Owner Approval and Scope Boundary

**Trigger:** None — normal implementation slice inside approved Move Routine #569.
**Approval status:** Approved within previously reviewed Move UI contract; latest owner instruction "move routine work ko start karne ke liye go".
**Approval evidence:** GitHub #569, Linear TNYX-81, ADR-0015, merged #598/#600/#601/#602.
**Approved product/UI/data-shape boundaries:** Add optional, owner-injected `onMoveRoutine` callback forwarding to existing `RoutineMetadataCard.onMove`; preserve same Core bottom sheet. Read-only/none capability stays hidden.
**Explicit non-changes:** No app shell `onMove` connection, new backend/RPC/grants, new UI geometry, new default Program, new mutation coordination, or production release.

## Active Handoff

**Planning owner:** Workout architecture
**Implementation owner:** Feature presentation (this branch only)
**Review owner:** Independent review pending
**Implementation ownership state:** Active
**Ownership transition:** M3D1 app composition merged PR #602 -> M3D2A Workout feature presentation
**Repository state last verified:** protected `main@bbe255c071e064b1aab6d68e836397b0becc4352` (post-merge CI #39132061631 success 5/5); 0 open PRs
**Branch:** `tnyx/issue-569-m3d2a-dormant-move-callbacks`
**HEAD SHA:** verified source/test HEAD `155a0feb`; update this documentation-only new HEAD after commit.
**Observed working-tree state:** User previously verified local Windows main clean and synced; no local checkout inspection in this tool session. GitHub branch is connector-controlled.
**Observed uncommitted/dirty files:** Not observable locally.
**PR / tracker:** GitHub #569 / Linear TNYX-81; [PR #603](https://github.com/im-tnyx/tio-world/pull/603) Draft
**Current implementation state:** Optional `onMoveRoutine` forwarded through Program Detail and Library->ProgramsSurface->_ProgramsList->InlineProgramRoutines; action still absent from production app shell. True callback requests local owner source list reload only, never a false success claim.
**Validation remaining:** Documentation-only latest HEAD CI and independent review. Source/test exact HEAD `155a0feb` CI 7/7 PASS, including both Workout Move widget suites. No live integration/device QA. Cross-Program/new-Program reconciliation and global Create/Edit/Delete locking are separate M3D3 gates.
**Current blocker:** Production app-shell coordinator, cross-mutation/refresh and hosted atomic RPC+authenticated grants remain unimplemented. No visible activation.
**Next exact action:** Add purely optional presentation callbacks, scoped guards and tests; leave app shell unchanged.

## 1. Discovery

Current `RoutineMetadataCard` shows Move only for non-null `onMove`. Existing Program Detail and Library inject Edit/Delete but do not forward Move; `RoutineMoveFlow` and authenticated Move repository are merged/dormant.

## 2. Codebase Exploration

Read root and feature AGENTS, Core theme README and routine action sheet, ADR-0015, canonical Routine screen, GitHub #569, Linear TNYX-81, provider and presentation source. Live read-only Supabase: 64 migrations, new atomic RPC absent, authenticated Move EXECUTE false. No app-shell callback is passed. Tests already exercise Delete and Edit on both surfaces.

## 3. Clarification

Preserve `Future<bool>` return as an owner-guarded *refresh request*, not a Move success claim. Actual cross-Program and newly-created Program list reconciliation is a later M3D3 requirement; this PR must remain dormant and cannot claim full-refresh readiness.

## 4. Architecture Design

Optional path: `ProgramDetailPage.onMoveRoutine -> RoutineMetadataCard.onMove`; `LibraryPage.onMoveRoutine -> ProgramsSurface.library -> _ProgramsList -> InlineProgramRoutines -> RoutineMetadataCard.onMove`. Both surfaces check loaded routine membership and lack of unconfirmed Create. No second action sheet, repository, RPC, or auth authority in presentation.

## 5. Implementation Plan

- [x] Add optional callbacks, source-membership guards and request-to-refresh behavior.
- [x] Add widget regressions: Program Detail Move-only/source reload/cancel and Library Move-only/source reload/no callback/pending Create suppression. Exact source/test CI 7/7 PASS.
- [x] Verify source/test `155a0feb` Flutter CI #39133824837 + attribution = 7/7 PASS.
- [ ] New handoff-only HEAD CI, independent review, explicit owner Go merge; app-shell activation separately gated.

## 6. Quality Review

Review scope: 8 changed paths (four Workout presentation, two Workout widget tests, task brief/index). No apps/app, core, Supabase or schema changes. Source/test exact HEAD `155a0feb` Flutter 5/5 PASS, attribution 2/2 PASS. No local Windows checkout/device run, no independent security approval.

## 7. Final Handoff

Move callbacks fully dormant: production shell supplies null. M3D2A requests a source reread only, not complete destination/new Program refresh; M3D2B/M3D3 separate. **In review, unmerged, no Move activation.**
