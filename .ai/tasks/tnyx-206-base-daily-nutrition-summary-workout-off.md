# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platform:** Flutter phone Meal Diary

## Owner Approval and Scope

**Approval:** Approved. The original N3A slice, the incomplete-nutrient UX refinement, and Codex-review repair slices were owner-authorized with `go` / `GO`.

N3A remains workout-OFF:

```text
Target - Eaten = Remaining
```

Current bounded repair scope:

- preserve exact aggregation semantics and the approved incomplete-nutrient presentation;
- when visible-range refresh is in `AsyncError`, do not pass Riverpod previous-value summaries into calendar decorations;
- keep the retryable range-error surface already implemented;
- document the public `TioDateCalendar` / `TioDateDecoration` ring ordering, semantic colors, and 30dp date-cell geometry in the canonical Core theme README;
- ensure selected-day Daily Nutrition consumes the complete MealLog set when the repository exposes the existing paged range-read capability, using a same-day range (`startDate == endDate`) instead of a potentially server-truncated single-day query;
- preserve compatibility for repositories that implement only `MealLogRepository` by falling back to the established `listByLocalDate` path;
- add focused regression coverage for stale previous-value calendar decorations and selected-day range-capability preference;
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
**Pre-R6/R7 HEAD:** `db4b8a42496bc8adcd8d03e04eac0fc535ef0c96`  
**R6/R7 source/docs HEAD:** `67292be4b13ccc58679347c9a53fbc21236bdc2b`  
**R6/R7 validation:** exact-head Flutter CI #2561 / run `34854445983` green for Flutter analyze, Dart analyze, Flutter tests, and Dart tests.  
**Pre-R9 HEAD:** `6369f090a74c34a04ce19439f687154450064bc7`  
**Pre-R9 validation:** exact-head Flutter CI #2562 / run `34855634165` green for Flutter analyze, Dart analyze, Flutter tests, and Dart tests.  
**Actual Codex review on pre-R9 HEAD:** reviewed `6369f090a7` and opened R9/P2 because selected-day resolution still used the potentially truncated single-day Supabase query while the calendar range path was paged.  
**Merge:** not authorized.

## Governance Read

Fresh-read for the current repair sequence:

- `AGENTS.md`
- `.ai/workflow.md`
- `apps/features/AGENTS.md`
- `apps/core/lib/src/theme/README.md`
- current task brief
- current PR #267 review threads / actual Codex reviews
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

Calendar and selected-day truth must be derived from complete reads when the production repository exposes paged range capability. A failed current visible-range read must not continue presenting a previous successful range as if it were current.

## Verified Runtime Evidence

- Before R6, `MealDiaryPage` computed `hasRangeError = rangeSummaries?.hasError == true` and forced the retryable summary error surface, but still called `_calendarDecorationBuilder(rangeSummaries?.valueOrNull)`. Riverpod may retain previous data on `AsyncError`, so stale calorie rings/semantics could remain visible during the error.
- R6 gates decoration input with `hasRangeError ? null : rangeSummaries?.valueOrNull`. A current range error therefore removes the decoration builder instead of rendering previous-value truth.
- `meal_diary_daily_nutrition_recovery_test.dart` covers successful range decoration → refresh failure retaining previous data → error surface + no calendar decorations → Retry recovery.
- `TioDateDecoration` documents the runtime layer contract in source: progress is outermost, selection sits directly inside with no decorative gap; progress uses semantic `progress`, selection/fill use `primary`.
- `TioDateCalendar` uses a 30dp normal date cell in this PR.
- R7 reconciles `apps/core/lib/src/theme/README.md` to those source contracts: 30dp cell, outer progress / inner selection with no decorative gap, `colors.progress` vs `colors.primary`, and explicit `null` unavailable vs `0` known-zero semantics.
- Production app composition supplies `PagedSupabaseMealLogTableGateway`, whose `listRowsByLocalDateRange` drains stable ordered pages.
- Before R9, `DailyNutritionSummaryResolver.resolve` still called `_mealLogRepository.listByLocalDate(localDate)` even when the same repository also implemented `MealLogRangeReadRepository`; that can diverge from the complete calendar range result when a single day exceeds the Supabase server row cap.

## Codex Review Findings

### R6 / P2 — stale calendar rings on range error

**Status:** implemented and CI-validated; thread resolution pending final exact-head reconciliation.

When a previously successful visible-range provider refresh fails, `AsyncError` can retain previous data. The repaired UI passes no calendar decoration map while `hasRangeError` is true, so old calorie rings and accessibility semantics cannot remain visible next to the unavailable/error surface. Retry still invalidates the selected/range providers and restores current decorations after recovery.

### R7 / P1 — canonical Core calendar contract documentation missing

**Status:** implemented and CI-validated; thread resolution pending final exact-head reconciliation.

The canonical Core theme README records the current reusable contract:

- normal date cell geometry is 30dp;
- progress ring is the outer visual boundary;
- selection ring is smaller and directly inside it with no decorative gap;
- progress uses `colors.progress`;
- selection/fill use `colors.primary`;
- `progress: null` remains unavailable while `progress: 0` remains known zero;
- feature/domain meaning stays outside Core.

### R8 / P1 — active task brief stale after R6/R7 implementation

**Status:** reconciled before R9; thread resolution pending final exact-head reconciliation.

The active handoff was updated after R6/R7 so it no longer instructs the next owner to redo already-implemented repairs and it records #2561 source/docs validation.

### R9 / P2 — selected-day summary read can truncate above the Supabase row cap

**Status:** repair authorized; implementation/test pending.

The production repository exposes `MealLogRangeReadRepository` through the paged gateway, but selected-day resolution still uses `listByLocalDate`. The repair will prefer `listByLocalDateRange(startDate: localDate, endDate: localDate)` whenever that capability exists, preserving the existing single-day API only as a compatibility fallback for repositories without range-read capability. This keeps selected-day card and calendar truth aligned without adding schema or persistence changes.

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

- [x] Fresh PR/Linear/governance/runtime audit for R6/R7/R9.
- [x] Verify R6/R7/R9 findings against exact source.
- [x] R6: suppress visible-range decorations while the range provider is in error, including previous-value `AsyncError`.
- [x] Add R6 recovery regression.
- [x] R7: update canonical Core theme README with the current 30dp / outer-progress / inner-selection / semantic-color calendar contract.
- [x] R6/R7 source/docs HEAD `67292be4...` passed Flutter/Dart analyze and tests in CI #2561 / run `34854445983`.
- [x] Pre-R9 metadata HEAD `6369f090...` passed Flutter/Dart analyze and tests in CI #2562 / run `34855634165`.
- [ ] R9: prefer same-day `MealLogRangeReadRepository` read in selected-day resolver when available; preserve fallback for non-range repositories.
- [ ] Add focused resolver regression proving range capability is used for selected-day truth and single-day fallback remains compatible.
- [ ] Validate exact post-R9 HEAD.
- [ ] Resolve R6/R7/R8/R9 review threads with validation evidence.
- [ ] Trigger/observe fresh actual Codex review on exact final HEAD.
- [ ] Reconcile PR body to exact final HEAD/evidence.

## Validation / Exit Gates

Required before merge readiness:

- Flutter analyze green;
- Dart analyze green;
- Flutter tests green;
- Dart tests green;
- range `AsyncError` never renders stale previous-value calendar decorations or semantics;
- Retry still restores decorations after the range source recovers;
- selected-day summary uses complete paged same-day truth when range capability exists;
- non-range repositories retain the established selected-day fallback;
- selected-day card and calendar cannot diverge solely because one path is capped at one Supabase page;
- exact/partial nutrient semantics remain unchanged;
- canonical Core README matches the actual reusable calendar contract;
- unresolved review threads = 0;
- fresh actual Codex review on exact HEAD has no new blocking P1/P2;
- PR body matches exact HEAD and validation evidence;
- explicit owner merge authorization remains a separate gate.

## Next Exact Action

Implement R9 in the selected-day resolver with focused compatibility coverage, validate the resulting exact HEAD, then resolve R6/R7/R8/R9 with evidence, trigger/observe one fresh actual Codex review, and reconcile the PR body. Keep TNYX-206 In Progress and TNYX-207 blocked until merge/post-merge sync; do not merge without separate explicit owner authorization.
