# TNYX-192 — Linear issue and project status update cadence

**Status:** In progress
**Primary owner:** repository AI governance
**Affected platforms:** repository governance only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner explicitly requested this governance follow-up after TNYX-191 / PR #248 merged.
**Approved product/UI/data-shape boundaries:** Documentation/process guidance only.
**Explicit non-changes:** No runtime, UI, Supabase, schema, milestone structure, or product behavior changes.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main` at `77fe0f646bf0d34ec8fae0e943d050c33cdcb846`; PR #248 merged; no open PRs; no Linear issues in started state before this task.
**Branch:** `tnyx/tnyx-192-gov-define-linear-issue-and-project-status-update-cadence`
**HEAD SHA:** branch created from `77fe0f646bf0d34ec8fae0e943d050c33cdcb846`
**Observed working-tree state:** GitHub/API workflow; no local working tree available.
**Observed uncommitted/dirty files:** Not applicable.
**PR / tracker:** Linear TNYX-192; PR not opened yet.
**Current implementation state:** Governance wording ready to apply.
**Relevant execution surface:** `AGENTS.md`, `.ai/workflow.md`.
**Validation completed at SHA:** Not run yet.
**Validation remaining:** API scope/compare audit and whitespace/diff review.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Add the cadence rule to `AGENTS.md` and reinforce it in `.ai/workflow.md`.

## 1. Discovery

### User Outcome

Keep Linear task state current while avoiding noisy project-level status updates after every completed task.

### Success Criteria

- Issue status is reconciled on real task transitions.
- Project health/status updates are not emitted for every task completion.
- Project updates are published on a reasonable weekly cadence when useful, or sooner when material project-level progress, milestone, risk, blocker, or scope changes.
- Material risk/blocker changes are updated promptly rather than waiting for the weekly cadence.

### Scope

- `AGENTS.md`
- `.ai/workflow.md`
- this task brief

### Non-Goals

- No automation implementation.
- No Linear project/milestone restructuring.
- No runtime/product changes.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md` already defines Tracker Reconciliation but not project status cadence.
- `.ai/workflow.md` defines tracker roles and final handoff but not issue-vs-project update frequency.
- `.ai/tasks/README.md` requires compact task briefs for active tracked work.
- `.github/POST_MERGE_SYNC.md` is referenced by governance but absent on current `main`; this task does not repair that separate gap.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Issue status cadence | Decided | Update on actual task state transitions | Owner |
| Project status cadence | Decided | Weekly when useful, plus material-change updates; avoid per-task spam | Owner |
| Material risk/blocker timing | Decided | Update promptly, do not wait for weekly cadence | Owner |

## 4. Architecture Design

### Chosen Approach

Keep the canonical rule in root `AGENTS.md` under tracker governance and add one concise workflow reinforcement in `.ai/workflow.md` final handoff/tracker guidance.

### Alternative Rejected

README-only documentation was rejected because this is agent execution governance rather than repository/product orientation.

### Failure and Accessibility States

Not applicable for docs-only governance.

## 5. Implementation Plan

- [ ] Add canonical Linear tracking cadence rule to `AGENTS.md`.
- [ ] Reinforce task-vs-project update behavior in `.ai/workflow.md`.
- [ ] Audit exact branch diff against `main`.
- [ ] Open focused docs-only PR and reconcile Linear state.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No review finding yet | — | — |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending.

### Known Limitations

This defines agent/process guidance only; it does not create an automatic Linear status updater.

### Final Status

`REVIEW`
