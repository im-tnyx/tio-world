# Nutrition Settings V1 — Nutrition Profile Edit Parity

**Status:** Implemented — awaiting CI and physical-device acceptance
**Primary owner:** Flutter mobile / Nutrition feature (Settings is navigation only)
**Affected platforms:** Flutter Android and iOS

## Global UI / Design-System Guardrail

Core theme guidance and feature-package ownership rules were read before this
slice. It introduces no new token, geometry, typography, or component contract:
every surface reuses existing `TioColors`, `TioSpacing`, `TioRadius`,
`TioFontSize`, `TioFontWeight`, `TioSize`, `TioStroke`, `TioAlpha`, `TioMotion`
and `TioButton` primitives.

## 1. Discovery

### User Outcome

A user in Nutrition or Hybrid mode can reach Settings → Nutrition & Diet →
Nutrition Profile and change the two canonical Nutrition Profile fields Product
Onboarding actually populates — Diet Type, and Allergies & Restrictions —
without redoing onboarding.

### Success Criteria

- The Settings Nutrition entry is present in Nutrition and Hybrid mode and
  absent in Workout mode (absent, not disabled or empty).
- The Nutrition hub exposes only the implemented capability; no placeholder rows.
- Nutrition Profile shows truthful summaries: unknown reads `Not set`, an
  explicitly empty allergy set reads `None`.
- Editing one field never drops the canonical fields the screen does not render.
- Regression tests lock the gate, navigation, canonical semantics, and the
  merge-preserving save.

### Scope

- Mode-aware Settings entry (presentation gate supplied by app composition).
- Nutrition Settings hub route.
- Nutrition Profile editor route with two purpose-specific editor sheets.

### Non-Goals

- Nutrition Targets (calories/macros) editing.
- Diet Plan, Meal Diary, Eating Style, Nutrition Approach.
- Onboarding's free-text "Other" elaborations (no canonical column exists).
- Any schema, RLS, RPC, or migration change. No backend service work.

## 2. Codebase Exploration

### Verified Evidence

- `NutritionProfileRepository.upsert` replaces the whole canonical row, so any
  partial write would clear `disliked_foods` and `medical_conditions`.
- `NutritionProfileData` uses nullable collections deliberately: `null` is
  unknown, `{}` is an explicitly answered "None".
- Onboarding's `nutrition_profile_mapper` never populates `dislikedFoods` or
  `medicalConditions`, and enforces None-exclusivity plus a non-empty answer.
- Onboarding's free-text `otherDietType` / `otherAllergyRestriction` live only
  in the local draft and have no canonical column.
- Settings is presentation/navigation only; domain features own business state
  and persistence.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Settings entry gated on canonical App Mode | Approved | Nutrition is a Nutrition/Hybrid capability |
| Nutrition feature owns its own selection vocabulary | Approved | Settings must never import Onboarding presentation |
| No free-text "Other" detail in V1 | Approved | No canonical column; writing it would be a silent data loss |
| Explicit merge on save (no `copyWith`) | Approved | `null` is meaningful, so a copy helper would hide intent |
| Hub shows only implemented capability | Approved | Placeholder rows advertise capability that does not exist |

## 4. Architecture Design

- `NutritionProfileVocabulary` (Nutrition domain) is the canonical owner-side
  list of selectable storage values and labels. `none` is deliberately absent.
- `NutritionSettingsPage` is a pure launcher.
- `NutritionProfileSettingsPage` renders summaries and opens one editor sheet
  per field. Each save rebuilds the full `NutritionProfileData`, changing one
  field and carrying every other field through verbatim.
- `apps/app` owns composition: the App Mode gate, the `nutritionProfileDataProvider`
  read, the loading/error/retry states, and provider invalidation after save.
- Parity between the Nutrition vocabulary and the Onboarding enums is asserted
  in `apps/app`, the only package that legitimately depends on both.

## 5. Implementation Plan

- [x] Add `NutritionProfileVocabulary` + `NutritionChoice`.
- [x] Add `NutritionSettingsPage` hub.
- [x] Add `NutritionProfileSettingsPage` with Diet Type and Allergies editors.
- [x] Add `nutritionSettings` and `nutritionProfileSettings` route contracts.
- [x] Add the gated `NUTRITION` section to `SettingsPage`.
- [x] Add `nutritionProfileDataProvider` and wire both routes in `router.dart`.
- [x] Add focused tests: gate, hub, editors, canonical semantics, data safety,
      route navigation, mode change, vocabulary parity.
- [x] `dart format`, `flutter analyze`, package test suites.
- [ ] CI on the exact PR head.
- [ ] Physical-device acceptance by the owner.

## 6. Quality Review

- `flutter analyze`: clean on `apps/core`, `apps/features/nutrition`,
  `apps/features/settings`, `apps/app`.
- Tests: nutrition 38, settings 175, core 116, app 263 — all passing locally.
- Data safety is covered at two levels: a widget test on the page's merge, and
  a route test asserting the repository received the untouched fields.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/nutrition-settings-profile-v1.md` (this file)
- `apps/core/lib/src/routing/routes/app_routes.dart`
- `apps/features/nutrition/lib/src/domain/models/nutrition_profile_vocabulary.dart`
- `apps/features/nutrition/lib/src/domain/models/models.dart`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_settings_page.dart`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_profile_settings_page.dart`
- `apps/features/nutrition/lib/src/presentation/pages/pages.dart`
- `apps/features/nutrition/lib/src/presentation/presentation.dart`
- `apps/features/settings/lib/src/presentation/pages/settings_page.dart`
- `apps/app/lib/app/network_providers.dart`
- `apps/app/lib/app/router.dart`
- `apps/features/nutrition/test/presentation/nutrition_settings_page_test.dart`
- `apps/features/nutrition/test/presentation/nutrition_profile_settings_page_test.dart`
- `apps/features/settings/test/presentation/settings_nutrition_entry_gating_test.dart`
- `apps/app/test/app/nutrition_profile_vocabulary_parity_test.dart`
- `apps/app/test/app/nutrition_settings_route_test.dart`

### Actual Behavior

Nutrition and Hybrid users see a `NUTRITION` section in Settings leading to a
Nutrition & Diet hub and a Nutrition Profile screen where Diet Type and
Allergies & Restrictions can be edited. Workout users see no Nutrition section.
Saving either field writes a fully merged canonical row.

**Current status:** IMPLEMENTED — local validation complete; CI and physical-device
acceptance pending.
