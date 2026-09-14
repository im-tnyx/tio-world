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

The current bounded implementation preserves the original product truth while closing the latest Codex findings:

- exact aggregation semantics and approved incomplete-nutrient presentation remain unchanged;
- stale previous-value range decorations stay suppressed on range error;
- the canonical Core calendar contract stays documented;
- selected-day summaries use paged same-day range truth when range capability exists, with `listByLocalDate` fallback for repositories without that optional capability;
- repositories without range capability keep valid selected-day Daily Nutrition and simply omit calendar range decorations;
- production Supabase range pagination uses immutable unique MealLog `id` keyset paging instead of numeric offsets;
- visual calorie progress remains clamped while accessibility percentage is derived from raw `Eaten / Target`;
- retained-data refresh keeps the compact summary/calendar overlap geometry stable, while any error state remains non-overlapped and interactive;
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
**R10/R12/R13/R14 source/test HEAD:** `7e55df9c9275c97eff37e2b803387b14f5009c1c`; CI #2573 / run `34872675496` all green for Flutter analyze, Dart analyze, Flutter tests, and Dart tests.  
**Final metadata policy:** this handoff reconciliation is metadata-only. Do not edit this task brief again solely to chase its resulting SHA; validate that final SHA externally and pin final CI/review evidence in the PR body.  
**Merge:** not authorized.

## Governance Read

Fresh-read for the repair sequence:

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

Calendar and selected-day truth use complete paged reads when production range capability exists. Optional range capability remains optional for injected/test repositories: lack of it removes calendar range decorations, not valid selected-day truth.

## Verified Runtime Evidence

- R6 gates decoration input with `hasRangeError ? null : rangeSummaries?.valueOrNull`; current range errors cannot render retained previous-value rings.
- R7 keeps the canonical Core README aligned with the 30dp date cell, outer progress / inner selection ordering, semantic colors, and unavailable-vs-known-zero contract.
- Production app composition supplies `PagedSupabaseMealLogTableGateway`.
- R9 updates `DailyNutritionSummaryResolver.resolve` so range-capable repositories use `listByLocalDateRange(startDate: localDate, endDate: localDate)`; repositories without that capability retain `listByLocalDate`.
- R10 gates Meal Diary visible-range request creation and range invalidation on `MealLogRangeReadRepository`, so non-range repositories keep their selected-day summary and simply render no calendar decorations.
- R12 replaces numeric offsets with immutable `id` keyset pages. The local-date range remains the filter; `SupabaseMealLogRepository` sorts fully decoded results into canonical Diary order after the complete read. Paging tests cover cursor draining, a mutation behind the cursor without later-page shifting, terminal pages, and duplicate-id rejection.
- R13 keeps `TioDateDecoration.progress` visually clamped but derives spoken percentage from raw `eaten / target`; 2500/2000 therefore announces 125 percent while the ring remains full.
- R14 aligns overlap eligibility with the rendered retained-value branch: a value with no error keeps compact overlap during refresh, while any selected/range error disables overlap and preserves Retry/handle interaction.
- Focused integration/recovery regressions cover non-range summary availability, over-target semantics, retained-refresh geometry, stale range-error decorations, and error-handle behavior.

## Codex Review Findings

### R6 / P2 — stale calendar rings on range error

**Status:** implemented, CI-validated, thread resolved.

### R7 / P1 — canonical Core calendar contract documentation missing

**Status:** implemented, CI-validated, thread resolved.

### R8 / P1 — active task brief stale after R6/R7 implementation

**Status:** reconciled, CI-validated, thread resolved.

### R9 / P2 — selected-day summary read can truncate above the Supabase row cap

**Status:** implemented, CI-validated, thread resolved.

### R10 / P2 — non-range repository error masks valid selected-day summary

**Status:** implemented and CI-validated on `7e55df9c...`; thread resolution pending final exact-head validation.

Visible-range work is created only for repositories that expose `MealLogRangeReadRepository`. A selected-day-only repository therefore retains a valid Daily Nutrition card with no range-error substitution and no calendar decoration builder.

### R11 / P1 — R9 task brief stale on the source/test checkpoint

**Status:** superseded by `5a650de0...`, CI-validated, thread resolved.

### R12 / P2 — offset pagination can duplicate/omit under concurrent mutation

**Status:** implemented and CI-validated on `7e55df9c...`; thread resolution pending final exact-head validation.

Production range paging now uses immutable unique `id` as the keyset cursor rather than a mutable numeric offset. Duplicate ids across pages are rejected rather than double-counted.

### R13 / P2 — over-target calendar accessibility percentage is clamped

**Status:** implemented and CI-validated on `7e55df9c...`; thread resolution pending final exact-head validation.

The visual ring remains clamped; semantics use raw `eaten / target`, with focused coverage for 2500/2000 → 125 percent.

### R14 / P2 — retained-data refresh causes summary geometry jump

**Status:** implemented and CI-validated on `7e55df9c...`; thread resolution pending final exact-head validation.

Overlap stays enabled for retained rendered value with no error during refresh, and remains disabled for selected/range error states.

## Earlier Findings / Validated Behavior

R1–R5 remain resolved:

- target-save cache coherence;
- selected-summary retry;
- complete Supabase range reads;
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
- [x] R10: gate visible-range request/invalidation on `MealLogRangeReadRepository`; non-range page regression added.
- [x] R12: replace offset pagination with immutable-id keyset cursor; paging regressions updated.
- [x] R13: compute calendar semantics percentage from raw eaten/target; over-target regression added.
- [x] R14: keep overlap stable during retained-data refresh while preserving non-overlap on error; refresh regression added.
- [x] Exact source/test repair HEAD `7e55df9c...` passed Flutter/Dart analyze and tests in CI #2573 / run `34872675496`.
- [ ] Validate this metadata-only final handoff SHA.
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
- duplicate ids cannot be silently aggregated twice;
- over-target calendar semantics report raw percentage or equivalent over-target truth while visual ring remains clamped;
- retained-data refresh does not move the rendered summary card;
- previous-value error remains non-overlapped so Retry/handle interaction stays correct;
- exact/partial nutrient semantics remain unchanged;
- unresolved review threads = 0;
- fresh actual Codex review on exact HEAD has no new blocking P1/P2;
- PR body matches exact HEAD and validation evidence;
- explicit owner merge authorization remains a separate gate.

## Next Exact Action

Validate this metadata-only checkpoint on its exact resulting HEAD, resolve R10/R12/R13/R14 with that evidence, run one fresh actual Codex review, and reconcile the PR body. Keep TNYX-206 In Progress and TNYX-207 blocked until merge/post-merge sync; do not merge without separate explicit owner authorization.
