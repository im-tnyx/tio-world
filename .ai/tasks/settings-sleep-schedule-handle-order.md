# Sleep Schedule Handle Ordering (#188)

**Status:** In progress
**Primary owner:** `apps/features/settings`
**Affected platforms:** Flutter phone app (Android + iOS)

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner explicitly requested implementation of GitHub #188 and froze clamp/stop behavior, linear 20:00 -> next 20:00 ordering, one 15-minute interaction gap when supported by current UI evidence, and no identity swapping.
**Approved product/UI/data-shape boundaries:** Prevent Bedtime and Wake Time timeline handles from crossing through drag, accessibility actions, and the precise time picker; preserve the existing timeline rendering and persistence contract.
**Explicit non-changes:** No #183 Phase-2B, #24, TNYX-144, or TNYX-141 work. No schema, Supabase, repository, canonical Wellness persistence, route, label, color, size, geometry, Save Schedule, Clear Schedule, or sleep-duration derivation change.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Not assigned
**Implementation ownership state:** Complete
**Ownership transition:** Prior Claude session -> Codex
**Repository state last verified:** 2026-09-01; fresh `git fetch --prune`; `HEAD == main == origin/main`
**Branch:** `codex/sleep-schedule-handle-order`
**HEAD SHA:** `660ad1b64e5ec3a9250332f43a14614d88e8f0dc`
**Observed working-tree state:** Dirty only for the approved implementation slice before this task brief was created.
**Observed uncommitted/dirty files:** `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_page.dart`
**PR / tracker:** GitHub #188 OPEN; no open PR; PR #187 merged as Phase-2A at current main.
**Current implementation state:** Shared linear-position constraint is complete for drag, accessibility, semantics previews, and precise picker; focused regression coverage is complete and locally green.
**Relevant execution surface:** Settings -> Health & Goals -> Daily Wellness -> Sleep Schedule
**Validation completed at SHA:** Uncommitted worktree based on `660ad1b64e5ec3a9250332f43a14614d88e8f0dc`: focused Dart format PASS; Settings `flutter analyze` PASS; focused ordering tests 5/5 PASS; focused boundary-haptic test PASS; Daily Wellness test file 69/69 PASS; Settings package suite 183/183 PASS; `git diff --check` PASS.
**Validation remaining:** Commit/push scope audit, exact pushed-head CI, owner physical-device acceptance.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Commit the three owned files, push, open a Draft PR, and wait for exact-head CI green without merging.

## Global UI / Design-System Guardrail

Read and applied `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. This slice changes interaction constraints only and preserves the current visual contract.

## 1. Discovery

### User Outcome

Bedtime remains the earlier/left timeline handle and Wake Time remains the later/right handle. Pushing either handle into the other stops at a one-snap (15-minute) boundary without swapping identities or wrapping through.

### Success Criteria

- Drag, accessibility increment/decrement, internal adjustment, and precise picker changes share one ordering constraint.
- Ordering uses the rendered 20:00 -> next 20:00 linear position, not raw minute-of-day comparison.
- Normal overnight schedules such as 22:00 -> 06:30 remain valid.
- Constrained values save through the unchanged `WellnessTargetsData` path; Clear and derived duration remain unchanged.
- Repeated drag updates beyond an unchanged clamp do not produce extra selection haptics.

### Scope

- `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_page.dart`
- Focused regression coverage in `apps/features/settings/test/presentation/daily_wellness_settings_page_test.dart`

### Non-Goals

- Medical/recommended minimum sleep duration.
- Persistence, repository, schema, Supabase, route, or design-system changes.
- Any work from the explicitly excluded issues/slices.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: current Sleep Schedule state, timeline mapping, pan hit-testing, semantics actions, precise `showTimePicker`, Save/Clear, parent save, and current Settings docs.
- Existing pattern to follow: `_fractionOf` maps minute-of-day into a 20:00-based 24-hour linear window; timeline drag already snaps to 15 minutes and haptics only on resolved value changes.
- Tests or validation already present: Daily Wellness widget tests cover ordinary Bedtime/Wake drag, 15-minute snapping, haptic deduplication, Save/Clear, partial schedules, and cross-midnight duration.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Collision spacing is 15 minutes | Approved | Exact overlap stacks both 24dp handles, makes equal-distance hit-testing ambiguous, and represents zero duration; one existing snap interval is the smallest supported gap. | Owner / implementation evidence |
| Crossing picker values clamp | Approved | Matches requested preferred behavior and avoids adding another modal. | Owner |
| Handle identities never swap | Approved | Explicit bug contract. | Owner |

## 4. Architecture Design

### Chosen Approach

Keep a small private helper inside `_SleepScheduleBottomSheetState`: map each candidate to the linear rendered position, normalize the Wake right edge, constrain against the opposite handle by 15 minutes, and convert back to canonical minute-of-day. Reuse it from drag, accessibility adjustment, semantic next-value previews, and the precise picker.

### Ownership and Data Flow

```text
Sleep Schedule UI interaction
  -> constrained local draft minutes
  -> Save Schedule result
  -> existing Daily Wellness state
  -> existing WellnessTargetsData / repository path
```

### Alternative Rejected

Raw clock comparison is invalid for overnight schedules. Swapping identities and circular wrap-through violate the owner contract. A domain-level minimum duration would broaden scope and change persistence semantics.

### Failure and Accessibility States

Boundary actions are stable no-ops. Semantics keep Bedtime/Wake labels and announce the constrained value an increment/decrement will actually produce. Picker cancellation remains unchanged.

## 5. Implementation Plan

- [x] Harden one linear-position constraint helper, including Wake at the right-edge 20:00 position.
- [x] Route drag, accessibility adjustments/previews, and precise picker through the helper.
- [x] Add focused drag, boundary, identity, overnight, semantics, picker, haptic, Save/Clear, and duration regressions.
- [x] Run focused formatting, analysis, tests, and diff checks.
- [ ] Commit, push, open Draft PR, and wait for exact-head CI green without merging.

## 6. Quality Review

### Validation Run

```text
G:\dev\flutter-sdk\bin\dart.bat format <source> <test> -> PASS
G:\dev\flutter-sdk\bin\flutter.bat analyze (apps/features/settings) -> PASS, no issues
G:\dev\flutter-sdk\bin\flutter.bat test test\presentation\daily_wellness_settings_page_test.dart --plain-name "Sleep Schedule handle ordering" -> PASS, 5/5
G:\dev\flutter-sdk\bin\flutter.bat test test\presentation\daily_wellness_settings_page_test.dart --plain-name "repeated pointer movement beyond the clamp" -> PASS
G:\dev\flutter-sdk\bin\flutter.bat test test\presentation\daily_wellness_settings_page_test.dart -> PASS, 69/69
G:\dev\flutter-sdk\bin\flutter.bat test (apps/features/settings) -> PASS, 183/183
git diff --check -> PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| Q1 | Low | Resolved | Initial synthetic haptic test moved only far enough to accept the drag recognizer, so no update/haptic occurred. Added a post-touch-slop move; focused and full suites pass. | uncommitted | Test seam only; production logic unchanged. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/settings-sleep-schedule-handle-order.md`
- `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_page.dart`
- `apps/features/settings/test/presentation/daily_wellness_settings_page_test.dart`

### Actual Behavior

Bedtime stays left/earlier and Wake stays right/later on the 20:00 -> next 20:00 timeline. Every mutation path clamps at a 15-minute interaction gap without swapping identities. Drag retains 15-minute snapping; the precise picker retains exact-time input while obeying the same order boundary. Boundary pushes do not add haptic churn.

### Known Limitations

Exact pushed-head CI and focused owner physical-device acceptance remain pending. No app-composition change was made, so app-shell regression was not required.

### Final Status

`REVIEW`
