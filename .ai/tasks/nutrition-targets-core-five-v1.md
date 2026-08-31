# Nutrition Targets V1 — Core Five

**Status:** Implemented — awaiting CI and physical-device acceptance
**Primary owner:** Flutter mobile / Nutrition feature (Settings is navigation only)
**Affected platforms:** Flutter Android and iOS

## Global UI / Design-System Guardrail

No new token, geometry, typography, or component contract. Every surface reuses
existing primitives. This slice also **removes** duplication rather than adding
it: the row/card widgets shared with Nutrition Profile were extracted, and the
two Nutrition routes now share one load-failure state.

## 1. Discovery

### User Outcome

A Nutrition or Hybrid user can open Settings → Nutrition & Diet → Nutrition
Targets and change their daily Calories, Protein, Carbohydrates, Fat and Fiber
without redoing onboarding — editing the same canonical row onboarding wrote.

### Success Criteria

- All five core targets render with correct units; unknown reads `Not set`.
- Editing one target never rewrites another, nor the recommendation provenance.
- A materially incoherent row cannot be saved, and the user is shown both sides.
- A partial row is never falsely blocked.

### Scope

Core five only. Additional Nutrient Goals (TNYX-141) is a separate slice.

### Non-Goals

Percentage macros, automatic rebalance, Reset-to-Recommended, additional
nutrient goals, meal calorie allocation, Diet Plan, Meal Log, Food Catalog,
NutritionSnapshot, providers, reference-sex, life-stage, and any schema change.

## 2. Codebase Exploration

### Verified Evidence

- `NutritionTargetsRepository.upsert` replaces the whole canonical row, so any
  partial write would clear untouched targets and metadata.
- `recommendationMetadata` persists only `{source, bmr, tdee}`; the macro
  formula needs `weightKg` and `primaryGoal`, which are **not** in the row.
  Re-deriving macros from a Calories change is therefore impossible without
  reaching into Body/Profile — so V1 does not re-derive at all.
- The recommendation rounds each macro independently, so shipped `recommended`
  rows already sit a few kcal off exact. A strict-equality coherence rule would
  have flagged every existing row as invalid on first open.
- `customizedFields` had never been written non-empty anywhere. This slice is
  its first writer, so it defines the vocabulary; no existing consumer breaks.
- `NutrientId` (merged in TNYX-143) is a **different namespace** from
  `NutritionTargetField`. Neither is renamed for symmetry with the other.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Grams-first, no percentage mode | Approved | Percentage intent is not persisted and cannot be reconstructed |
| Calories change never re-derives macros | Approved | Required inputs are not in the row; reaching across owners would overwrite user values |
| ≤ 5 kcal coherence tolerance | Approved | Independent rounding means real rows are never exactly equal |
| Coherence evaluated only when all four are present | Approved | Treating null as zero would fabricate a value and produce a false block |
| Custom intent only accumulates | Approved | Clearing it belongs to an explicit Reset flow, not to typing a familiar number |

## 4. Architecture Design

- `NutritionTargetField` — typed core-five vocabulary for `customized_fields`.
- `NutritionTargetEditor` — pure rules: coherence, provenance, merge-preserving
  edit. Kept out of the widget layer so the contracts are testable directly.
- `NutritionTargetsSettingsPage` — rows plus one focused numeric editor per
  target, rather than a dense five-field form.
- `apps/app` owns composition: read provider, loading/error/retry, invalidation.

## 5. Implementation Plan

- [x] Add `NutritionTargetField` and `NutritionTargetEditor`.
- [x] Add `NutritionTargetsSettingsPage` with a per-target editor sheet.
- [x] Extract shared Nutrition settings row/card widgets; move Profile onto them.
- [x] Extract one shared Nutrition load-failure state for both routes.
- [x] Add the Targets row to the Nutrition hub.
- [x] Add the route contract, chrome policy entry, provider and router wiring.
- [x] Tests: domain rules, page behaviour, hub, route-level preservation.
- [x] `dart format`, `flutter analyze`, affected package suites.
- [ ] CI on the exact PR head.
- [ ] Physical-device acceptance by the owner.

## 6. Quality Review

- `flutter analyze`: clean on `apps/core`, `apps/features/nutrition`, `apps/app`.
- Tests: nutrition 82, app 266, settings 175, core 116, onboarding 447.
- Preservation is covered at two levels: the pure editor, and a route test
  asserting the repository received the untouched fields and metadata.

### Presentation & limit policy (added after owner UI review)

Card hierarchy is frozen as three sections: **DAILY CALORIE GOAL**,
**MACRONUTRIENTS** (C/P/F grouped), and **FIBER** separate. Fiber is not
grouped with the energy macros because it is excluded from their relationship.

Macro rows carry a **read-only** derived share of macro energy. It is not
persisted, not editable, and adds no percentage/grams mode -- that remains N12.
Shares use largest-remainder apportionment so they total exactly 100; rounding
each independently would display 99% or 101%, which reads as a bug. When any
macro is unknown, or the macros carry no energy at all, no percentage is shown
rather than a fabricated `0%`.

A quiet "Calories from macros" line appears when the row is coherent; beyond
tolerance it is replaced by the existing warning.

**Limit policy.** One new hard rule, and it is a storage constraint rather than
a health judgement: `calories_kcal` is a Postgres `integer`, so a larger value
would fail at the database. Everything else was deliberately left alone --
recommended is not the same as allowed, and no defensible universal upper bound
exists for any target. The calculator's 25-50 fiber clamp is a *recommendation
heuristic*, not a constraint, and must never become one.

Recommendation context was audited and **not** added: `recommendationMetadata`
carries only `{source, bmr, tdee}`, never the recommended calorie value, so
after the first edit the original recommendation is unrecoverable. Showing
"Recommended: X" would have required fabricating it.

### Deliberate divergence worth reviewing

The coherence warning appears **on the page**, not only inside an editor. A row
can already be incoherent when opened — onboarding-written rows are not
guaranteed within tolerance — so telling the user only after they open an
unrelated field would hide the problem.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/nutrition-targets-core-five-v1.md` (this file)
- `apps/core/lib/src/routing/routes/app_routes.dart`
- `apps/features/nutrition/lib/src/domain/models/nutrition_target_field.dart`
- `apps/features/nutrition/lib/src/domain/usecases/nutrition_target_editor.dart`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_targets_settings_page.dart`
- `apps/features/nutrition/lib/src/presentation/widgets/nutrition_settings_widgets.dart`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_profile_settings_page.dart`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_settings_page.dart`
- barrels: `models.dart`, `usecases.dart`, `pages.dart`, `presentation.dart`
- `apps/app/lib/app/network_providers.dart`, `apps/app/lib/app/router.dart`
- tests: nutrition domain + presentation, app route

### Actual Behavior

Nutrition and Hybrid users reach Nutrition Targets from the Nutrition hub and
edit any of the five core targets. Unknown values read `Not set` and can be
cleared back to unset. A Calories change leaves macros exactly as they were. A
mismatch beyond 5 kcal blocks Save and shows target, macro-derived and
difference. Saving writes a fully merged canonical row.

**Current status:** IMPLEMENTED — local validation complete; CI and
physical-device acceptance pending. Schema NONE, Supabase UNCHANGED.
