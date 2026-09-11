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
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main` at `77fe0f646bf0d34ec8fae0e943d050c33cdcb846`; PR #248 merged; no open PRs and no Linear issues in started state before TNYX-192 began.
**Branch:** `tnyx/tnyx-192-gov-define-linear-issue-and-project-status-update-cadence`
**HEAD SHA:** governance implementation reviewed at `3fade49b3e399493272cc09d0297190ef3c400ef`; this task-handoff update moves HEAD afterward.
**Observed working-tree state:** GitHub/API workflow; no local working tree available.
**Observed uncommitted/dirty files:** Not applicable.
**PR / tracker:** Linear TNYX-192; GitHub PR #249.
**Current implementation state:** Governance wording implemented; exact PR patch reviewed; ready for review after final branch/PR reconciliation.
**Relevant execution surface:** `AGENTS.md`, `.ai/workflow.md`, this task brief.
**Validation completed at SHA:** `3fade49b3e399493272cc09d0297190ef3c400ef` API compare + complete PR patch review.
**Validation remaining:** Final API compare after this handoff-only update and PR metadata reconciliation.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Re-run exact branch compare, update PR evidence, move Linear TNYX-192 to `In Review`, and await owner merge authorization.

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

- Root `AGENTS.md` already defined Tracker Reconciliation but not project status cadence.
- `.ai/workflow.md` defined tracker roles and final handoff but not issue-vs-project update frequency.
- `.ai/tasks/README.md` requires compact task briefs for active tracked work.
- `docs/POST_MERGE_SYNC.md` exists on `main` and is linked from `.ai/README.md` / `docs/README.md`.
- Root `AGENTS.md` contained a stale `.github/POST_MERGE_SYNC.md` path; because the same governance file was already in scope, the reference was corrected to `docs/POST_MERGE_SYNC.md` in this slice.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Issue status cadence | Decided | Update on actual task state transitions | Owner |
| Project status cadence | Decided | Weekly when useful, plus material-change updates; avoid per-task spam | Owner |
| Material risk/blocker timing | Decided | Update promptly, do not wait for weekly cadence | Owner |
| Post-merge guide path | Decided | Point root governance at the existing `docs/POST_MERGE_SYNC.md` | Repository evidence + Owner correction |

## 4. Architecture Design

### Chosen Approach

Keep the canonical rule in root `AGENTS.md` under tracker governance and add concise reinforcement in `.ai/workflow.md` final handoff/tracker guidance. Correct the stale post-merge path in the already-touched canonical agent file.

### Alternative Rejected

README-only documentation was rejected because this is agent execution governance rather than repository/product orientation.

### Failure and Accessibility States

Not applicable for docs-only governance.

## 5. Implementation Plan

- [x] Add canonical Linear tracking cadence rule to `AGENTS.md`.
- [x] Reinforce task-vs-project update behavior in `.ai/workflow.md`.
- [x] Correct stale post-merge guide path in `AGENTS.md`.
- [x] Audit exact branch diff against `main`.
- [x] Open focused docs-only PR.
- [ ] Reconcile Linear to `In Review` after final exact-head audit.

## 6. Quality Review

### Validation Run

```text
GitHub/API compare at implementation head 3fade49b3e399493272cc09d0297190ef3c400ef:
- merge base == parent main 77fe0f646bf0d34ec8fae0e943d050c33cdcb846
- ahead / behind: 4 / 0
- changed files: exactly 3 intended governance/task files

Complete PR #249 patch review:
- AGENTS.md cadence wording is scoped and consistent with Tracker Reconciliation
- .ai/workflow.md reinforces the same task-vs-project distinction
- stale post-merge path corrected to docs/POST_MERGE_SYNC.md
- no runtime/product/UI/Supabase changes
- no whitespace or unrelated-diff issue observed in the returned patch
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| GOV-1 | P3 | Resolved | Task brief initially repeated the stale assumption that `POST_MERGE_SYNC.md` was absent | `3fade49b` review | Owner pointed out the docs path; live repo verified `docs/POST_MERGE_SYNC.md`, task brief corrected |

## 7. Final Handoff

### Changed Files

- `AGENTS.md`
- `.ai/workflow.md`
- `.ai/tasks/tnyx-192-linear-status-update-cadence.md`

### Actual Behavior

Agents now have a canonical distinction between task-level Linear state transitions and project-level health/status summaries. Project updates are not emitted for every completed task; weekly summaries are used when useful, with immediate updates for material risks/blockers or other project-level changes. Root agent governance also points to the existing `docs/POST_MERGE_SYNC.md` guide.

### Known Limitations

This defines agent/process guidance only; it does not create an automatic Linear status updater.

### Final Status

`REVIEW`
