# Nutrition Settings V1 — Nutrition Profile Edit Parity

**Status:** Validated — CI green, migration applied, device acceptance PASS
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
- Any RLS or RPC change. No backend service work.

### Owner-approved extension (added after the initial slice was implemented)

The owner reviewed the editors and rejected offering "Other" without a way to
say what it means: a bare `other` records that an answer exists without
recording the answer, and for allergies it tells later diet planning that a
restriction exists without saying which — worse than storing nothing.

Investigating that surfaced an existing defect: Product Onboarding already
collects this text and discards it at completion, because no column existed.

The slice therefore grew by one additive migration and the free-text wiring on
both surfaces. This is the only scope expansion, and it was explicitly
approved.

## 2. Codebase Exploration

### Verified Evidence

- `NutritionProfileRepository.upsert` replaces the whole canonical row, so any
  partial write would clear `disliked_foods` and `medical_conditions`.
- `NutritionProfileData` uses nullable collections deliberately: `null` is
  unknown, `{}` is an explicitly answered "None".
- Onboarding's `nutrition_profile_mapper` never populates `dislikedFoods` or
  `medicalConditions`, and enforces None-exclusivity plus a non-empty answer.
- Onboarding's free-text `otherDietType` / `otherAllergyRestriction` lived only
  in the local draft and were dropped by `NutritionProfileMapper`, because no
  canonical column existed. This slice adds the columns and carries the text.
- `users.other_health_condition TEXT` is the established house pattern for this
  concept: one nullable TEXT column, blank stored as NULL. The new columns
  follow it rather than inventing a shape.
- That precedent also drops its `other` token when the text is blank. This
  slice deliberately does not: for a single-valued diet it would make "Other"
  unsaveable, and for allergies an empty set already means the positive answer
  "None", so dropping the token would silently change the user's answer.
- Settings is presentation/navigation only; domain features own business state
  and persistence.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Settings entry gated on canonical App Mode | Approved | Nutrition is a Nutrition/Hybrid capability |
| Nutrition feature owns its own selection vocabulary | Approved | Settings must never import Onboarding presentation |
| ~~No free-text "Other" detail in V1~~ | Superseded | Held only while no column existed. The owner ruled that "Other" without its text records nothing, so the columns were added instead |
| Keep the `other` token when its text is blank | Approved | Dropping it would make Diet Type unsaveable and would turn an answered allergy into "None" |
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
- [x] Add `other_diet_type` / `other_allergy_restriction` migration, model
      fields, adapter read/write, and the inline "Other" field in both editors.
- [x] Carry the onboarding free text through `NutritionProfileMapper`.
- [x] `dart format`, `flutter analyze`, package test suites.
- [x] CI on the exact PR head.
- [x] Apply the migration to hosted Supabase (owner-approved after the code's
      read began requesting the new columns and broke the app against it).
- [x] Physical-device acceptance by the owner — PASS.

## 6. Quality Review

- `flutter analyze`: clean on `apps/core`, `apps/features/nutrition`,
  `apps/features/settings`, `apps/features/onboarding`, `apps/app`.
- Tests: nutrition 52, onboarding 447, settings 175, core 116, app 264. CI runs
  analyze plus tests across every package via melos, and is green on the head.
- Data safety is covered at three levels: the page's merge, the adapter
  payload, and a route test asserting the repository received the untouched
  fields.

### Defects found during device acceptance, fixed here

- **Nutrition Profile would not load.** The adapter's `select` was extended to
  the new columns while the migration was deliberately deferred, so every read
  failed against hosted Supabase and surfaced as a connection error. Deferring
  the migration *was* the break: schema and reader had to ship together.
- **Save sat under the keyboard** in the taller Allergies sheet, and selecting
  "Other" left its field below the fold. Save is now pinned outside the scroll
  view, and the row scrolls itself into view as Product Onboarding already did.

### Known limitation, not fixed

A signed-out save surfaces "Couldn't save. Check your connection and try
again." although the real cause is authentication. The route sits behind the
session gate, so it should be unreachable; recorded rather than papered over.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/nutrition-settings-profile-v1.md` (this file)
- `supabase/migrations/20260831064841_add_nutrition_other_free_text.sql`
- `apps/features/nutrition/lib/src/domain/models/nutrition_profile_data.dart`
- `apps/features/nutrition/lib/src/data/repositories/supabase_nutrition_profile_repository.dart`
- `apps/features/onboarding/lib/src/domain/usecases/nutrition_profile_mapper.dart`
- `apps/features/onboarding/test/domain/nutrition_profile_mapper_test.dart`
- `apps/features/nutrition/test/data/supabase_canonical_nutrition_repositories_test.dart`
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
Choosing "Other" reveals a text field, and what the user types is stored and
shown back in place of the generic label. Saving either field writes a fully
merged canonical row.

### Follow-ups raised, deliberately not done here

- **TNYX-139** — selection cards are hand-rolled per surface, so App Mode
  Settings, Account Setup and this slice's editor tiles all differ. The owner
  ruled it an audit-first design-system effort rather than a patch here.
- `medical_conditions` and `disliked_foods` columns exist and no product flow
  writes either. `medical_conditions` is diet-plan-safety relevant.

**Current status:** VALIDATED — CI green, migration applied to hosted Supabase,
owner device acceptance PASS. Awaiting merge authorization.
