# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platform:** Flutter phone Meal Diary

## Owner Approval and Scope

**Approval:** Approved. The original N3A slice, the incomplete-nutrient UX refinement, and the Codex-review repair slice were owner-authorized with `go` / `GO`.

N3A remains workout-OFF:

```text
Target - Eaten = Remaining
```

Current bounded repair scope is implemented:

- preserve exact aggregation semantics and the approved incomplete-nutrient presentation;
- when visible-range refresh is in `AsyncError`, do not pass Riverpod previous-value summaries into calendar decorations;
- keep the retryable range-error surface already implemented;
- document the public `TioDateCalendar` / `TioDateDecoration` ring ordering, semantic colors, and 30dp date-cell geometry in the canonical Core theme README;
- add focused regression coverage for stale previous-value calendar decorations;
- no Workout term, schema/RLS change, new persisted total, unrelated Diary redesign, or TNYX-207 work.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT after implementation  
**Branch:** `tnyx/tnyx-206-n3a-base-daily-nutrition-summary-workout-off`  
**Base:** `main@2866ded8a963b64a99e41b5007da4753a922c7cc`  
**PR:** #267 — Ready for review  
**Linear:** TNYX-206 — In Progress; blocks TNYX-207  
**Repository state:** connector/API session; no local worktree state is claimed.  
**Pre-repair HEAD:** `db4b8a42496bc8adcd8d03e04eac0fc535ef0c96`  
**Repair source/docs HEAD:** `67292be4b13ccc58679347c9a53fbc21236bdc2b`  
**Repair validation:** exact-head Flutter CI #2561 / run `34854445983` green for Flutter analyze, Dart analyze, Flutter tests, and Dart tests.  
**Actual Codex review that opened this slice:** reviewed `db4b8a4249` after PR was marked Ready and opened R6/P2 + R7/P1. Both are implemented and validated; their GitHub threads should be resolved with the #2561 evidence after this checkpoint.  
**Final metadata policy:** this handoff reconciliation is metadata-only. Do not edit this task brief again solely to chase its resulting SHA; validate that final SHA externally and pin final CI/review evidence in the PR body.  
**Merge:** not authorized.

## Governance Read

Fresh-read before this repair slice:

- `AGENTS.md`
- `.ai/workflow.md`
- `apps/features/AGENTS.md`
- `apps/core/lib/src/theme/README.md`
- current task brief
- current PR #267 review threads
- Linear TNYX-206 relations/status
- exact affected runtime/test files

Relevant repository rule: materially changing a public reusable component/theme usage contract requires updating `apps/core/lib/src/theme/README.md` in the same PR.

## Locked Truth Contract

For each supported nutrient:

1. **Exact known** — every contributing entry has the nutrient; exact total may drive progress.
2. **Partial known / incomplete** — exact total is unavailable; a confirmed minimum may display with `+`; exact progress stays unavailable.
3. **Fully unavailable** — display `—`; never fabricate `0g+`.
4. **Known empty day** — successful empty MealLog read is exact known zero.

`+` means “at least this much is confirmed”; it is presentation-only and must never drive exact Remaining/progress.

Calendar truth follows the same unavailable-vs-zero rule: a failed current visible-range read must not continue presenting a previous successful range as if it were current.

## Verified Runtime Evidence

- Before R6, `MealDiaryPage` computed `hasRangeError = rangeSummaries?.hasError == true` and forced the retryable summary error surface, but still called `_calendarDecorationBuilder(rangeSummaries?.valueOrNull)`. Riverpod may retain previous data on `AsyncError`, so stale calorie rings/semantics could remain visible during the error.
- R6 now gates decoration input with `hasRangeError ? null : rangeSummaries?.valueOrNull`. A current range error therefore removes the decoration builder instead of rendering previous-value truth.
- `meal_diary_daily_nutrition_recovery_test.dart` now covers successful range decoration → refresh failure retaining previous data → error surface + no calendar decorations → Retry recovery.
- `TioDateDecoration` already documents the runtime layer contract in source: progress is outermost, selection sits directly inside with no decorative gap; progress uses semantic `progress`, selection/fill use `primary`.
- `TioDateCalendar` uses a 30dp normal date cell in this PR.
- R7 reconciles `apps/core/lib/src/theme/README.md` to those source contracts: 30dp cell, outer progress / inner selection with no decorative gap, `colors.progress` vs `colors.primary`, and explicit `null` unavailable vs `0` known-zero semantics.
- Incremental repair compare from the task-brief checkpoint to `67292be4...` was bounded to three implementation/doc files: page `3+/1-`, recovery test `+65`, theme README `2+/2-`; no collateral file drift.

## Codex Review Findings

### R6 / P2 — stale calendar rings on range error

**Status:** implemented and CI-validated; thread resolution pending this handoff checkpoint.

When a previously successful visible-range provider refresh fails, `AsyncError` can retain previous data. The repaired UI passes no calendar decoration map while `hasRangeError` is true, so old calorie rings and accessibility semantics cannot remain visible next to the unavailable/error surface. Retry still invalidates the selected/range providers and restores current decorations after recovery.

### R7 / P1 — canonical Core calendar contract documentation missing

**Status:** implemented and CI-validated; thread resolution pending this handoff checkpoint.

The canonical Core theme README now records the current reusable contract:

- normal date cell geometry is 30dp;
- progress ring is the outer visual boundary;
- selection ring is smaller and directly inside it with no decorative gap;
- progress uses `colors.progress`;
- selection/fill use `colors.primary`;
- `progress: null` remains unavailable while `progress: 0` remains known zero;
- feature/domain meaning stays outside Core.

## Earlier Findings / Validated Behavior

R1–R5 remain resolved:

- target-save cache coherence;
- selected-summary retry;
- paged Supabase range reads;
- previous-value error does not overlap/steal the calendar handle;
- range-only error exposes Retry.

The incomplete-nutrient refinement also remains locked:

- Daily Summary partial Protein: `24 g+ / 150 g` + missing-meal context, no progress bar;
- fully unavailable Protein: `— / 150 g`;
- section partial Protein: `24g+`;
- section fully unavailable Protein: `Protein —`;
- missing nutrition never becomes zero.

## Implementation Checklist

- [x] Fresh PR/Linear/governance/runtime audit for R6/R7.
- [x] Verify both new Codex findings against exact current source.
- [x] R6: suppress visible-range decorations while the range provider is in error, including previous-value `AsyncError`.
- [x] Add regression: successful range decoration → refresh failure retaining previous value → error surface visible and calendar decoration absent → Retry recovers current decorations.
- [x] R7: update canonical Core theme README with the current 30dp / outer-progress / inner-selection / semantic-color calendar contract.
- [x] Repair source/docs HEAD `67292be4...` passed Flutter/Dart analyze and tests in CI #2561 / run `34854445983`.
- [ ] Resolve R6/R7 review threads with validation evidence.
- [ ] Validate this metadata-only final handoff SHA.
- [ ] Trigger/observe fresh actual Codex review on the exact final HEAD.
- [ ] Reconcile PR body to exact final HEAD/evidence.

## Validation / Exit Gates

Required before merge readiness:

- Flutter analyze green;
- Dart analyze green;
- Flutter tests green;
- Dart tests green;
- range `AsyncError` never renders stale previous-value calendar decorations or semantics;
- Retry still restores decorations after the range source recovers;
- exact/partial nutrient semantics remain unchanged;
- canonical Core README matches the actual reusable calendar contract;
- unresolved review threads = 0;
- fresh actual Codex review on exact HEAD has no new blocking P1/P2;
- PR body matches exact HEAD and validation evidence;
- explicit owner merge authorization remains a separate gate.

## Next Exact Action

Resolve R6/R7 with #2561 evidence, validate this metadata-only checkpoint on its exact resulting HEAD, then trigger/observe one fresh actual Codex review and reconcile the PR body. Keep TNYX-206 In Progress and TNYX-207 blocked until merge/post-merge sync; do not merge without separate explicit owner authorization.
