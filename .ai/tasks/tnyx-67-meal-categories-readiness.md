# TNYX-67 — Meal Type / Meal Categories Readiness

**Status:** In progress
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter Android + iOS; Supabase Postgres in a later separately approved persistence slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice; future Supabase column shape change; future product-visible UI/UX change
**Approval status:** Slice A approved; implementation started after owner review
**Approval evidence:** TNYX-67 owner-locked semantics updated 2026-09-06 and the 2026-09-06 TNYX-66 readiness-refresh request.
**Approved product/data direction:** Meal Category is separate from `MealLogEntry.mealName`; four resolved defaults; maximum eight active categories; stable non-semantic IDs; profile-owned nullable versioned JSONB direction.
**Explicit non-changes:** No Flutter UI, Supabase adapter/migration/live mutation, MealLog persistence, `services/api`, Weight, or Workout work. No Slice B, C, or D implementation.

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** Codex `/root`
**Review owner:** Owner review pending
**Implementation ownership state:** In progress — Slice A only
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-06 after `git fetch --prune`
**Branch:** `tnyx/tnyx-67-meal-categories-domain-config`
**Base SHA:** `8379067fed3527ebf8532eec3a9e5a072c32237f`
**Observed working-tree state:** Slice A implementation is staged on the fresh branch; the unrelated root `pubspec.lock` modification remains unstaged and excluded
**Observed uncommitted/dirty files:** `pubspec.lock` only outside the staged Slice A scope (pre-existing, preserve exactly)
**PR / tracker:** Zero open GitHub PRs; TNYX-67 moved to In Progress for Slice A; TNYX-66 remains Backlog
**Current implementation state:** Slice A domain/config/codec/policy, UUID-v4 ID generator, repository contract, in-memory implementation, exports, and focused tests are implemented locally. No UI, Supabase adapter/schema, or MealLog implementation exists.
**Relevant execution surface:** Nutrition domain/data; later Nutrition Meal Diary Settings and meal-logging presentation
**Validation completed at SHA:** Working tree on base `8379067f...`: scoped format check clean; Nutrition package analyzer clean; focused Slice A tests passed; full Nutrition package suite passed (`284` tests)
**Validation remaining:** Final staged diff/scope checks, commit/push, Draft PR, and exact-head GitHub CI
**Current blocker:** None for Slice A below. Later settings UI remains coupled to TNYX-68/N14 and its TNYX-54 dependency.
**Open review finding IDs:** None
**Next exact action:** Complete the exact staged scope audit, commit/push Slice A, open one focused Draft PR, and verify exact-head CI. Do not begin Slice B, C, or D.

## 1. Discovery

### User Outcome

Prepare one safe implementation sequence for TNYX-67 so Meal Type uses stable category identity, customization cannot exceed eight active categories, and later history survives rename/archive without conflating the category with the meal title.

### Success Criteria

- `NULL` configuration resolves exactly Breakfast, Lunch, Dinner, Snacks.
- Rename/reorder preserves category `id`; `defaultKey` remains separate from visible text.
- Custom IDs are generated independently from `displayName` and never reused.
- Every write boundary rejects malformed config and more than eight active items without truncation.
- Settings and pickers ultimately consume one repository/state owner.
- Archived categories remain retained/resolvable for future historical logs.

### Scope

Readiness evidence, owner contract, proposed ownership/data flow, rollout slices, validation plan, and exact first slice.

### Non-Goals

Supabase adapter or migration creation/application, UI/routes, MealLog schema/persistence, Meal Diary aggregation, reminders, targets, Weight, Workout, `services/api`, and Slice B/C/D implementation.

## 2. Codebase Exploration

### Verified Evidence

- Git: `main == origin/main == 8379067f...`; only pre-existing `pubspec.lock` is modified. Preserved local branch `docs/supabase-android-studio-qa-run == 7fe896820c8f176b5049df4fe84fc9acea5933b1`. Fresh GitHub search returned zero open PRs.
- Runtime: `apps/features/nutrition` owns domain/data/presentation. `apps/app` only composes providers/routes. No `MealCategory`, Meal Diary Settings route, category store, or generated Supabase model exists.
- Quick Add: `MealLogActionFooter` is already the Nutrition-owned reusable footer. Its Meal type control is disabled and intentionally neutral; the accepted Core `TioDateTimePickerPopup`/`TioDateTimeWheelPicker` path is independent and must remain untouched.
- Current settings: `NutritionSettingsPage` exposes Profile and Targets only. No primary Meal Diary More/Settings route or secondary Nutrition Settings shortcut exists.
- Current profile persistence: `NutritionProfileRepository.upsert()` is a whole-profile write used by Product Onboarding and Nutrition Profile Settings. Extending that payload directly with category config would risk clearing custom categories when an older/profile-only writer rebuilds the object.
- Safe persistence pattern: existing canonical repositories deliberately omit unrelated reserved columns so PostgREST conflict updates preserve them. Meal categories should use a column-scoped repository on the same table, not a duplicate storage location.
- Hosted Supabase project resolved fresh as `tio-world` (`oykupyiitspujzpwwvuj`, Postgres 17). `public.user_nutrition_profiles` has two rows, RLS enabled, owner-scoped SELECT/INSERT/UPDATE/DELETE policies, and no `meal_categories_config` column.
- Current table columns: `user_id`, `preferred_diet`, `allergies`, `disliked_foods`, `medical_conditions`, `updated_at`, `other_diet_type`, `other_allergy_restriction`. Primary key/FK is `user_id -> auth.users(id) ON DELETE CASCADE`.
- Grants currently include table privileges for `anon`, `authenticated`, and `service_role`; only `authenticated` has row policies, so RLS remains the user-ownership boundary. A future additive column should not change policies/RPCs.
- Local migration ownership matches hosted truth: table creation/policies in `20260815000002_create_tnyxhub_canonical_tables.sql`, legacy-owner cleanup in `20260824070233_cleanup_legacy_canonical_mirrors.sql`, and current free-text columns in `20260831064841_add_nutrition_other_free_text.sql`.
- JSONB precedent exists in `onboarding_drafts.payload`, `user_nutrition_targets.recommendation_metadata`, nullable `additional_nutrient_goals`, `body_weight_logs.metadata`, and `user_profiles.unit_preferences`. Persisted JSON keys use snake_case and versioned envelopes.
- `pg_jsonschema` is not installed. Built-in `jsonb_typeof`, `jsonb_array_length`, and `jsonb_path_query_array` are immutable on the hosted database. A read-only feasibility query counted 8, 9, and 8 active items correctly for eight-active, nine-active, and eight-active-plus-archived samples.
- Current Supabase guidance supports JSONB for small variable config but warns that relational modeling provides query/join/FK integrity. The owner explicitly accepts that trade-off for V1.
- Stale docs: `.ai/CURRENT.md` is an Onboarding O7 snapshot dated 2026-08-23. `docs/DEVELOPMENT_SETUP.md`, `docs/ROADMAP.md`, `docs/SUPABASE_STRATEGY.md`, and parts of `docs/MODULE_OWNERSHIP.md` still describe absent/future Supabase or `backend/*`; current `AGENTS.md`, `README.md`, and `docs/ARCHITECTURE.md` establish active `supabase/` and future `services/api` as canonical.

### Linear Dependency Truth

- TNYX-67 was Backlog during readiness and is now In Progress for the approved Slice A. It remains blocked by TNYX-66 and continues to block TNYX-71; no dependency relation was changed.
- TNYX-68/N14 owns the full Meal Diary Settings surface and is blocked by TNYX-66 plus TNYX-54/N1. Therefore category domain/persistence foundations can proceed first, while the settings UI waits for its own dependency readiness.
- TNYX-57 owns dynamic Diary sections and uses resolvable category labels; it is blocked by TNYX-54. TNYX-58 is then blocked by TNYX-57.
- TNYX-113 owns the future physical MealLog aggregate and is blocked by TNYX-54/TNYX-66. TNYX-115 depends on TNYX-113/TNYX-114. None is implemented here.
- TNYX-158 is Done and supplies the current Quick Add shell; its neutral category control is the future picker consumer.

## 3. Clarification

### Locked Contract

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| `MealCategory` is not `MealLogEntry.mealName` | Locked | Category/slot and actual meal title have different identity/lifecycle | Owner / TNYX-67 |
| Defaults | Locked | `meal_slot_1..4` with `breakfast/lunch/dinner/snacks` and visible Breakfast/Lunch/Dinner/Snacks | Owner / TNYX-67 |
| Active limit | Locked | `MAX_ACTIVE_MEAL_CATEGORIES = 8`; archived retained items do not count | Owner / TNYX-67 |
| Persistence | Preferred V1 | Nullable versioned JSONB on `user_nutrition_profiles`; `NULL` resolves defaults; persist full config only after customization | Owner + audit evidence |
| Repository ownership | Chosen | A column-scoped `MealCategoriesRepository` uses the same row/column owner while profile-only writers omit and preserve it | Nutrition |
| Custom ID generation | Chosen | Injected generator emits lowercase UUID v4 suffixes as `meal_slot_<uuid>`; collision-check against every retained ID and retry; never derive from text or reuse archived IDs | Nutrition |
| Storage keys | Chosen | Domain uses Dart camelCase; JSONB uses repository-standard snake_case such as `schema_version`, `default_key`, `display_name` | Nutrition |
| Unsupported future schema | Chosen | Fail closed on `schema_version > 1`; never coerce/truncate/write it back through a V1 editor | Nutrition |
| Duplicate names | Chosen | Store trimmed visible text; reject blank and duplicate normalized names using trimmed, collapsed-whitespace, case-insensitive comparison; do not invent a short length cap | Nutrition |
| Restore Defaults | Deferred from Slice A | Exact treatment of custom/archived items is a later owner-visible UI decision; not needed to establish identity/config correctness | TNYX-68 UI slice |

## 4. Architecture Design

### Domain Contract

```text
MealCategory {
  id            // immutable opaque slot ID
  defaultKey?   // breakfast | lunch | dinner | snacks; null for custom
  displayName   // trimmed user-visible label
  active        // selectable for new logs
  order         // Settings/picker order only
}
```

- Rename changes only `displayName`; reorder changes only `order`.
- Active order must be deterministic; archived items may retain their last order but do not consume an active slot.
- Reactivation must revalidate the active limit and duplicate-name rule.
- Archive retains the full item. Hard delete/ID reuse is forbidden once history may refer to it.

### Resolved Defaults and JSONB

```text
meal_categories_config IS NULL
  -> resolve the four canonical defaults in memory

meaningful customization
  -> persist one complete V1 envelope
     {"schema_version":1,"items":[...]}
```

The codec must reject malformed envelope/item types, duplicate IDs/default keys, invalid default mappings, blank/duplicate names, negative/ambiguous active order, and more than eight active items. It must never silently truncate.

### Ownership and Data Flow

```text
Meal Categories UI / Meal type picker
  -> controller/notifier
  -> MealCategory policy/config codec
  -> MealCategoriesRepository
  -> column-scoped Supabase gateway
  -> public.user_nutrition_profiles.meal_categories_config
```

The existing `NutritionProfileRepository` remains responsible for profile context and continues omitting the category column. This is one physical store with two narrow contracts, not duplicate persistence.

### JSONB vs Normalized Table

**Preferred V1: JSONB.** It is a small user-owned configuration, has at most eight active choices, requires no cross-user query or category join in V1, matches current versioned JSONB conventions, and avoids premature table/RLS/lifecycle complexity.

A PostgreSQL FK cannot target an object inside JSONB. Future `MealLogEntry.mealCategoryId` integrity therefore depends on Nutrition domain/repository validation: new logs require an active resolved ID; edits/history may retain a resolved archived ID; archive never remaps; missing IDs fail rather than falling back. TNYX-113 retains ownership of the future physical MealLog schema. Reconsider normalization only if real reporting/query/FK requirements outgrow this boundary.

### Database-Side Limit Feasibility

A later migration can add a CHECK-compatible built-in JSONB/JSONPath validation expression, or a narrowly scoped immutable validator used by a CHECK, to validate the V1 envelope/items and enforce active count `<= 8`. No `pg_jsonschema` dependency is required. Exact SQL remains for the migration slice and must be tested against malformed booleans/types, 8/9 active items, and archived extras.

## 5. Proposed Implementation Order

1. **Slice A — implemented locally:** repository-neutral `MealCategory`/config/codec/policy, injectable UUID-v4 slot ID generation, `MealCategoriesRepository` contract, in-memory implementation, and pure tests. No schema or UI.
2. **Slice B — separately approved Supabase persistence:** additive nullable `meal_categories_config jsonb`, database validation, column-scoped Supabase adapter, old-client/profile-writer preservation tests, migration/app rollout ordering, and read/write/RLS verification. No UI.
3. **Slice C — TNYX-68 dependency-gated UI:** one Meal Diary Settings route/state, Meal Categories management, primary Diary entry and secondary Nutrition Settings shortcut. No duplicate store.
4. **Slice D — picker consumption:** enable the existing Quick Add/full Meal Editor Meal type control against the same state; show active options for new selection and retain archived selection in edit mode. Leave DateTime wheel untouched.

Do not bundle all slices automatically into one PR.

## 6. Required Validation Plan

- Defaults: `NULL` -> exactly four defaults with exact IDs/default keys/names/order.
- Identity: rename/reorder preserve ID; default key stays separate; custom ID is UUID-based, text-independent, collision-safe, and never reused.
- Validation: 8 active accepted; ninth/reactivation rejected; archived item frees a slot; malformed/duplicate/blank/whitespace config rejected without truncation.
- Repository: signed-out writes fail closed; profile-only/onboarding upserts preserve config; supported V1 round-trip is lossless; future schema fails closed.
- Database slice: object/array/item shape checks; 8 accepted; 9 rejected; archived extra accepted; RLS owner isolation; existing policies/RPCs unchanged.
- History boundary: archived category resolves; archive never remaps; missing ID fails; ID reuse forbidden.
- Picker: only active options for new selection; rename/add appear after state refresh; archived disappears for new selection; historical edit retains archived selection.
- Settings: both entry paths reach one route/provider; no duplicate store; Add is disabled with a reason at eight.
- Theme/a11y UI slice: Light/Dark/OLED/System, long names, large text, focus/semantics, and duplicate/blank error messaging.
- Regression: existing Quick Add DateTime popup/wheel behavior and tests remain unchanged.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-67-meal-categories-readiness.md`
- `apps/features/nutrition/lib/src/domain/models/meal_*` plus the models barrel
- `apps/features/nutrition/lib/src/domain/usecases/meal_category_id_generator.dart` plus the usecases barrel
- `apps/features/nutrition/lib/src/domain/repositories/meal_categories_repository.dart` plus the repositories barrel
- `apps/features/nutrition/lib/src/data/in_memory_meal_categories_repository.dart` plus the data barrel
- `apps/features/nutrition/pubspec.yaml` and its package-local lockfile for the existing approved `uuid` package
- focused Meal Categories domain/codec/in-memory repository tests

### Actual Behavior

Slice A now provides a pure repository-neutral Meal Categories foundation. Absent customization resolves four canonical defaults; strict validation rejects malformed/ambiguous identity, ordering, duplicate active labels, unsupported versions, and more than eight active categories; archived identities remain retained/resolvable; the in-memory owner validates before accepting writes.

The V1 codec uses `schema_version`, `default_key`, and `display_name` storage keys, accepts absent/null `default_key` for custom items, and never infers identity from labels or order. Production custom IDs use `meal_slot_<lowercase-uuid-v4>` with injected generation, collision retry, and retained-ID protection.

### Known Limitations

- Slice B needs separate owner authorization for the exact column/migration and any hosted apply.
- Slice C remains dependency-gated by TNYX-68/TNYX-54 and needs owner-approved visible UI behavior, including exact Restore Defaults semantics.
- TNYX-113 owns the future physical MealLog schema and database referential-integrity decision.

### Final Status

`PASS` locally for Slice A — formatting, analyzer, focused tests, and full Nutrition package tests pass. Draft PR/exact-head CI remain the handoff gates; later slices remain unimplemented.
