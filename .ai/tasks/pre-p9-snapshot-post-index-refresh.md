# Pre-P9 — Post-index dynamic snapshot refresh

**Status:** In progress
**Primary owner:** repository documentation governance
**Affected platforms:** documentation / AI execution orientation only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner said `Go` after the #250 bookkeeping audit identified stale post-#426 snapshot wording.
**Approved product/UI/data-shape boundaries:** Refresh only the two dynamic current-state snapshots so they reflect the completed Product Onboarding task-index reconciliation and current governance checkpoint.
**Explicit non-changes:** No runtime/UI/routing/state changes; no Supabase/schema/RLS/migration changes; no canonical product/architecture doc changes; no #250 checkbox/bookkeeping edits; no P9 routing-map decision.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** ChatGPT
**Review owner:** manual exact-head review after implementation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@7a243122a58baa2cf1e03fa785669339e89940c5`
**Branch:** `tnyx/pre-p9-snapshot-post-index-refresh`
**HEAD SHA:** branch created from exact verified main
**Observed working-tree state:** Connector/API workflow; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable.
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** Snapshot refresh implemented and exact three-path scope validated.
**Relevant execution surface:** `.ai/CURRENT.md`, `.ai/IMPLEMENTATION_STATUS.md`
**Validation completed at SHA:** Audit baseline `7a243122a58baa2cf1e03fa785669339e89940c5`
**Validation remaining:** PR exact-head review and repository checks.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Refresh only the two snapshots, then validate exact scope.

## 1. Discovery

### User Outcome

Keep the dynamic AI execution snapshots truthful before #250 acceptance bookkeeping and P9 are evaluated.

### Success Criteria

- remove the obsolete claim that the Product Onboarding O1-as-NEXT index cleanup is still pending;
- record that PR #426 completed the task-index reconciliation and PR #427 archived its validated handoff;
- refresh the verification baseline to current main;
- preserve P9 as separately gated and Not started;
- do not duplicate volatile tracker/backlog state.

### Scope

- `.ai/CURRENT.md`
- `.ai/IMPLEMENTATION_STATUS.md`
- this focused task brief

### Non-Goals

- #250 checkbox changes;
- P9 decision;
- runtime/source changes;
- canonical docs or Supabase changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, task template, both dynamic snapshots.
- Tracker evidence: GitHub #250 P9 remains Not started; Linear TNYX-193 remains In Progress.
- Merge evidence: PR #426 merged as `6ca53860ddce4e6a6a919f4810dd8ee4d5176642`; PR #427 merged as current `main@7a243122a58baa2cf1e03fa785669339e89940c5`.
- Existing pattern: dynamic snapshots are orientation only and must be refreshed together.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Refresh both snapshots together | Approved | They form one dynamic current-state layer. | #250/P7 governance |
| Update #250 acceptance boxes in this slice | Rejected | Bookkeeping requires its own evidence-by-evidence reconciliation. | Slice discipline |
| Start P9 here | Rejected | P9 remains separately gated. | GitHub #250 |

## 4. Architecture Design

Documentation/execution orientation only. Runtime/source, canonical docs, and live trackers remain the higher-authority layers.

## 5. Implementation Plan

- [x] Refresh snapshot baselines to current main.
- [x] Replace obsolete Product Onboarding pending-cleanup wording with completed #426/#427 state.
- [x] Preserve P9 and tracker boundaries.
- [x] Validate exact three-path scope.

## 6. Quality Review

### Validation Run

```text
Repository API validation: 4 ahead / 0 behind from main; exactly 3 changed paths; both snapshots reference main@7a243122... and PRs #426/#427; obsolete pending-index-cleanup phrases absent; GitHub #250 P9 remains Not started; Linear TNYX-193 remains In Progress.
```

## 7. Final Handoff

### Changed Files

- `.ai/CURRENT.md`
- `.ai/IMPLEMENTATION_STATUS.md`
- `.ai/tasks/pre-p9-snapshot-post-index-refresh.md`

### Actual Behavior

No runtime behavior change.

### Known Limitations

Live tracker state remains volatile and must be re-queried before implementation.

### Final Status

`REVIEW`
