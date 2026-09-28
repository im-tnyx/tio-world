# GitHub #443 — Calendar router test determinism

**Status:** In progress
**Primary owner:** `apps/app` tests
**Affected platforms:** Flutter phone test suite

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said “Go follow agent.md” on 2026-09-28 after the separate month-boundary CI blocker and isolated-slice requirement were explained.
**Approved product/UI/data-shape boundaries:** Test-only stabilization of the two date-sensitive calendar/router widget tests.
**Explicit non-changes:** No production calendar logic, routing behavior, App Mode behavior, UI, persistence, API, Supabase, or schema change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Codex bot after PR creation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub API against `main@4db03ef82f7330dabfc11a11cf5439c5dc8dce81`
**Branch:** `tnyx/issue-443-calendar-router-test-determinism`
**HEAD SHA:** `78d7cfec260d0c0c980120650e3f30660ef8c36b` reviewed by Codex
**Observed working-tree state:** Not available through GitHub API execution
**Observed uncommitted/dirty files:** Not observable; no local dirty-state claim
**PR / tracker:** GitHub #443; Linear mirror unavailable because workspace issue limit is exceeded
**Current implementation state:** Test-only determinism fix implemented; Draft PR #444 open; Codex P2 handoff finding being addressed
**Relevant execution surface:** `apps/app/test/app/app_mode_router_test.dart`
**Validation completed at SHA:** `78d7cfec260d0c0c980120650e3f30660ef8c36b` — parent-to-head audit 2 ahead / 0 behind with exactly this task brief and `app_mode_router_test.dart`; Codex reviewed this head
**Validation remaining:** hosted Flutter CI completion and exact-head re-review after this handoff-only correction
**Current blocker:** None
**Open review finding IDs:** Codex P2 `discussion_r4117697186` — stale Active Handoff/checklist
**Next exact action:** Verify this handoff-only correction, reply to and resolve Codex P2, then request exact-head Codex re-review; wait for hosted Flutter CI before merge.

## 1. Discovery

### User Outcome

Restore reliable Flutter CI without widening PR #442 or changing production behavior.

### Success Criteria

- The two affected calendar/router tests do not depend on the wall-clock month boundary.
- Existing redirect, visible-month, Today-action and calendar behavior assertions remain meaningful.
- Production source remains untouched.
- Hosted Flutter CI passes.

### Scope

`apps/app/test/app/app_mode_router_test.dart` only, plus task/tracker handoff files.

### Non-Goals

Production date/calendar logic, router behavior, UI changes, C3f route extraction, persistence/data/backend changes.

## 2. Codebase Exploration

### Verified Evidence

- PR #442 Flutter CI: 378 passed / 2 failed.
- Both failures are in `app_mode_router_test.dart`, with expected September 2026 vs actual October 2026.
- The test blob SHA is identical on base `4db03ef...` and PR #442 head `d3644dc...`.
- PR #442 does not change this test file.
- The affected tests derive state from real local today and exercise weekly paging near a month boundary.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep fix test-only | Decided | No production regression evidence | apps/app tests |
| Do not patch PR #442 | Decided | Preserve C3f scope and ownership | repository governance |
| Preserve behavioral assertions | Decided | Fix determinism, not coverage | apps/app tests |

## 4. Architecture Design

### Chosen Approach

Remove the wall-clock month assumption from the affected widget-test assertions while preserving their behavioral contract.

### Ownership and Data Flow

Test fixture/assertion -> existing production calendar controller/router -> observed UI/state.

### Alternative Rejected

Changing production calendar logic or C3f routing code merely to make CI green.

### Failure and Accessibility States

Not applicable; no production behavior/UI changes.

## 5. Implementation Plan

- [x] Audit failing CI and source identity.
- [x] Create isolated GitHub tracker #443.
- [x] Apply smallest deterministic test fix.
- [x] Audit exact parent-to-head scope: 2 ahead / 0 behind; exactly 2 owned paths at `78d7cfec260d0c0c980120650e3f30660ef8c36b`.
- [x] Open Draft PR #444.
- [x] Receive Codex review on `78d7cfec260d0c0c980120650e3f30660ef8c36b`.
- [ ] Resolve Codex P2 after verifying this handoff correction.
- [ ] Wait for hosted Flutter CI and exact-head Codex re-review.

## 6. Quality Review

### Validation Run

```text
PR #442 hosted Flutter CI: analyze passed; Flutter tests 378 passed / 2 failed.
Root-cause audit: affected test file is byte-identical between base and PR head.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| I443-REV-01 | P2 | Open | Active Handoff/checklist remained at pre-implementation state after the test fix was committed. | `78d7cfec260d0c0c980120650e3f30660ef8c36b` | Refresh implementation state, checklist, changed files, and next action; resolve only after post-fix verification. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/issue-443-calendar-router-test-determinism.md`
- `apps/app/test/app/app_mode_router_test.dart`

### Actual Behavior

Production behavior is unchanged. Tests now assert the calendar label against the controller's actual `visibleMonth` contract instead of assuming Today's week always belongs to Today's calendar month.

### Known Limitations

Local Flutter/git execution is unavailable through the connector session; hosted CI is required.

### Final Status

`PARTIAL`
