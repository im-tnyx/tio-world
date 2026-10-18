# #569 M3D2A — Dormant Move callback plumbing

**Status:** In progress — isolated feature presentation slice
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
**HEAD SHA:** base `bbe255c0` — update after work
**Observed working-tree state:** User previously verified local Windows main clean and synced; no local checkout inspection in this tool session. GitHub branch is connector-controlled.
**Observed uncommitted/dirty files:** Not observable locally.
**PR / tracker:** GitHub #569 / Linear TNYX-81; new PR pending
**Current implementation state:** Move card option already supported, but Program Detail and Library callback chain omit it.
**Validation remaining:** Focused widget tests for both surfaces, no-callback hidden, confirmed/uncertain refresh, stale program/id and duplicate taps; exact-head Flutter CI and review.
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

- [ ] Add optional callbacks, source-membership guards and request-to-refresh behavior.
- [ ] Add focused widget regressions for both surfaces, suppressed menu when no capability, and cancellation/no false success.
- [ ] Exact-head Flutter CI, manual/independent review, separate owner Go merge; app-shell activation separately gated.

## 6. Quality Review

Not executed for this branch yet. No local device test claimed.

## 7. Final Handoff

Pending implementation/CI. Do not merge, grant or activate Move through this task.
