# GitHub #447 — C3f/C3g post-merge handoff reconciliation

**Status:** In progress
**Primary owner:** repository AI governance
**Affected platforms:** Documentation/governance only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner authorized continuing the audited post-merge reconciliation with “Go” on 2026-09-28.
**Approved product/UI/data-shape boundaries:** No product/runtime change; reconcile already-merged execution records only.
**Explicit non-changes:** No `apps/**`, UI, route behavior, persistence, API, Supabase, schema, or new router extraction.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Codex after PR creation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@d82609e25388178763c6e3e74962725c83105702`
**Branch:** `tnyx/issue-447-c3fg-handoff-archive`
**HEAD SHA:** `2961d14005b38edc2c6d029a2cd533055c4f8e54` — Codex-reviewed head before this task-brief-only correction
**Observed working-tree state:** Not available through GitHub API execution
**Observed uncommitted/dirty files:** Not observable; no local dirty-state claim
**PR / tracker:** GitHub #447 / parents #357 and #260 / Linear TNYX-201
**Current implementation state:** C3f/C3g briefs archived and active/archive indexes reconciled; no runtime source changed.
**Relevant execution surface:** `.ai/tasks/**`, `.ai/archive/**`, tracker comments
**Validation completed at SHA:** `b03869d1f15ad7d5b79db28b2757017f4630a7bc` — pre-handoff API scope audit against `main@d82609e...`: 7 ahead / 0 behind; exactly 7 `.ai/**` paths, no runtime paths. Codex reviewed `dcdbaba219b5a75bf269ea81f9146ee470280baa` and raised P2 C3FG-REV-01 for the stale HEAD field; no runtime/source finding.
**Validation remaining:** Exact branch scope audit, hosted checks if triggered, Codex exact-head review.
**Current blocker:** None.
**Open review finding IDs:** C3FG-REV-04 — open-PR checklist state; C3FG-REV-05 — discovery baseline labeling; C3FG-REV-06 — review-history wording. C3FG-REV-01 is resolved; C3FG-REV-02/C3FG-REV-03 were fixed before the `2961d140...` review, which raised these three new consistency findings.
**Next exact action:** Revalidate the current correction head with Codex, resolve C3FG-REV-02/C3FG-REV-03 after verification, then re-audit merge readiness. PR #448 is already open and Ready for Review.

## 1. Discovery

### User Outcome

Clear stale post-merge execution state before any next router source slice.

### Success Criteria

- C3f and C3g are represented as validated merged outcomes, not active work.
- Active task index no longer advertises completed C3f/C3g work.
- Archive index records both outcomes with exact merge evidence.
- Parent GitHub/Linear trackers record completion without prematurely closing the broader router work.

### Scope

C3f/C3g task/index/archive governance plus tracker reconciliation.

### Non-Goals

Any router/source implementation or broader completion decision for #260/#357/TNYX-201.

## 2. Codebase Exploration

### Verified Evidence

Current evidence:
- C3f PR #442 merged as `f3646625fd9286b1f7b783f88afd25d36d86a8ea`.
- C3g PR #446 merged as `d82609e25388178763c6e3e74962725c83105702`.
- C3f/C3g briefs are now archived and the stale C3f active-task index row is removed on this branch.
- Archive contract requires Validated/Superseded status before moving; both replacement archive records use `Validated` with merge/review evidence.

Pre-reconciliation baseline observed on `main@d82609e...`:
- Active task index listed C3f In progress.
- C3f brief described an open Draft review state and used invalid ownership state `Review`.
- C3g brief described post-doc validation/merge as pending.

## 3. Clarification

No product decision required; runtime truth and archive governance determine the correction.

## 4. Architecture Design

Docs/governance-only normalization. Preserve canonical runtime/docs; do not create a second source of truth.

## 5. Implementation Plan

- [x] Rewrite C3f final handoff to validated merged truth and archive it.
- [x] Rewrite C3g final handoff to validated merged truth and archive it.
- [x] Remove stale active-task rows and add archive index rows.
- [x] Audit exact changed paths.
- [x] Open PR and request Codex exact-head review.
- [ ] After merge, reconcile #260/#357/TNYX-201 and audit remaining router work.

## 6. Quality Review

### Validation Run

GitHub API compare at `b03869d1...`: 7 ahead / 0 behind, exactly 7 `.ai/**` governance paths and no `apps/**` runtime path. Connector-only session cannot claim local `git diff --check`.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| C3FG-REV-01 | P2 | Resolved | Active Handoff HEAD field lagged the reviewed head. | `dcdbaba219b5a75bf269ea81f9146ee470280baa` | Fixed in `3d88a932...`; the finding did not recur, while the later Ready-triggered review on that same head raised C3FG-REV-02/C3FG-REV-03. |
| C3FG-REV-02 | P2 | Resolved | C3f archive overstated lifecycle evidence instead of recording the post-merge governance race explicitly. | `3d88a932dabc6437f461ec87507efa38a43cf428` | Archive now records merged-head CI, clean Codex review, late post-merge governance P2, resolved thread, and later clean merge-commit Codex review; fixed evidence was reviewed at `2961d140...`; that review raised separate consistency findings C3FG-REV-04/05/06. |
| C3FG-REV-03 | P2 | Resolved | Active Handoff next action still said to open the already-open PR. | `3d88a932dabc6437f461ec87507efa38a43cf428` | Next action now points to exact-head revalidation/finding resolution and merge-readiness audit; reviewed at `2961d140...`, where this finding did not recur. |
| C3FG-REV-04 | P2 | Open | Implementation checklist left the already-open PR step pending. | `2961d14005b38edc2c6d029a2cd533055c4f8e54` | Checklist corrected to completed; exact-head revalidation pending. |
| C3FG-REV-05 | P2 | Open | Discovery baseline facts were worded as current repository state after reconciliation. | `2961d14005b38edc2c6d029a2cd533055c4f8e54` | Evidence split into current state and pre-reconciliation baseline; exact-head revalidation pending. |
| C3FG-REV-06 | P2 | Open | C3FG-REV-01 evidence incorrectly called the `3d88...` review clean despite later findings on that SHA. | `2961d14005b38edc2c6d029a2cd533055c4f8e54` | Evidence now states only that REV-01 did not recur and records the later findings separately; exact-head revalidation pending. |

## 7. Final Handoff

Pending.

### Final Status

`REVIEW`
