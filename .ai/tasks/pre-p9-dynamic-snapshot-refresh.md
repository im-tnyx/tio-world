# Pre-P9 — Dynamic current-state snapshot refresh

**Status:** In progress
**Primary owner:** repository AI governance
**Affected platforms:** Documentation / execution orientation only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** User authorized the next pre-P9 governance slice after PR #423 merge.
**Approved product/UI/data-shape boundaries:** Refresh `.ai/CURRENT.md` and `.ai/IMPLEMENTATION_STATUS.md` against the merged repository/tracker baseline.
**Explicit non-changes:** No runtime, UI, Supabase/schema/RLS/migration, canonical product/architecture docs, P9 decision, or unrelated active-task lifecycle cleanup.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** current pre-P9 snapshot-refresh slice
**Review owner:** pending exact-head review
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** `main@0a534984793714ad46e23f40b366f7ca8c82c2f3`
**Branch:** `tnyx/pre-p9-dynamic-snapshot-refresh`
**HEAD SHA:** `1feaece28812add716dcef49e328974b85d7a09e` before final handoff-evidence commit
**Observed working-tree state:** Connector/API workflow; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable / not observed.
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** Fresh audit complete; snapshot reconstruction in progress.
**Relevant execution surface:** `.ai/CURRENT.md`, `.ai/IMPLEMENTATION_STATUS.md`
**Validation completed at SHA:** `1feaece28812add716dcef49e328974b85d7a09e` — 3 paths, 3 ahead / 0 behind, baseline matches current main; stale `P7 current` and `no open PRs` claims absent.
**Validation remaining:** PR exact-head review and required CI.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Reconstruct both dynamic snapshots together without turning them into a volatile backlog copy.

## 1. Discovery

### User Outcome

Restore truthful current-state orientation before deciding P9.

### Success Criteria

- Both snapshots use the current merged baseline.
- P7 is recorded completed, not current.
- P9 remains separately gated / not started.
- The completed Product Onboarding handoff cleanup is reflected.
- No false “no open PRs” claim remains.
- Volatile open-work context is described as live-query-required rather than copied as a pseudo backlog.
- Known remaining `.ai/tasks/README.md` Product Onboarding execution-order contradiction is explicitly identified as a separate follow-up.

### Scope

Two dynamic snapshots plus this focused task handoff.

### Non-Goals

No P9 decision/routing map; no tracker acceptance rewrite; no unrelated task cleanup; no product/runtime change.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/README.md`, `.ai/workflow.md`, both snapshots, `.ai/tasks/README.md`, GitHub #250, Linear TNYX-193, live open-PR query.
- Existing pattern to follow: P7 reconstructed both snapshots together and gave them Dynamic Current-State Snapshot truth boundaries.
- Current baseline: `main@0a534984793714ad46e23f40b366f7ca8c82c2f3`.
- GitHub #250: P7 Completed; P9 Not started.
- Linear TNYX-193: In Progress.
- Fresh GitHub query returned 24 open PR search results at audit time; therefore snapshots must not claim there are no open PRs.
- PR #423 cleanup is merged; stale canonical onboarding execution handoff is archived as Superseded/Historical.
- Remaining drift: `.ai/tasks/README.md` still contains an old Product Onboarding execution-order block with O1 marked NEXT; separate lifecycle/index cleanup required.

## 3. Clarification

No product or architecture decision is required. This is execution-orientation reconciliation only.

## 4. Architecture Design

Keep the snapshots high-level and authority-aware. Avoid enumerating a volatile full PR/backlog set; direct agents to live trackers for current execution.

## 5. Implementation Plan

- [x] Refresh `.ai/CURRENT.md`.
- [x] Refresh `.ai/IMPLEMENTATION_STATUS.md`.
- [x] Validate exact scope and stale claims.
- [ ] Review exact head and CI before merge authorization.

## 6. Quality Review

### Validation Run

Connector/API validation at `1feaece28812add716dcef49e328974b85d7a09e`: branch is 3 commits ahead / 0 behind current `main@0a534984793714ad46e23f40b366f7ca8c82c2f3`; exact changed paths are the two snapshots plus this task brief. Both snapshots carry the current baseline. Old `P7 current` and `no open pull requests` assertions are absent. Historical references are explicitly labelled retired/superseded.

## 7. Final Handoff

### Changed Files

`.ai/CURRENT.md`, `.ai/IMPLEMENTATION_STATUS.md`, `.ai/tasks/pre-p9-dynamic-snapshot-refresh.md`.

### Actual Behavior

Documentation/orientation only.

### Known Limitations

The stale Product Onboarding execution-order block in `.ai/tasks/README.md` is deliberately outside this slice.

### Final Status

`REVIEW`
