# W7C-3 — Workout in-progress Play start guard

**Status:** REVIEW
**Primary owner:** Owner (product copy) / Cursor (implementation)
**Affected platforms:** Flutter mobile (`apps/features/workout`, `apps/app` shell Play wiring)

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner chat request for exact conflict card copy and 3 actions when a workout is already running; also aligns with Codex P2 (do not start a new local draft while resuming a legacy session).
**Approved product/UI/data-shape boundaries:**
- When Play is pressed and a local draft and/or running legacy session already exists, show a popup card:
  - Title: `You have a workout in progress`
  - Message: `If you start a new workout, your old workout will be permanently deleted.`
  - Actions: `Resume workout in progress` | `Start new workout` | `Cancel`
- Resume must not create a separate new local workout.
- Start new permanently replaces the old local draft and running legacy session, then opens a fresh Log Workout.
**Explicit non-changes:** No redesign of Log Workout / Active Workout layout; no new recovery screens; Gym `Select` copy change remains a separate owner-approved micro-fix.

## Active Handoff

**Planning owner:** Cursor
**Implementation owner:** Cursor
**Review owner:** Not started
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** local dirty tree on `feat/w7c-3-active-workout-execution-ui`
**Branch:** `feat/w7c-3-active-workout-execution-ui`
**HEAD SHA:** uncommitted (post `a2522755`)
**PR / tracker:** [#740](https://github.com/im-tnyx/tio-world/pull/740) / TNYX-84
**Current implementation state:** Conflict card + resume create-guard implemented; awaiting commit/push
**Relevant execution surface:** Play FAB → shell → Active Workout
**Validation completed at SHA:** local uncommitted
**Validation remaining:** commit/push + exact-head CI
**Current blocker:** None
**Open review finding IDs:** Codex P2 addressed locally (resume no create)
**Next exact action:** Owner commit/push when ready

## 1. Discovery

### User Outcome

Play while a workout is already in progress never silently duplicates work; user chooses Resume, replace, or Cancel.

### Success Criteria

- In-progress Play shows the owner card with the three actions.
- Resume opens existing draft/session and does not create a new draft.
- Start new discards old draft/session then starts fresh Log Workout.
- Cancel leaves state unchanged.

### Scope

Play entry conflict UX + resume create-guard.

### Non-Goals

Routine/program start conflict surfaces; Isar store; Save RPC changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `shell_route.dart` Play push; `ActiveWorkoutDraftController.restoreOrStart` / `restoreExisting` / `discard`; `ActiveWorkoutPage` preview path; Codex open P2 on PR #740; tio-workspace routine conflict dialog pattern.
- Existing pattern to follow: compact `TioCard` dialog (`showTioConfirmationDialog` / Program Delete), feature-owned flow.
- Tests or validation already present: `active_workout_page_test.dart`, `workout_home_page_test.dart`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Exact card copy and 3 actions | Made | Owner-provided | Owner |
| Resume must not call `restoreOrStart` create path | Made | Codex P2 + owner | Cursor |

## 4. Architecture Design

### Chosen Approach

Feature-owned `showWorkoutInProgressDialog` + `runWorkoutPlayStart`; shell Play probes draft store/controller and running session, then routes with `preview=1` or `preview=1&resume=1`.

### Ownership and Data Flow

```text
Play FAB -> shell runWorkoutPlayStart -> (dialog?) -> go_router ActiveWorkoutPage
  resume: restoreExisting only
  start new: discard draft + discardSession -> restoreOrStart
```

## 5. Implementation Plan

- [x] Task brief
- [x] Dialog + Play start flow
- [x] ActiveWorkoutPage createDraftIfMissing
- [x] Shell Play wiring
- [x] Tests

## 6. Quality Review

### Validation Run

```text
flutter test test/presentation/workout_in_progress_dialog_test.dart → PASS (2)
flutter test test/presentation/workout_play_start_flow_test.dart → PASS (4)
flutter test ... --name discardForReplacement → PASS
flutter test ... --name "Play resume with legacy" → PASS
flutter analyze on touched workout/shell files → pending in this update
```

## 7. Final Handoff

### Final Status

`REVIEW`
