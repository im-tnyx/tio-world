# #569 M3D2A — Dormant Move callback plumbing

**Status:** **Validated / archived 2026-10-20.** [PR #603](https://github.com/im-tnyx/tio-world/pull/603) squash-merged as `main@11d5324fd44ff1c690417bfacf3005b02a865032` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** In Review — [PR #603](https://github.com/im-tnyx/tio-world/pull/603) **Open / Ready for Review / unmerged**. Exact last verified HEAD `6a96d8ea718ea676524b72694cd4b7afdfcf307d` [Flutter CI #39134695940](https://github.com/im-tnyx/tio-world/actions/runs/39134695940) **5/5 PASS** plus attribution **2/2 PASS** (7/7). Earlier source/test `155a0feb` and first handoff `af6cc5f5` also 7/7 PASS. Final governance-only follow-up HEAD requires fresh checks; independent APPROVED and owner merge authorization pending.
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
**HEAD SHA:** last fully validated `6a96d8ea718ea676524b72694cd4b7afdfcf307d`; next task/index-only follow-up HEAD must pass its own checks.
**Observed working-tree state:** User previously verified local Windows main clean and synced; no local checkout inspection in this tool session. GitHub branch is connector-controlled.
**Observed uncommitted/dirty files:** Not observable locally.
**PR / tracker:** GitHub #569 Open / Linear TNYX-81 Backlog; [PR #603](https://github.com/im-tnyx/tio-world/pull/603) Ready for Review / unmerged. GitHub live state authoritative.
**Current implementation state:** Optional `onMoveRoutine` forwarded through Program Detail and Library->ProgramsSurface->_ProgramsList->InlineProgramRoutines; action still absent from production app shell. True callback requests local owner source list reload only, never a false success claim.
**Validation remaining:** Next documentation-only HEAD exact CI, independent GitHub APPROVED or applicable policy disposition, and separate explicit owner Go merge. Source/test HEAD `155a0feb` + handoff heads `af6cc5f5`/`6a96d8ea` all 7/7 PASS. No physical/device QA, shell activation or hosted grant.
**Current blocker:** Production app-shell coordinator, cross-mutation/refresh and hosted atomic RPC+authenticated grants remain unimplemented. No visible activation.
**Next exact action:** Verify follow-up docs-only HEAD Flutter/attribution checks, independently review any new inline findings, then hold for separate owner Go merge. Do not wire production Move.

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
- [x] First handoff-only HEAD `af6cc5f5` Flutter CI #39134225026 5/5 + attribution 2/2 SUCCESS.
- [x] Task/index HEAD `6a96d8ea` [Flutter CI #39134695940](https://github.com/im-tnyx/tio-world/actions/runs/39134695940) 5/5 + attribution 2/2 SUCCESS (7/7).
- [x] Two latest **non-blocking scope-observation threads** on opening source refresh and future Auth/coordination gates replied and resolved: 2/2, without changes to source.
- [ ] New documentation-only HEAD exact CI and independent GitHub approval/owner Go merge; production activation still separately gated.

## 6. Quality Review

Review scope: 8 changed paths (four Workout presentation, two Workout widget tests, task brief/index). No apps/app, core, Supabase or schema changes. Exact HEAD `6a96d8ea` Flutter 5/5 + attribution 2/2 PASS; older validated heads `155a0feb` and `af6cc5f5` likewise 7/7. Two non-blocking scope threads resolved. No confirmed open P1/P2 in dormant diff; independent GitHub APPROVED still zero. Codex automated re-review failed due usage limits before analysis, not security PASS. No local Windows checkout/device run.

## 7. Final Handoff

Move callbacks fully dormant: production shell supplies null. M3D2A requests a source reread only, not complete destination/new Program refresh; M3D2B/M3D3 separate. **In review, unmerged, no Move activation.**
