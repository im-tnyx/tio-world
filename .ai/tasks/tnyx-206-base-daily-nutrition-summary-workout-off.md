# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platform:** Flutter phone Meal Diary

## Owner Approval and Scope

**Approval:** Approved. The original N3A slice, incomplete-nutrient UX refinement, and Codex-review repair slices were owner-authorized with `go` / `GO`.

N3A remains workout-OFF:

```text
Target - Eaten = Remaining
```

Current bounded repair scope now includes the latest exact-head Codex findings:

- preserve exact aggregation semantics and approved incomplete-nutrient presentation;
- keep stale previous-value range decorations suppressed on range error;
- keep the canonical Core calendar contract documented;
- keep selected-day summaries on paged same-day range truth when range capability exists, with `listByLocalDate` fallback for repositories without that optional capability;
- when the repository lacks range capability, do not create the visible-range provider request and do not replace a valid selected-day summary with a permanent range-capability error;
- replace mutable offset pagination with a stable keyset cursor for paged Supabase range reads; aggregation does not require presentation ordering, so paging may use immutable unique `id` ordering while the repository continues to sort decoded entries for Diary presentation;
- keep the visual calorie ring clamped while deriving accessibility percentage from raw `Eaten / Target`, so over-target days are not announced as only 100%;
- keep summary/calendar overlap geometry stable during a Riverpod refresh that renders retained previous data, while previous-value errors still render the non-overlapped interactive error surface;
- add the smallest focused regressions for each repaired behavior;
- no Workout term, schema/RLS change, persisted daily aggregate, unrelated Diary redesign, or TNYX-207 work.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT after implementation  
**Branch:** `tnyx/tnyx-206-n3a-base-daily-nutrition-summary-workout-off`  
**Base:** `main@2866ded8a963b64a99e41b5007da4753a922c7cc`  
**PR:** #267 — Ready for review  
**Linear:** TNYX-206 — In Progress; blocks TNYX-207  
**Repository state:** connector/API session; no local worktree state is claimed.  
**R6/R7 source/docs HEAD:** `67292be4b13ccc58679347c9a53fbc21236bdc2b`; CI #2561 / run `34854445983` all green.  
**Pre-R9 HEAD:** `6369f090a74c34a04ce19439f687154450064bc7`; CI #2562 / run `34855634165` all green.  
**R9 source/test HEAD:** `a39541110275b93de094731774507a993bb42457`; CI #2565 / run `34866579339` all green.  
**Post-R9 metadata HEAD:** `5a650de0dc8a4d377542b8e3e45fc4d5b3443d13`; CI #2566 / run `34867617194` all green.  
**Latest actual Codex reviews:** `a395411102` opened the non-range capability and mutable-pagination findings plus a now-resolved stale-brief finding; `5a650de0dc` opened the over-target semantics and refresh-geometry findings.  
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
- exact affected runtime/data/test files

Relevant repository rule: materially changing a public reusable component/theme usage contract requires updating `apps/core/lib/src/theme/README.md` in the same PR. The latest repairs do not change that Core public visual contract.

## Locked Truth Contract

For each supported nutrient:

1. **Exact known** — every contributing entry has the nutrient; exact total may drive progress.
2. **Partial known / incomplete** — exact total is unavailable; a confirmed minimum may display with `+`; exact progress stays unavailable.
3. **Fully unavailable** — display `—`; never fabricate `0g+`.
4. **Known empty day** — successful empty MealLog read is exact known zero.

`+` means “at least this much is confirmed”; it is presentation-only and must never drive exact Remaining/progress.

Calendar and selected-day truth use complete paged reads when production range capability exists. Optional range capability must remain optional for injected/test repositories: lack of it removes calendar range decorations, not valid selected-day truth.

## Verified Runtime Evidence

- R6 gates decoration input with `hasRangeError ? null : rangeSummaries?.valueOrNull`; a current range error cannot render retained previous-value rings.
- R7 keeps the canonical Core README aligned with the 30dp date cell, outer progress / inner selection ordering, semantic colors, and unavailable-vs-known-zero contract.
- Production app composition supplies `PagedSupabaseMealLogTableGateway`.
- R9 updates `DailyNutritionSummaryResolver.resolve` so range-capable repositories use `listByLocalDateRange(startDate: localDate, endDate: localDate)`; repositories without that capability retain `listByLocalDate`.
- The Meal Diary page still creates `MealDiarySummaryRangeRequest` without checking the optional range capability. On a non-range repository, selected-day fallback can succeed while the range provider throws permanently and `forceError` hides the valid summary. This is the latest non-range finding.
- `PagedSupabaseMealLogTableGateway` currently increments numeric offsets across independent Supabase queries. Inserts/deletes before the next offset can shift boundaries and duplicate/omit rows. Paging should use a stable immutable unique cursor instead.
- `_calendarDecorationBuilder` currently derives spoken percentage from already-clamped `calorieProgress`; an over-target day such as 2500/2000 therefore announces 100% instead of 125%.
- `canOverlapDailySummary` currently requires runtime `AsyncData`, while `AsyncValue.when` may keep rendering retained data during `AsyncLoading` refresh. That mismatch causes the same rendered summary card to move down/up during refresh. The predicate should match the rendered data branch while excluding any error state.

## Codex Review Findings

### R6 / P2 — stale calendar rings on range error

**Status:** implemented, CI-validated, thread resolved.

### R7 / P1 — canonical Core calendar contract documentation missing

**Status:** implemented, CI-validated, thread resolved.

### R8 / P1 — active task brief stale after R6/R7 implementation

**Status:** reconciled, CI-validated, thread resolved.

### R9 / P2 — selected-day summary read can truncate above the Supabase row cap

**Status:** implemented, CI-validated, thread resolved.

Selected-day resolution prefers same-day range capability; fallback remains for non-range repositories.

### R10 / P2 — non-range repository error masks valid selected-day summary

**Status:** verified; repair pending.

Gate visible-range request creation on `MealLogRangeReadRepository`. Without range capability, keep selected-day summary available and omit calendar decorations/range error state.

### R11 / P1 — R9 task brief stale on the source/test checkpoint

**Status:** superseded by `5a650de0...`, CI-validated, thread resolved.

### R12 / P2 — offset pagination can duplicate/omit under concurrent mutation

**Status:** verified; repair pending.

Replace offset paging with keyset paging using immutable unique MealLog `id` as the pagination cursor. The local-date range remains the filter; decoded repository entries are already sorted after the complete read, so pagination order does not need to encode Diary presentation order.

### R13 / P2 — over-target calendar accessibility percentage is clamped

**Status:** verified; repair pending.

Keep `TioDateDecoration.progress` visually clamped, but compute spoken percentage from raw `eaten / target` when the decoration is otherwise valid.

### R14 / P2 — retained-data refresh causes summary geometry jump

**Status:** verified; repair pending.

Allow overlap whenever the daily summary has a rendered value and no error, including retained data during refresh; keep overlap disabled for any error and for range errors.

## Earlier Findings / Validated Behavior

R1–R5 remain resolved:

- target-save cache coherence;
- selected-summary retry;
- paged Supabase range reads;
- previous-value error does not overlap/steal the calendar handle;
- range-only error exposes Retry.

The incomplete-nutrient refinement remains locked:

- Daily Summary partial Protein: `24 g+ / 150 g` + missing-meal context, no progress bar;
- fully unavailable Protein: `— / 150 g`;
- section partial Protein: `24g+`;
- section fully unavailable Protein: `Protein —`;
- missing nutrition never becomes zero.

## Implementation Checklist

- [x] R6/R7/R8/R9/R11 implemented/reconciled, validated, and resolved with evidence.
- [x] R9 source/test HEAD `a3954111...` passed CI #2565; post-R9 metadata HEAD `5a650de0...` passed CI #2566.
- [ ] R10: gate visible-range request on `MealLogRangeReadRepository`; add non-range page regression.
- [ ] R12: replace offset pagination with stable `id` keyset cursor; update paging regressions.
- [ ] R13: compute calendar semantics percentage from raw eaten/target; add over-target regression.
- [ ] R14: keep overlap stable during retained-data refresh while preserving non-overlap on error; add refresh regression.
- [ ] Validate exact repair HEAD across Flutter/Dart analyze and tests.
- [ ] Resolve R10/R12/R13/R14 with exact-head evidence.
- [ ] Fresh thread audit = 0 unresolved.
- [ ] Trigger/observe fresh actual Codex review on exact final HEAD.
- [ ] Reconcile PR body to exact final HEAD/evidence.

## Validation / Exit Gates

Required before merge readiness:

- Flutter analyze green;
- Dart analyze green;
- Flutter tests green;
- Dart tests green;
- non-range repositories keep selected-day summary and simply omit range decorations;
- paged range reads use stable keyset pagination rather than mutable offsets;
- no duplicate/omitted aggregation caused solely by offset boundary shifts;
- over-target calendar semantics report raw percentage or equivalent over-target truth while visual ring remains clamped;
- retained-data refresh does not move the rendered summary card;
- previous-value error remains non-overlapped so Retry/handle interaction stays correct;
- exact/partial nutrient semantics remain unchanged;
- unresolved review threads = 0;
- fresh actual Codex review on exact HEAD has no new blocking P1/P2;
- PR body matches exact HEAD and validation evidence;
- explicit owner merge authorization remains a separate gate.

## Next Exact Action

Implement R10/R12/R13/R14 with focused tests, validate the resulting exact HEAD, resolve those threads with evidence, then run one fresh actual Codex review and reconcile the PR body. Keep TNYX-206 In Progress and TNYX-207 blocked until merge/post-merge sync; do not merge without separate explicit owner authorization.
