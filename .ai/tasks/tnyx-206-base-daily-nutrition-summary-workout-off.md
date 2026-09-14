# TNYX-206 — N3A Base Daily Nutrition Summary (workout OFF)

**Status:** In progress  
**Primary owner:** `apps/features/nutrition`  
**Affected platform:** Flutter phone Meal Diary

## Owner Approval and Scope

**Approval:** Approved. The original N3A implementation was owner-approved with `go`; on 2026-09-14 the owner explicitly approved the incomplete-nutrient UX refinement with `GO`.

N3A remains workout-OFF:

```text
Target - Eaten = Remaining
```

Current bounded refinement:

- preserve exact aggregation semantics: a nutrient is exact only when every contributing MealLog contains that nutrient;
- never replace missing nutrition with `0`;
- when some entries have a nutrient and some do not, retain a presentation-safe confirmed minimum plus the number of missing entries;
- Daily Summary may render `24g+ / 150g` with an incomplete indicator while exact consumed total/progress remain unavailable;
- Meal section header renders exact grams, a partial `24g+`, or explicit `Protein —` when no protein amount is known;
- do not derive exact Remaining/progress from a `+` lower bound;
- no Workout term, schema/RLS change, new persisted total, unrelated Diary redesign, or TNYX-207 work.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT after implementation  
**Branch:** `tnyx/tnyx-206-n3a-base-daily-nutrition-summary-workout-off`  
**Base:** `main@2866ded8a963b64a99e41b5007da4753a922c7cc`  
**Draft PR:** #267  
**Linear:** TNYX-206 — In Progress; blocks TNYX-207  
**Repository state:** connector/API session; no local worktree state is claimed.  
**Pre-refinement HEAD:** `a445a97ee79d8878df3f4fa17eb86d83a484aa55`  
**Pre-refinement validation:** Flutter CI #2541 / run `34807629996` green for Flutter analyze, Dart analyze, Flutter tests, and Dart tests; all five prior Codex findings R1–R5 resolved; unresolved threads 0; final review `5194084768` reported no new P1/P2.  
**Refinement validation:** source/test HEAD `31c74b72ecb7a09ea242d02cc73b122441fd69d3` passed Flutter CI #2555 / run `34809905692`: Flutter analyze, Dart analyze, Flutter tests, and Dart tests all green. Documentation checkpoint HEAD `0c2e478cc1b9c853d82b39ad6143d07ab394075b` then passed exact-head Flutter CI #2556 / run `34848212107` with the same four gates green. Fresh exact-head Codex-style review `5198219045` on `0c2e478c...` reported no new P1/P2, thread audit remained 0 unresolved, and fresh compare stayed 87 ahead / 0 behind current main.  
**Final metadata policy:** this brief closure commit only records already-completed evidence. Do not edit the task brief again solely to chase its own resulting SHA. Validate that final metadata-only SHA externally via CI, then pin that SHA/run/review in the PR body; PR metadata does not mutate the branch.  
**Merge:** not authorized.

## Governance Read

Before this UI-affecting refinement, read and followed:

- `AGENTS.md`
- `.ai/tasks/README.md`
- `.ai/tasks/design-system-token-consolidation.md`
- `apps/features/AGENTS.md`
- `apps/core/lib/src/theme/README.md`
- current PR #267 and Linear TNYX-206

No new Core token/component contract is needed. Existing feature composition and governed typography/spacing remain in use.

## Verified Runtime Evidence

- Before this slice, `DailyNutritionSummaryResolver._aggregate` dropped a nutrient from exact `consumedTotals` as soon as one MealLog was missing that nutrient. That correctly prevented a partial sum from masquerading as exact but discarded the known lower bound.
- `DailyNutritionSummary.progressFor` requires exact consumed truth and a positive target; the refinement keeps that exact-only calculation contract unchanged.
- `MealDiarySectionReadModel.proteinGrams` remains exact-only via `_allKnownTotal`; section coverage is derived separately from the same canonical entries rather than weakening that field.
- Daily Summary keeps Carbs/Protein/Fat/Fiber cells visible and renders unavailable exact truth explicitly.
- Quick Add requires Calories but Protein is optional, so mixed known/missing Protein rows are a normal valid state.

## Locked Truth Contract

For each supported nutrient, distinguish these states:

1. **Exact known** — every contributing entry has the nutrient. Existing exact total remains authoritative and may drive progress.
2. **Partial known / incomplete** — at least one entry has the nutrient and at least one entry is missing it. Exact total remains unavailable; a confirmed minimum may be displayed with `+`, e.g. `24g+`; progress remains unavailable.
3. **Fully unavailable** — contributing entries exist but none provide the nutrient. Display `—`; never display `0g+`.
4. **Known empty day** — a successful read with no MealLogs is exact known zero, unchanged from current behavior.

`+` means “at least this much is confirmed”; it is not an estimate and not an exact aggregate.

## Implemented Model Shape

Existing exact fields/contracts stay intact. Presentation-safe coverage is additive:

```text
DailyNutritionSummary
  consumedTotals                       existing; exact-only
  confirmedConsumedTotals              new; lower-bound facts only when partial
  missingConsumedEntryCounts           new

MealDiarySectionReadModel
  proteinGrams                          existing; exact-only
  entries                               existing canonical section entries

mealDiarySectionProteinCoverage(section)
  exactTotal                            mirrors exact section protein truth
  confirmedTotal                        derived lower bound when at least one value exists
  missingEntryCount                     derived from canonical section entries
```

The Daily Summary resolver performs one aggregation pass over canonical MealLog facts. Section coverage is derived by a Nutrition-owned helper from the existing section entries; the widget does not infer missingness from display strings and the canonical section read model is not weakened.

## Approved Presentation

### Daily Summary

- exact Protein: `70 g / 150 g` and normal progress bar;
- partial Protein: `24 g+ / 150 g`, no progress bar, compact missing-meal indication such as `1 meal missing protein`;
- fully unavailable Protein: `— / 150 g`, no progress bar;
- missing target remains confirmed/exact consumed against `—`, with no fabricated progress;
- accessibility semantics explicitly state “at least”, missing meal count, and incomplete truth.

### Meal section header

- exact Protein: existing `38g` with the Protein glyph;
- partial Protein: `24g+` with the Protein glyph;
- fully unavailable Protein: literal `Protein —` so the nutrient does not disappear; no value glyph is shown for an unavailable value;
- no partial value is exposed as exact.

Individual MealLog cards remain unchanged in this slice.

## Implementation Checklist

- [x] Fresh PR/Linear/runtime audit.
- [x] UI/design-system governance read.
- [x] Owner approval for incomplete-nutrient UX refinement.
- [x] Extend Daily Nutrition derived read model with confirmed minimum + missing count while preserving exact-only `consumedTotals`.
- [x] Derive section Protein coverage from existing canonical entries while preserving exact-only `proteinGrams`.
- [x] Render Daily Summary partial values with `+`, missing-meal indication, and no fabricated progress.
- [x] Render section-header Protein as exact / `+` / explicit `Protein —` instead of hiding incomplete Protein.
- [x] Add focused partial-known/all-missing widget/history regressions; existing suite continues to cover exact/empty-day behavior.
- [x] Reconcile `docs/screens/meal-diary.md` for the incomplete-nutrient truth contract.
- [x] Source-bearing implementation HEAD CI green — #2555 / run `34809905692` on `31c74b72ecb7a09ea242d02cc73b122441fd69d3`.
- [x] Post-refinement documentation checkpoint CI green — #2556 / run `34848212107` on `0c2e478cc1b9c853d82b39ad6143d07ab394075b`; PR body reconciled to that evidence.
- [x] Fresh documentation-checkpoint Codex-style review clean — review `5198219045`, no new P1/P2; 0 unresolved threads.

## Validation / Exit Gates

Required before merge readiness:

- Flutter analyze green;
- Dart analyze green;
- Flutter tests green;
- Dart tests green;
- exact consumed/progress semantics unchanged for all-known and empty-day states;
- incomplete values never produce exact progress or fake Remaining;
- focused compact-width behavior remains overflow-free;
- unresolved review threads = 0;
- fresh exact-head Codex-style review has no new P1/P2;
- PR body matches exact HEAD and validation evidence;
- explicit owner merge authorization remains a separate gate.

## Prior Review Findings

R1–R5 from the earlier N3A review cycle are resolved and validated on historical HEAD `a445a97ee79d8878df3f4fa17eb86d83a484aa55`. Fresh thread audit after the refinement still reports 0 unresolved threads. This refinement must not regress target-refresh, summary/range retry, paged range reads, or calendar-handle interaction.

## Next Exact Action

Validate this final metadata-only closure SHA with CI. If all four gates remain green, update the PR body to pin that resulting exact HEAD/run and submit one final exact-head review without editing this task brief again. Keep the PR Draft and do not merge without separate explicit owner authorization.
