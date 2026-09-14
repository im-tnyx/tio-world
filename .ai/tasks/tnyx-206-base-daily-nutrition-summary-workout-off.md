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
- Meal section header may render `24g+`; if no protein amount is known it renders `—` rather than hiding Protein;
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

- `DailyNutritionSummaryResolver._aggregate` currently drops a nutrient from `consumedTotals` as soon as one MealLog is missing that nutrient. This correctly prevents a partial sum from masquerading as exact, but also discards the known lower bound.
- `DailyNutritionSummary` currently exposes only exact `consumedTotals`; `progressFor` correctly requires an exact consumed value and positive target.
- `MealDiarySectionReadModel.proteinGrams` is exact-only via `_allKnownTotal`; `_SectionNutritionSummary` currently hides the Protein glyph/value when that exact aggregate is null.
- Daily Summary already keeps Carbs/Protein/Fat/Fiber cells visible and renders `—` for unavailable exact truth.
- Quick Add requires Calories but Protein is optional, so mixed known/missing Protein rows are a normal valid state.

## Locked Truth Contract

For each supported nutrient, distinguish these states:

1. **Exact known** — every contributing entry has the nutrient. Existing exact total remains authoritative and may drive progress.
2. **Partial known / incomplete** — at least one entry has the nutrient and at least one entry is missing it. Exact total remains unavailable; a confirmed minimum may be displayed with `+`, e.g. `24g+`; progress remains unavailable.
3. **Fully unavailable** — contributing entries exist but none provide the nutrient. Display `—`; never display `0g+`.
4. **Known empty day** — a successful read with no MealLogs is exact known zero, unchanged from current behavior.

`+` means “at least this much is confirmed”; it is not an estimate and not an exact aggregate.

## Chosen Model Shape

Keep existing exact fields/contracts intact and add presentation-safe metadata:

```text
DailyNutritionSummary
  exact consumedTotals                 existing
  confirmedConsumedTotals              new; exact or lower-bound facts
  missingConsumedEntryCounts           new

MealDiarySectionReadModel
  proteinGrams                          existing exact-only
  confirmedProteinGrams                 new lower-bound when at least one value exists
  missingProteinEntryCount              new
```

The resolver/read-model aggregation performs one pass over canonical MealLog facts. No widget infers missingness from display strings.

## Approved Presentation

### Daily Summary

- exact Protein: `70 g / 150 g` and normal progress bar;
- partial Protein: `24 g+ / 150 g`, no progress bar, compact `incomplete`/missing-meal indication;
- fully unavailable Protein: `— / 150 g`, no progress bar;
- missing target remains `confirmed/exact consumed / —` with no progress bar;
- accessibility semantics must explicitly state incomplete truth and missing meal count.

### Meal section header

- exact Protein: existing `38g`;
- partial Protein: `24g+`;
- fully unavailable Protein: `—` instead of silently removing Protein from the visible header summary;
- no partial value is exposed as exact.

Individual MealLog cards remain unchanged in this slice.

## Implementation Checklist

- [x] Fresh PR/Linear/runtime audit.
- [x] UI/design-system governance read.
- [x] Owner approval for incomplete-nutrient UX refinement.
- [ ] Extend Daily Nutrition derived read model with confirmed minimum + missing count while preserving exact-only `consumedTotals`.
- [ ] Extend section read model with Protein confirmed minimum + missing count while preserving exact-only `proteinGrams`.
- [ ] Render Daily Summary partial values with `+`, incomplete indication, and no fabricated progress.
- [ ] Render section-header Protein as exact / `+` / `—` instead of hiding incomplete Protein.
- [ ] Add focused domain/widget/history regressions including all-known, partial-known, all-missing, empty-day, and accessibility semantics.
- [ ] Reconcile `docs/screens/meal-diary.md` and PR body.
- [ ] Run exact-head CI and fresh Codex-style review; resolve only evidence-backed findings.

## Validation / Exit Gates

Required before merge readiness:

- Flutter analyze green;
- Dart analyze green;
- Flutter tests green;
- Dart tests green;
- exact consumed/progress semantics unchanged for all-known and empty-day states;
- incomplete values never produce exact progress or fake Remaining;
- focused light/dark/compact-width behavior remains overflow-free;
- unresolved review threads = 0;
- fresh exact-head Codex-style review has no new P1/P2;
- PR body matches exact HEAD and validation evidence;
- explicit owner merge authorization remains a separate gate.

## Prior Review Findings

R1–R5 from the earlier N3A review cycle are resolved and validated on historical HEAD `a445a97ee79d8878df3f4fa17eb86d83a484aa55`. This refinement must not regress target-refresh, summary/range retry, paged range reads, or calendar-handle interaction.

## Next Exact Action

Implement the smallest model/resolver/read-model changes that preserve exact truth while carrying confirmed lower bounds and missing counts. Then update the two existing presentation surfaces, add focused tests, reconcile docs, and require fresh exact-head CI/review. Do not merge without explicit owner authorization.
