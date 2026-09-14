# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platform:** Flutter phone Meal Diary

## Owner Approval and Scope

**Approval:** Approved. The original N3A slice, the incomplete-nutrient UX refinement, and the current Codex-review repair slice were owner-authorized with `go` / `GO`.

N3A remains workout-OFF:

```text
Target - Eaten = Remaining
```

Current bounded repair scope:

- preserve exact aggregation semantics and the approved incomplete-nutrient presentation;
- when visible-range refresh is in `AsyncError`, do not pass Riverpod previous-value summaries into calendar decorations;
- keep the retryable range-error surface already implemented;
- document the already-shipped public `TioDateCalendar` / `TioDateDecoration` ring ordering, semantic colors, and 30dp date-cell geometry in the canonical Core theme README;
- add/adjust focused regression coverage for stale previous-value calendar decorations;
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
**Pre-repair validation:** exact-head Flutter CI #2557 / run `34849217429` green for Flutter analyze, Dart analyze, Flutter tests, and Dart tests.  
**Actual Codex review:** reviewed `db4b8a4249` after PR was marked Ready and opened two new unresolved findings, R6/P2 and R7/P1 below.  
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

- `MealDiaryPage` computes `hasRangeError = rangeSummaries?.hasError == true`, correctly forces the retryable summary error surface, but still calls `_calendarDecorationBuilder(rangeSummaries?.valueOrNull)`. Riverpod may retain previous data on `AsyncError`, so stale calorie rings/semantics can remain visible during the error.
- The minimal runtime repair is to gate decoration input on `!hasRangeError` (or otherwise pass `null` while errored) without changing retry/provider semantics.
- Existing `meal_diary_daily_nutrition_recovery_test.dart` covers range-only initial error and previous-value selected-summary error, but not a **successful range → invalidation → range error with previous value** sequence. Add that regression.
- `TioDateDecoration` already documents the runtime layer contract in source: progress is outermost, selection sits directly inside with no decorative gap; progress uses semantic `progress`, selection/fill use `primary`.
- `TioDateCalendar` changed `_dateCellSize` from 28dp to 30dp in this PR. The canonical theme README currently says only that `TioDateCalendar` accepts generic decoration state and does not record the new ring ordering/color/geometry contract.

## Codex Review Findings

### R6 / P2 — stale calendar rings on range error

**Status:** accepted, repair pending.

When a previously successful visible-range provider refresh fails, `AsyncError` can retain previous data. The current `valueOrNull` path still supplies that map to `TioDateCalendar`, so old calorie rings and accessibility semantics can remain visible next to an error card. During a range error, calendar decorations must be unavailable (`null`) rather than stale.

### R7 / P1 — canonical Core calendar contract documentation missing

**Status:** accepted, repair pending.

This PR materially changed the public reusable calendar visual contract but did not update `apps/core/lib/src/theme/README.md`. Document the current contract in that README:

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
- [ ] R6: suppress visible-range decorations while the range provider is in error, including previous-value `AsyncError`.
- [ ] Add regression: successful range decoration → refresh failure retaining previous value → error surface visible and calendar decoration absent → Retry recovers current decorations.
- [ ] R7: update canonical Core theme README with the current 30dp / outer-progress / inner-selection / semantic-color calendar contract.
- [ ] Run exact-head Flutter/Dart analyze and tests.
- [ ] Reconcile R6/R7 review threads only after validation.
- [ ] Trigger/observe fresh actual Codex review on the exact repaired HEAD.
- [ ] Reconcile PR body to exact repaired HEAD/evidence.

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

Implement the smallest R6 runtime gate + focused recovery regression and R7 canonical README correction. Then run fresh exact-head CI, resolve the two Codex threads with evidence, and require a fresh actual Codex review before any merge-readiness claim.
