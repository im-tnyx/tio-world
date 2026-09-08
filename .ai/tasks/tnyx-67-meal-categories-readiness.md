# TNYX-67 — Meal Type / Meal Categories Readiness

**Status:** Blocked
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter Android + iOS Nutrition presentation readiness for Slice C; production behavior and hosted Supabase are unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice; future Supabase column shape change; future product-visible UI/UX change
**Approval status:** Slice A, Slice B1, and Slice B2 are closed. The current authorization is readiness/documentation only; Slice C/D remain unapproved and unstarted.
**Approval evidence:** TNYX-67 owner-locked semantics updated 2026-09-06; prior Slice A/B1/B2 authorizations and closeouts; and the 2026-09-08 explicit Slice C readiness-only instruction.
**Approved product/data direction:** Meal Category is separate from `MealLogEntry.mealName`; four resolved defaults; maximum eight active categories; stable non-semantic IDs; profile-owned nullable versioned JSONB direction.
**Explicit non-changes:** No Flutter production source/tests, UI, route, Quick Add/Meal Editor activation, MealLog persistence, `services/api`, Weight, Workout, Slice C/D implementation, migration/SQL, schema/RLS/RPC/index/timestamp change, hosted Supabase mutation, Docker, or local/backend service work.

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** None — Slice C implementation is not authorized and is dependency-blocked
**Review owner:** None — this is a readiness-only audit
**Implementation ownership state:** Slice A closed; Slice B1 merged/hosted/verified; Slice B2 merged/post-merge validated; Slice C/D unstarted
**Ownership transition:** B2 ownership closed after PR #224 squash merge; current work returned to readiness-only planning on 2026-09-08
**Repository state last verified:** 2026-09-08 after fresh Git/GitHub/Linear/Supabase read-only verification
**Branch:** `main`
**Base SHA:** `3d0b415fde1be8b62aa5002990fbdfe4fa226ace`
**Observed working-tree state:** `main == origin/main`; only the unrelated root `pubspec.lock` and this authorized task-brief reconciliation are modified locally
**Observed uncommitted/dirty files:** pre-existing `pubspec.lock` with SHA-256 `004DE1A093C1F04F684B39DF072C2F2E37B1CD21046BFEE01E628E7F77300B1C`, plus this authorized task-brief update only
**PR / tracker:** PR #218/#219/#220/#221/#222/#223/#224 are merged. No open overlapping Meal Categories UI PR exists. TNYX-67 remains `In Progress` and blocked by TNYX-66; TNYX-66/TNYX-68/TNYX-54 remain `Backlog` with their dependency relations unchanged.
**Current implementation state:** Slice A is closed; Slice B1 is merged, hosted-applied, and verified; Slice B2 is merged and post-merge validated. The TNYX-68 shell that Slice C depended on is merged at `5f06a72b3a1404b1d315ee987c281605d706b738`, so the Section 13 blocker is cleared. Slice C/D remain unstarted.
**Relevant execution surface:** Future Nutrition-owned Meal Diary Settings and Meal Categories presentation, with app-owned route/top-bar composition and the existing Meal Categories repository boundary
**Validation completed:** Slice A validation remains green. Slice B1 repository/hosted evidence remains verified at 40 migrations. Slice B2 PR #224 was squash-merged at `3d0b415fde1be8b62aa5002990fbdfe4fa226ace`, and post-merge Flutter CI run `34175515202` passed on that SHA. The 2026-09-08 hosted prerequisite recheck was read-only and reconfirmed the B1 column/CHECK/functions/trigger/RLS policies and two preserved rows.
**Validation remaining:** None for readiness. Slice C implementation and its own validation have not started.
**Current blocker:** None. Archived presentation is owner-locked to Option A; the route, entries, domain, repository and provider Slice C needs all exist in `main`.
**Resolved review finding IDs:** `3949432003`, `3949432006`, `3949432012`, and `3949432017` are fixed, exact-head validated, replied, and resolved. PR #222 Codex P2 `3950154215` identified stale hosted-state wording; this correction incorporates that finding.
**Next exact action:** Start Slice C into the existing Meal Categories destination as one named slice. Do not start Slice D or any consumer activation automatically.

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

1. **Slice A — validated / handoff complete:** repository-neutral `MealCategory`/config/codec/policy, injectable UUID-v4 slot ID generation, `MealCategoriesRepository` contract, in-memory implementation, and pure tests. No schema or UI.
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

### Post-Merge P1 Follow-Up

PR #218 merged the Slice A foundation to `main` as `5d9f6371409e2d9f057c035b267b496cf85de2ab`. Post-merge Codex review comment `3944690722` correctly identified that `InMemoryMealCategoriesRepository.upsert()` could replace customized state with an otherwise-valid config that omitted an existing custom ID. That made an archived identity unavailable for future historical lookup and removed it from the retained-ID collision set. PR #219 merged the follow-up fix to `main` as `dd0c0e3d6efeaec18e525ebf113a4435e0abdf1a`.

The follow-up adds one reusable transition policy: for ordinary upsert, `previousIds - nextIds` must be empty. Missing retained IDs are rejected with `MealCategoriesValidationCode.retainedIdentityRemoved`; the previous repository state remains unchanged because assignment occurs only after config and transition validation. Rename, reorder, archive, and valid reactivation remain supported. Initial `null`/absent customization to first customized config remains valid and does not materialize extra implicit state.

This is not a delete/reset API. Restore Defaults and future durable tombstone behavior remain intentionally deferred and must preserve historically referenced identities/tombstones. Slice A is closed, merged, and post-merge validated. Slice B, C, and D remain unstarted.

Follow-up validation: the regression test failed on the merged implementation before the fix; changed Dart files are formatted; Nutrition analyzer passed with fatal infos; the focused Meal Categories suite passed `48/48`; the full Nutrition package suite passed `301/301`; and post-merge `main` Flutter CI run `34072455019` passed at `dd0c0e3d6efeaec18e525ebf113a4435e0abdf1a`.

### Changed Files

- `.ai/tasks/tnyx-67-meal-categories-readiness.md`
- `apps/features/nutrition/lib/src/domain/models/meal_*` plus the models barrel
- `apps/features/nutrition/lib/src/domain/usecases/meal_category_id_generator.dart` plus the usecases barrel
- `apps/features/nutrition/lib/src/domain/repositories/meal_categories_repository.dart` plus the repositories barrel
- `apps/features/nutrition/lib/src/data/in_memory_meal_categories_repository.dart` plus the data barrel
- `apps/features/nutrition/pubspec.yaml` and its package-local lockfile for the existing approved `uuid` package
- focused Meal Categories domain/codec/in-memory repository tests

### Actual Behavior

Slice A now provides a pure repository-neutral Meal Categories foundation. Absent customization resolves four canonical defaults; configs validate at construction and store deterministic semantic order; strict validation rejects malformed/ambiguous identity, ordering, duplicate active labels, unsupported versions, and more than eight active categories; archived identities remain retained/resolvable; the in-memory owner validates before accepting writes.

The V1 codec uses `schema_version`, `default_key`, and `display_name` storage keys, accepts absent/null `default_key` for custom items, and never infers identity from labels or order. Production custom IDs use `meal_slot_<lowercase-uuid-v4>` with injected generation, collision retry, and retained-ID protection.

Slice A intentionally exposes no destructive reset/clear method. Restore Defaults remains a later owner-visible decision and must preserve retained custom identities or use explicit tombstone semantics before historical MealLogs can reference them.

### Known Limitations

- Slice B needs separate owner authorization for the exact column/migration and any hosted apply.
- Slice C remains dependency-gated by TNYX-68/TNYX-54 and needs owner approval for the exact visible archived-category presentation. Restore Defaults is excluded from the initial Slice C and remains a separate future historical-safety decision.
- TNYX-113 owns the future physical MealLog schema and database referential-integrity decision.

### Final Status

`CLOSED / MERGED / POST-MERGE VALIDATED` for Slice A — PR #218 merged the foundation, PR #219 resolved the retained-identity P1 on `main` at `dd0c0e3d6efeaec18e525ebf113a4435e0abdf1a`, and post-merge Flutter CI run `34072455019` passed. TNYX-67 remains In Progress; TNYX-66 is unchanged; Slice B, C, and D are not started.

## 8. Slice B Readiness Refresh — 2026-09-07

### Fresh Baseline and Tracker Reconciliation

- Baseline: `main == origin/main == 1f31153543c20fd44a42b84f4defe897e0d48a2d`; PR #218/#219/#220 are merged and no open overlapping PR exists.
- Preserved local branch: `docs/supabase-android-studio-qa-run == 7fe896820c8f176b5049df4fe84fc9acea5933b1`.
- Pre-existing root `pubspec.lock` remains unstaged with SHA-256 `004DE1A093C1F04F684B39DF072C2F2E37B1CD21046BFEE01E628E7F77300B1C`.
- Fresh Linear initially showed TNYX-67 `Done`; the readiness authorization was used to correct only its status to `In Progress`. Its `blockedBy TNYX-66` relation is unchanged. TNYX-66 remains Backlog; TNYX-68 and TNYX-113 remain Backlog and blocked by TNYX-66 plus TNYX-54.

### Hosted Schema, RLS, Grants, and Migration Truth

- Hosted project `tio-world` (`oykupyiitspujzpwwvuj`) is healthy on PostgreSQL 17.6.1. `public.user_nutrition_profiles` has two rows and no `meal_categories_config` column.
- Current columns are `user_id`, `preferred_diet`, `allergies`, `disliked_foods`, `medical_conditions`, `updated_at`, `other_diet_type`, and `other_allergy_restriction`. Only `user_id` is non-null; it is the primary key and references `auth.users(id) ON DELETE CASCADE`. Therefore a first customization can insert only `user_id` plus the new nullable JSONB column without fabricating profile values.
- RLS is enabled. Authenticated owner policies exist for SELECT, INSERT, UPDATE, and DELETE; UPDATE has both `USING (auth.uid() = user_id)` and `WITH CHECK (auth.uid() = user_id)`. Table grants exist for `anon`, `authenticated`, and `service_role`, but only authenticated owner policies expose rows through the Data API. No custom table trigger exists. The primary-key index plus a redundant `user_id` btree index exist; Slice B needs no new index.
- Local and hosted migration ledgers match exactly at 39 migrations. Latest is `20260903091350_add_nutrition_additional_nutrient_goals`. `pg_jsonschema` is available but not installed and is not required.

### JSONB and Repository Ownership

- The accepted store remains one nullable `public.user_nutrition_profiles.meal_categories_config jsonb` column. `NULL` resolves canonical defaults in Dart; defaults are not eagerly persisted. A meaningful customization stores the complete existing V1 codec envelope with `schema_version` and `items` using the current snake_case item keys.
- `NutritionProfileRepository` continues selecting/writing only profile fields and omitting `meal_categories_config`. `MealCategoriesRepository` owns only that column over the same physical row. Existing PostgREST `upsert` payloads update the columns supplied on conflict, so profile-only writers preserve the new column; this remains a required integration test. No generated Supabase type system exists or is introduced.
- Unsupported or malformed non-null config fails closed through the existing `MealCategoriesConfigCodec`; it is never downgraded, defaulted, merged, truncated, or overwritten.

### Database Validation Boundary

The database independently rejects direct-write shapes that could undermine persistence or retained-identity safety:

- non-null payload is a V1 object with only the supported envelope keys;
- `schema_version` is the exact supported integer representation;
- `items` is an array whose members are objects with required `id`, `display_name`, `active`, and `order` fields and only the optional `default_key` addition;
- required field types are valid, `default_key` is null or a supported string, and order is a non-negative integer;
- IDs and orders are unique; IDs use one of the four canonical IDs or the V1 UUID-v4 slot format;
- all four canonical IDs/default-key mappings are present exactly once;
- every `active` value is boolean and active count is at most eight, so a malformed value cannot bypass the cap;
- no silent truncation occurs.

Dart remains the owner of normalized display-name semantics, whitespace/case-insensitive duplicate-name checks, rich deterministic validation codes/messages, immutable models, ordering behavior, and future-schema fail-closed UX. The database need not reproduce those rich app errors or duplicate-label normalization.

### Retained-Identity Atomicity Decision

Plain client `SELECT -> validateTransition -> upsert` is rejected because it races across devices. B1 uses a fail-closed migration to create a schema-qualified, `SECURITY INVOKER` row-level `BEFORE UPDATE OF meal_categories_config` trigger. It compares the row-locked current `OLD` config with `NEW` and rejects every `OLD` ID absent from `NEW`.

- `OLD NULL -> NEW valid non-null` is allowed; INSERT is validated by the CHECK boundary.
- `OLD non-null -> NEW NULL` is rejected because ordinary upsert is not Restore Defaults.
- `OLD/NEW non-null` permits rename, reorder, archive, and valid reactivation while rejecting identity removal.
- PostgreSQL row locking and atomic `ON CONFLICT DO UPDATE` ensure that a stale concurrent writer is checked against the latest committed row version. It fails rather than removing an identity introduced by another writer.
- The helper functions live in the existing non-exposed `private` schema, use explicit safe `search_path` and schema-qualified references, and remain `SECURITY INVOKER`. Grant only the namespace/function execution needed for PostgreSQL to maintain the CHECK/trigger for current write roles; add no public RPC, service-role client requirement, bypass, or `SECURITY DEFINER`. Remove only the authenticated standalone Nutrition Profile DELETE policy so a row cannot be recreated to erase retained identities; the canonical account-deletion RPC and FK cascade remain authoritative.

Optimistic revision state is unnecessary additional schema for this invariant. An atomic RPC would duplicate the normal Data API/RLS write path and add avoidable exposure/authorization surface. The trigger protects direct writes as well as the production adapter.

### Selected B1 Migration Design

- Add nullable, no-default `meal_categories_config JSONB` and a column comment.
- Add immutable `private.is_valid_meal_categories_config_v1(jsonb)` and CHECK `user_nutrition_profiles_meal_categories_config_valid`; fail closed if reserved objects already exist instead of silently accepting an unknown contract.
- Add `private.protect_meal_category_retained_ids()` as a schema-qualified `SECURITY INVOKER` trigger function and `trg_user_nutrition_profiles_protect_meal_category_retained_ids` as the `BEFORE UPDATE OF meal_categories_config` trigger, with the same fail-closed collision preflight.
- Drop only `user_nutrition_profiles_delete_own`; add no RLS policy and make no table-grant change. Add only the minimum validator `EXECUTE` grant required for `SECURITY INVOKER` CHECK/trigger evaluation; add no public RPC, index, second timestamp/revision column, backfill, or default-row materialization.
- Leave `updated_at` unchanged: the current table has no update trigger and profile writers omit it. B1 does not broaden profile timestamp semantics; the category adapter also omits it.
- Forward rollback policy is app-first: stop category writes while preserving the additive column/data and repair with a new forward migration. Dropping the guard/column after release would be destructive and requires separate authorization.

### Proposed B2 Adapter Contract — Design Only

`SupabaseMealCategoriesRepository` (repo-convention equivalent) stays in Nutrition data and implements the existing domain contract:

- signed-out read performs no remote access and resolves canonical defaults consistently with the nullable-read pattern; signed-out write fails before gateway access;
- read selects only `meal_categories_config`; missing row or null resolves defaults; non-null decodes only through `MealCategoriesConfigCodec` and fails closed on malformed/future data;
- upsert validates through Slice A, then sends only `user_id` and encoded `meal_categories_config` using the existing primary-key conflict path; it never touches profile fields or `updated_at`;
- DB CHECK plus the retained-ID trigger are the authoritative atomic persistence boundary. The client never silently merges, truncates, or treats a read-before-write check as concurrency protection.

### Rollout and Validation Plan

1. After separate authorization, implement/review B1 migration only.
2. Obtain separate explicit authorization before hosted apply; apply B1, then verify column, CHECK, trigger, the deliberate removal of only the standalone DELETE policy, unchanged table grants, and owner/anon isolation.
3. Only after hosted schema verification, implement B2 adapter and focused app/gateway tests; release clients after the database accepts the column.

Required DB tests: existing rows unchanged; null, valid four-default, eight-active, eight-active-plus-archived, and a large archived set accepted; nine-active, non-object, wrong schema type/value, malformed active type, invalid structural fields, duplicate IDs/orders, and invalid canonical mapping rejected; retained-ID removal and non-null-to-null rejected; rename/reorder/archive/reactivation within the cap accepted; stale concurrent writer cannot remove a newly committed identity; owner/other-user/anon standalone DELETE affects no rows; DELETE-to-reinsert cannot erase identities; canonical account deletion still cascades; validator `EXECUTE` necessity is proven; user A owns only A, user B is isolated, and anon sees/writes none.

Required app tests: signed-out behavior; missing row/null defaults; strict V1 round-trip; malformed/future schema failure; category-only existing-row update preserves profile fields; first-write insert fabricates no profile values; profile/onboarding writers preserve category config; gateway payload excludes profile fields and `updated_at`; DB rejection propagates without fallback/overwrite.

### Slice B Readiness Classification

`READY — Slice B1: additive meal_categories_config migration + DB validation/retained-ID guard only.`

B2 remains a later Flutter adapter slice after owner-authorized hosted rollout and verification. At the readiness-refresh gate this result authorized neither implementation nor hosted apply; the later explicit B1 authorization is recorded in Section 9 and still does not authorize hosted apply. Slice C/D, UI, Quick Add activation, and MealLog persistence remain out of scope.

## 9. Slice B1 Repository Implementation — 2026-09-07

### Implementation State

- Owner authorization now covers Slice B1 repository implementation and one Draft PR only. Hosted apply remains explicitly unauthorized.
- Exact base: `1f31153543c20fd44a42b84f4defe897e0d48a2d`.
- Branch: `tnyx/tnyx-67-meal-categories-db-guards`.
- CLI-generated migration: `supabase/migrations/20260907065602_add_meal_categories_config.sql`.
- Repository implementation and its validation harness are authored. This machine cannot currently run Docker because firmware virtualization is disabled and a reboot is deferred; the owner therefore authorized the mandatory disposable PostgreSQL/Supabase validation on GitHub Actions `ubuntu-latest`, without installing or starting a backend service here.

### Database Objects and Boundaries

- Adds nullable, no-default, no-backfill `public.user_nutrition_profiles.meal_categories_config jsonb` plus a column comment documenting default resolution, retained historical identity, and the maximum of eight active categories.
- Adds immutable, strict, `SECURITY INVOKER` `private.is_valid_meal_categories_config_v1(jsonb)` with `search_path = ''`. It performs no table reads and validates the exact V1 envelope, item types/keys, stable canonical/custom identity, set-based unique IDs/orders, non-negative integer order, canonical mappings, and active count at most eight. Archived retained items remain uncapped.
- Adds `user_nutrition_profiles_meal_categories_config_valid`, accepting SQL `NULL` or a validator-approved V1 payload.
- Adds `SECURITY INVOKER` `private.protect_meal_category_retained_ids()` and `trg_user_nutrition_profiles_protect_meal_category_retained_ids` as a row-level `BEFORE UPDATE OF meal_categories_config` trigger. It rejects non-null-to-null reset and removal of any previously retained canonical, custom, or archived ID.
- Revokes default execution from `PUBLIC`, `anon`, `authenticated`, and `service_role`. Grants only validator `EXECUTE` to existing write roles `authenticated` and `service_role`; a disposable regression proves authenticated guarded writes fail without it. The trigger function remains non-callable. The existing `private` schema is not exposed through the configured Data API schemas. No table grant, public RPC, index, unrelated profile column, or `updated_at` behavior changes.
- Deliberately drops only `user_nutrition_profiles_delete_own`. Ordinary authenticated clients can no longer hard-delete the Nutrition Profile and recreate it to erase retained IDs. The canonical `public.delete_user_account()` `SECURITY DEFINER` RPC still deletes `auth.users`, and the existing `user_nutrition_profiles.user_id -> auth.users.id ON DELETE CASCADE` path remains intact.
- Database validation deliberately stops at persistence shape/invariants. Dart remains responsible for display-name normalization, normalized duplicate-label semantics, deterministic app-facing validation errors, and future-schema UX.

### Verification State

- Completed before push: Supabase CLI `2.116.0` official Windows archive checksum verification; CLI login/project visibility; current CLI `--help` discovery; fresh hosted read-only verification of 39 migrations/latest `20260903091350`, absent column/trigger, enabled owner RLS policies, and existing `private` schema; migration/workflow static whitespace checks; concurrency script Bash syntax check.
- Authored CI validation: initialize a disposable Supabase Postgres base; replay each original repository migration file in its own transaction; record the local ledger through Supabase CLI; capture the pre-B1 lint baseline; reinitialize and replay the complete history; compare repository filenames to the ledger dynamically and assert B1 appears exactly once; run exhaustive accepted/rejected SQL table writes, large archived-set validation, authenticated/anon RLS and privilege proof, standalone DELETE denial, DELETE-to-reinsert denial, canonical account-deletion cascade, first-row write, profile-only upsert preservation, deterministic real two-session stale-writer rejection, later preserving update, and baseline/current `db lint` comparison for B1-introduced errors.
- Draft PR #221 first run `34116102725` failed before B1 execution because the historical `20260824070233_cleanup_legacy_canonical_mirrors.sql` begins with `LOCK TABLE` and current CLI startup submitted it outside a transaction. The applied historical migration remains unchanged; the bounded CI fix starts without repository migrations and replays the original files with `psql --single-transaction`, then uses Supabase CLI to populate and verify the disposable ledger.
- Run `34116667734` then passed base initialization, baseline replay/lint, clean full replay, exact 40-migration ledger parity, and Data API exposure check. Its SQL matrix reached the authenticated-role cases and exposed a test-harness-only permission gap: the switched role could not read the transaction-local fixture table. The fixture now grants read-only access only to the test roles inside the rolled-back test transaction; production grants remain unchanged.
- Run `34116951958` passed at exact implementation head `cfa219ce67c42f588e71d1402b2ac95651c928c9`. Job `101725903752` completed every required step successfully: baseline replay/lint, clean full replay, exact 40-migration ledger, private-schema exposure check, exhaustive SQL matrix, real two-session concurrency, and no B1-introduced database lint errors.
- PR run `34117316914` and manual run `34117336350` both passed at evidence head `5167122937c79134dc4bf780e909b4088f9a355a`; every required database step was green again.
- Hosted project `oykupyiitspujzpwwvuj` was rechecked read-only after CI and remains unchanged: 39 migrations with latest `20260903091350`, two Nutrition Profile rows, no `meal_categories_config`/B1 functions/trigger, RLS enabled, and the same four authenticated owner policies.
- PR #221 is open and marked ready for review. TNYX-67 remains In Progress with its TNYX-66 blocker relation unchanged; TNYX-66 remains Backlog. Linear follow-up comment `de439b70-2018-4967-b75f-d07ca4efe811` records the handoff.
- Slice B2, Flutter production source, UI, Quick Add, MealLog persistence, and Slice C/D remain unstarted.

### Post-CI P1 Remediation

- Review `3949432003`: removed the hard-coded total migration count from the reusable SQL matrix. The workflow's repository-file-to-ledger comparison remains dynamic, and the SQL matrix now requires B1 version `20260907065602` exactly once.
- Review `3949432006`: repository audit found no direct standalone Nutrition Profile delete in Flutter/Dart; the only product deletion path is `SupabaseAccountDeletionRpcGateway -> public.delete_user_account()`. B1 now drops only `user_nutrition_profiles_delete_own`, while disposable tests prove owner, other-user, and anon direct deletes affect zero rows, DELETE-to-reinsert cannot erase retained identities, and canonical account deletion still removes the profile through the existing FK cascade.
- Review `3949432012`: replaced repeated `array_position` scans with set-based `jsonb_array_elements + GROUP BY + HAVING count(*) > 1` checks for IDs and orders, and uses set difference for retained-ID comparison instead of nested scans. No total retained-item cap was added; a 512-item archived regression is accepted and a duplicate inside that large set is rejected.
- Review `3949432017`: clarified the exact grant boundary. No table grants are changed, no public RPC is added, and the only function grant is private validator `EXECUTE` for `authenticated` and `service_role`; a disposable revoke/guarded-write regression proves authenticated evaluation requires it. The trigger function remains non-direct-callable.
- Exact-head run `34120463118` passed clean full migration replay, dynamic ledger parity, and private-schema exposure before the SQL matrix found a test-helper-only syntax error: `COALESCE` is a SQL special form and cannot be schema-qualified as `pg_catalog.coalesce`. The helper was corrected without changing the production migration contract; a new exact-head run is required.
- Run `34120860985` passed at exact P1-remediation implementation head `bf31923d4ab8ea59256536ad467cc81ef21d609f`: clean full migration replay, dynamic ledger parity, B1 exactly once, private helper exposure, the complete SQL/RLS/DELETE/account-cascade/large-archived matrix, real two-session concurrency, and no B1-introduced lint errors.
- Hosted project `oykupyiitspujzpwwvuj` was rechecked read-only after exact-head run `34121248320` and remains unchanged: 39 migrations with latest `20260903091350`, two Nutrition Profile rows, no `meal_categories_config`, no B1 validator/trigger function or trigger, RLS enabled, and the same four hosted owner policies including the still-unapplied DELETE policy.
- Evidence replies `3949676238`, `3949676833`, `3949677540`, and `3949678241` were posted against findings `3949432003`, `3949432006`, `3949432012`, and `3949432017`; all four review threads were then re-fetched and verified resolved.
- Independent final review covered intent/scope, SQL correctness, RLS and grants, account-deletion cascade, DELETE bypass prevention, set-oriented validation complexity, large archived payloads, migration replay/ledger behavior, and real concurrency. It found no remaining P1/P2 issue.

### Slice B1 Final Classification

`B1 REPOSITORY MERGED / VALIDATED; HOSTED ROLLOUT APPLIED / VERIFIED` — PR #221 is squash-merged at main SHA `d66779a48f9a1a4042c6d4acc379059e12e1a9fc`; hosted project `oykupyiitspujzpwwvuj` contains migration `20260907065602_add_meal_categories_config` exactly once with the reviewed column, CHECK, private validator, retained-ID trigger, grants, and RLS policy hardening verified. B2/C/D remain unstarted.

## 10. Slice B1 Hosted Rollout — 2026-09-07

### Apply Evidence

- Fresh preflight verified `main == origin/main == d66779a48f9a1a4042c6d4acc379059e12e1a9fc`, PR #221 merged from reviewed head `1208c3b5143ddf9699bce466edbc53eb8e02ab8d`, and all four P1 review threads resolved.
- The reviewed-head and merged-main migration blobs both resolve to Git blob `5cfe8d6c3b7513d3c5746c874b2d55560dc0a637`; local SHA-256 is `AF8CED3CC1EC9E20EBC43DDA4C1E69A347FEF6F6B9937501EDA9840C9B230247`.
- Supabase CLI `2.116.0` dry-run against exact project ref `oykupyiitspujzpwwvuj` listed only `20260907065602_add_meal_categories_config.sql`, with no seed, role, Vault, or unrelated migration change.
- The exact migration applied successfully once from `2026-09-07T13:15:30Z` through `2026-09-07T13:15:39Z`. Hosted migration history now contains 40 entries with `20260907065602_add_meal_categories_config` as the latest and only occurrence of that version.

### Hosted Contract Verification

- `public.user_nutrition_profiles.meal_categories_config` exists as nullable `jsonb` with no default and the reviewed column comment. Both existing rows remain present and have `NULL` config; the row fingerprint excluding the additive B1 column remains `428741695b179576037e53778fe0df73`, matching preflight.
- CHECK `user_nutrition_profiles_meal_categories_config_valid` exists, is validated, and allows SQL `NULL` or `private.is_valid_meal_categories_config_v1(meal_categories_config)`.
- `private.is_valid_meal_categories_config_v1(jsonb)` returns boolean, is immutable, strict, `SECURITY INVOKER`, and has empty `search_path`. Direct `EXECUTE` is limited to `authenticated`, `service_role`, and owner `postgres`; `PUBLIC` and `anon` have none.
- `private.protect_meal_category_retained_ids()` returns trigger, is volatile, `SECURITY INVOKER`, and has empty `search_path`. Only owner `postgres` has direct `EXECUTE`.
- Enabled trigger `trg_user_nutrition_profiles_protect_meal_category_retained_ids` is `BEFORE UPDATE OF meal_categories_config FOR EACH ROW` on `public.user_nutrition_profiles`.
- RLS remains enabled. Authenticated owner SELECT and INSERT policies remain; UPDATE retains both `USING` and `WITH CHECK`; standalone `user_nutrition_profiles_delete_own` is absent as designed. The table-grant set is unchanged.
- The complete B1-named object inventory contains only the column, CHECK, two private functions, and trigger. The migration added no public RPC, index, revision/timestamp column, backfill, table, unrelated policy/grant, or Storage change.

### Hosted Advisors

- Security advisor: 5 existing `WARN` findings — four existing public `SECURITY DEFINER` RPC execution warnings and disabled leaked-password protection. No B1-named finding and no HIGH/CRITICAL B1 blocker.
- Performance advisor: 30 existing findings — 18 `WARN` RLS init-plan findings and 12 `INFO` unused-index findings. The Nutrition Profile findings apply to its pre-existing SELECT/INSERT/UPDATE policies and redundant existing user-id index; B1 added no policy or index. No B1-named finding and no B1 blocker.
- Slice B1 hosted verification result: `PASS`. TNYX-67 remains `In Progress`; TNYX-66 remains unchanged; B2/C/D are not started.

## 11. Slice B2 Adapter Readiness Refresh — 2026-09-07

### Fresh Repository and Hosted Evidence

- `main == origin/main == 31d3dd4b98182edca86866f9b1c31c1c41eac368`; PR #223 is squash-merged and changed only this task brief. Its late Codex review found no major issue. PR #222 finding `3950154215` is replied to/resolved, and no actionable B1 P1/P2 thread remains.
- The existing Meal Categories domain already owns stable IDs, canonical defaults, the strict V1 codec, maximum-eight validation, retained-ID transition policy, repository contract, and deterministic in-memory implementation. These contracts are exported through `package:tio_feature_nutrition/nutrition.dart`; B2 must reuse them rather than create a parallel model or feature tree.
- Current Supabase Nutrition adapters use an injectable narrow table gateway, `client.auth.currentUser?.id`, signed-out reads without gateway access, signed-out writes that throw before mutation, filtered `.select(...).eq('user_id', userId).maybeSingle()`, and `.upsert(payload, onConflict: 'user_id')`. Production composition selects Supabase or in-memory owners in `apps/app/lib/app/network_providers.dart`.
- `NutritionProfileRepository` and Product Onboarding write only canonical profile columns and omit `meal_categories_config`. The B1 database regression already proves the profile-only `ON CONFLICT` writer preserves a customized category config. B2 must not modify those writers or duplicate profile ownership.
- Fresh hosted read-only verification reconfirmed healthy project `tio-world` (`oykupyiitspujzpwwvuj`), 40 migrations with `20260907065602_add_meal_categories_config` latest and present exactly once, nullable/no-default `meal_categories_config jsonb`, validated CHECK, private `SECURITY INVOKER` validator and retained-ID trigger function with empty `search_path`, enabled row-level `BEFORE UPDATE OF meal_categories_config` trigger, RLS owner SELECT/INSERT/UPDATE with UPDATE `USING` and `WITH CHECK`, no standalone DELETE policy, two preserved rows with SQL `NULL` configs, and no B1 public RPC or category index. Current advisors contain only pre-existing warnings/info and no HIGH/CRITICAL or B1 blocker.
- Current Supabase Dart documentation confirms the repository's established `.maybeSingle()` and `.upsert(..., onConflict: 'user_id')` conventions. No current source, hosted contract, review, or tracker evidence requires a new schema object, RPC, index, timestamp/revision field, read-before-write concurrency layer, or backend service for B2.

### Exact B2 Implementation Boundary

One focused implementation PR is authorized. Actual branch/base:

```text
branch: tnyx/tnyx-67-meal-categories-supabase-adapter
base:   31d3dd4b98182edca86866f9b1c31c1c41eac368
```

Expected changed files/modules:

- add `apps/features/nutrition/lib/src/data/repositories/supabase_meal_categories_repository.dart` with an injectable `MealCategoriesTableGateway` and `SupabaseMealCategoriesRepository`;
- update `apps/features/nutrition/lib/src/data/data.dart` to export the adapter;
- update `apps/app/lib/app/network_providers.dart` with `mealCategoriesRepositoryProvider`, selecting the Supabase adapter when a client exists and `InMemoryMealCategoriesRepository` otherwise;
- add `apps/features/nutrition/test/data/supabase_meal_categories_repository_test.dart` for the focused adapter contract;
- update `apps/app/test/app/network_providers_test.dart` for Supabase/in-memory composition selection;
- update this task brief with actual implementation/validation evidence. No other source file is expected to change unless fresh implementation evidence proves the bounded adapter contract cannot be met.

Repository behavior for the implementation is fixed as follows:

- signed-out `read()` performs no gateway access and returns `MealCategoriesConfig.canonicalDefaults()`; signed-out `upsert()` throws before gateway access;
- authenticated read selects only `meal_categories_config` filtered by `user_id`; a missing row or SQL `NULL` resolves defaults, while non-null data decodes only through `MealCategoriesConfigCodec` and malformed/future schema errors propagate without defaulting;
- write calls `config.validate()`, encodes through `MealCategoriesConfigCodec`, and upserts only `user_id` plus `meal_categories_config`; it does not write profile fields or `updated_at`;
- the adapter does not perform a race-prone read-before-write transition check. The hosted CHECK and row-locking retained-ID trigger remain the authoritative atomic boundary; database rejection propagates without retry, merge, reset, truncation, downgrade, or fallback overwrite;
- existing profile/onboarding writers stay unchanged and continue preserving the category column through their already-narrow payloads.

### Focused Test and Validation Plan

`apps/features/nutrition/test/data/supabase_meal_categories_repository_test.dart` must cover signed-out read/write with zero gateway calls; missing-row and SQL-NULL defaults; valid V1 encode/decode round-trip; malformed and future-schema read failure; exact category-only payload with neither unrelated profile fields nor `updated_at`; first customization using only `user_id`/config; database rejection propagation with no fallback write; archived IDs retained in the encoded payload; and invalid ninth-active config rejected before gateway access. The public contract exposes no destructive reset/clear path.

Existing preservation coverage must remain green: the exact Nutrition Profile gateway payload test proves `meal_categories_config` remains omitted; Product Onboarding owner-write tests prove it delegates only through `NutritionProfileRepository`; the B1 SQL regression proves that profile-only `ON CONFLICT` updates preserve the stored category config. Provider tests must prove both no-Supabase in-memory and Supabase adapter selection.

Expected validation commands from their owning package directories:

```text
cd apps/features/nutrition
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub test/data/supabase_meal_categories_repository_test.dart test/data/supabase_canonical_nutrition_repositories_test.dart test/data/in_memory_meal_categories_repository_test.dart test/domain/meal_categories_config_test.dart test/domain/meal_categories_config_codec_test.dart

cd apps/app
flutter analyze --no-pub
flutter test --no-pub test/app/network_providers_test.dart

cd apps/features/onboarding
flutter test --no-pub test/domain/persist_onboarding_owner_data_use_case_test.dart

git diff --check
```

The focused PR must also receive exact-head Flutter CI. No Supabase Database CI change is expected because B2 changes no SQL, migration, RLS, grants, or database test.

### Explicit Non-Goals

No Meal Diary Settings UI, rename/add/archive/reorder screen, navigation/route, Quick Add Meal type activation, Meal Editor picker activation, Diary section integration, MealLog schema/persistence, TNYX-68/TNYX-113 work, Slice C/D, migration, table, RPC, index, revision/timestamp column, hosted mutation, `services/api`, Weight, Workout, Docker, local Supabase stack, or backend service is in B2.

### Slice B2 Readiness Classification

`READY — TNYX-67 Slice B2: Supabase Meal Categories repository adapter, narrow gateway, app composition provider, and focused adapter/provider preservation tests only.`

## 12. Slice B2 Implementation Evidence — 2026-09-08

### Implemented Boundary

- Added `SupabaseMealCategoriesRepository` and the injectable `MealCategoriesTableGateway` under the existing Nutrition data boundary. The concrete gateway selects only `meal_categories_config` for the authenticated `user_id` and upserts only `user_id` plus codec-encoded `meal_categories_config` with `onConflict: 'user_id'`.
- Signed-out reads resolve through `MealCategoriesConfig.resolve(null)` without gateway access. Signed-out writes reject before gateway access. Missing rows and SQL `NULL` resolve canonical defaults; malformed non-null and unsupported future-schema values propagate strict codec failures.
- Writes call the existing domain validation and V1 codec. They do not pre-read, merge, retry, reset, truncate, downgrade, write `updated_at`, or write Nutrition Profile fields. The hosted B1 CHECK and retained-ID trigger remain the authoritative atomic transition boundary, and gateway/database rejection propagates without a fallback write.
- Added `mealCategoriesRepositoryProvider` to the established app composition surface: Supabase client availability selects `SupabaseMealCategoriesRepository`; absence selects `InMemoryMealCategoriesRepository`. No UI, route, picker, MealLog, Slice C/D, or backend behavior was added.
- Existing Nutrition Profile and onboarding writers remain production-code unchanged. Their focused payload/delegation tests remain green, and the profile payload test now explicitly asserts omission of `meal_categories_config` and `updated_at`.

### Changed Files

- `.ai/tasks/tnyx-67-meal-categories-readiness.md`
- `apps/features/nutrition/lib/src/data/repositories/supabase_meal_categories_repository.dart`
- `apps/features/nutrition/lib/src/data/data.dart`
- `apps/features/nutrition/test/data/supabase_meal_categories_repository_test.dart`
- `apps/features/nutrition/test/data/supabase_canonical_nutrition_repositories_test.dart`
- `apps/app/lib/app/network_providers.dart`
- `apps/app/test/app/network_providers_test.dart`

### Local Validation

- Configured local toolchain: Flutter `3.44.6`, Dart `3.12.2`. `flutter` was unavailable through PATH and the wrapper initially waited on its SDK lock; validation therefore used the same configured Flutter SDK through `flutter_tools.snapshot` with `FLUTTER_ROOT`, without dependency resolution or repository-specific path changes.
- Scoped Dart format: 6 changed Dart files, 0 changes on verification.
- `apps/features/nutrition`: `flutter analyze --no-pub` — PASS, no issues.
- `apps/app`: `flutter analyze --no-pub` — PASS, no issues.
- Focused Nutrition adapter/domain/preservation set — PASS, 73 tests.
- `apps/app/test/app/network_providers_test.dart` — PASS, 9 tests.
- `apps/features/onboarding/test/domain/persist_onboarding_owner_data_use_case_test.dart` — PASS, 12 tests.
- Full `apps/features/nutrition` package suite — PASS, 314 tests.
- `git diff --check` — PASS.
- The unrelated root `pubspec.lock` remains unstaged and byte-for-byte preserved at SHA-256 `004DE1A093C1F04F684B39DF072C2F2E37B1CD21046BFEE01E628E7F77300B1C`. Preserved branch `docs/supabase-android-studio-qa-run` remains at `7fe896820c8f176b5049df4fe84fc9acea5933b1`.

### External Safety and Remaining Handoff

- Fresh hosted B1 verification before implementation was read-only and reconfirmed the 40-entry migration ledger, single latest B1 migration, reviewed column/CHECK/trigger/RLS contract, and preserved rows. No hosted Supabase mutation occurred.
- Docker, local Supabase, PostgreSQL containers, `services/api`, and backend services were not started.
- PR #224 opened from implementation commit `5f837c5bbb013e2ff8046e812fabedfb97e9790c`. Flutter CI run `34152650847` passed that implementation head, and GitHub Codex review comment `5574644339` reported no major issues; actual inline review threads were empty.
- This final task-record commit changes the PR head, so the final handoff must independently re-verify exact-head CI/review state before the one authorized Linear comment. No further repository change is expected. Merge is not authorized.

## 13. Slice C Settings UI Readiness Refresh — 2026-09-08

### B2 Closeout Reconciliation

- Slice A is closed. Slice B1 repository work is merged and its hosted migration is applied/verified. Slice B2 PR #224 is squash-merged and post-merge validated.
- `main == origin/main == 3d0b415fde1be8b62aa5002990fbdfe4fa226ace`. Push/main Flutter CI run `34175515202` passed on that exact SHA. The B2 local and remote implementation branches are deleted.
- No open overlapping Meal Categories UI PR or Slice C branch exists. Preserved branch `docs/supabase-android-studio-qa-run` remains at `7fe896820c8f176b5049df4fe84fc9acea5933b1`.
- Slice C and Slice D are not started. The unrelated root `pubspec.lock` remains byte-for-byte preserved at SHA-256 `004DE1A093C1F04F684B39DF072C2F2E37B1CD21046BFEE01E628E7F77300B1C`.

### Fresh Linear Dependency Truth

| Issue | Status | Relevant dependency/ownership truth |
|---|---|---|
| TNYX-66 | Backlog | Nutrition readiness gate; blocks TNYX-67, TNYX-68, and TNYX-54 |
| TNYX-67 | In Progress | Owns stable Meal Category identity/config and management behavior; blocked by TNYX-66 |
| TNYX-68 | Backlog | Owns the Meal Diary Settings surface, primary Diary entry, and optional Nutrition Settings shortcut; blocked by TNYX-66 and TNYX-54 |
| TNYX-54 | Backlog | Owns Nutrition IA/domain boundaries; blocked by TNYX-66 and blocks TNYX-68/TNYX-57 |
| TNYX-158 | Done | Supplies the current Quick Add shell; Meal Type activation remains Slice D |
| TNYX-137 | Done | Supplies the current mode-aware Nutrition Settings launcher/hub; unimplemented capabilities stay absent |
| TNYX-57 | Backlog | Owns future dynamic Diary sections; blocked by TNYX-54 |
| TNYX-58 | Backlog | Owns the full Meal Editor; blocked by TNYX-57 |

No status or dependency relation was changed by this readiness refresh.

### Current UI and Navigation Audit

- `NutritionSettingsPage` is intentionally a launcher for implemented capabilities only and currently exposes Nutrition Profile and Nutrition Targets. Its tests explicitly require Meal Diary to remain absent while unimplemented.
- `MealDiaryPage` owns the current Diary body and Add Food entry, but its top bar is composed by `apps/app/lib/app/router.dart` through `TioShellStatusTopBar`.
- `AppRoutes` has Nutrition Settings/Profile/Targets route contracts but no Meal Diary Settings or Meal Categories route.
- The current `TioShellStatusTopBar` has one contextual `leadingAction` slot. App composition uses it for the conditional Meal Diary Today action, so adding the owner-locked `More / ⋮` affordance requires an explicit TNYX-68 composition decision rather than silently replacing Today or changing Core.
- Core already supplies the reusable Settings row/card family, `TioInput`, `TioEditorSheet`, and `showTioConfirmationBottomSheet`. No production `ReorderableListView` precedent exists in the repository, so reorder behavior needs focused gesture/accessibility coverage when authorized.

### Ownership and Route Decision

- Meal Categories presentation/state belongs to `apps/features/nutrition`; widgets must not call Supabase directly.
- Meal Diary Settings hierarchy and entry semantics belong to TNYX-68. Route identities follow the existing `AppRoutes` contract in `apps/core`, while `apps/app/lib/app/router.dart` owns route registration, repository/controller injection, and top-bar navigation composition.
- A direct temporary `Nutrition Settings -> Meal Categories` route would violate the locked hierarchy, which requires both primary and secondary paths to pass through the same Meal Diary Settings surface/state.
- Building an unexposed Meal Categories screen before TNYX-68 would create dead/orphan UI and is not a safe implementation slice.
- Therefore Slice C cannot precede the minimal TNYX-68/TNYX-54 route/ownership readiness. It may proceed only after that boundary is approved, either as a coordinated minimal TNYX-68 shell plus TNYX-67 management page or after TNYX-68 lands first.

### Proposed Single State Owner

- Add one feature-owned `MealCategoriesController` with immutable editor state: initial load, confirmed config, local draft, saving/error state, max-active state, archived items, and reorder state.
- App composition instantiates that controller from the existing `mealCategoriesRepositoryProvider` and injects it into the route. No second in-memory repository/store is introduced.
- Load/retry goes only through `MealCategoriesRepository.read()`. Saves validate the full draft and call `MealCategoriesRepository.upsert()` once. Do not update the confirmed state until the write succeeds; on failure keep the draft visible with safe retry instead of inventing rollback or calling Supabase from widgets.
- The domain remains authoritative for IDs, normalized duplicate detection, active limit, retained identities, and malformed/future-config failure. The controller maps typed failures to safe UI messages without exposing database details.

### Product Behavior Decisions and Remaining Approval

- Active categories should form the reorderable primary list. The safest discoverable reactivation model is a separate `Archived` section below it; this keeps inactive identities out of active ordering while retaining them for history. That presentation is a recommendation and still needs owner-visible approval because TNYX-67 does not lock the exact inactive-list layout.
- At eight active categories, `Add Meal Category` and inactive-category reactivation are disabled/unavailable with the exact reason `Maximum 8 active meal categories`. Archiving an active category frees a slot.
- Rename/add uses `TioInput` in the governed editor sheet. Blank names and normalized duplicates (trimmed, collapsed whitespace, case-insensitive) are rejected before save; internal IDs are never rendered. Rename/reorder/archive/reactivate preserve the same ID.
- `Restore Defaults` is excluded from the first safe Slice C boundary. Ordinary upsert cannot remove retained identities, and the current contract does not define whether restore should archive custom active items, preserve them, or how to reassign their order. A historical-safe domain transformation and owner-approved visible semantics are required before exposing that action; writing `NULL` or replacing the config with four items is forbidden.

### Hosted Supabase Prerequisite

- Fresh read-only check: project `oykupyiitspujzpwwvuj` is `ACTIVE_HEALTHY`; migration ledger has 40 entries and latest is `20260907065602_add_meal_categories_config`.
- The nullable/no-default `jsonb` column, validated CHECK, private `SECURITY INVOKER` validator, private retained-ID function, enabled retained-ID trigger, RLS, and authenticated owner SELECT/INSERT/UPDATE policies each exist exactly once. Standalone DELETE policy count is zero and two Nutrition Profile rows remain present.
- Slice C requires zero new migration/schema/RLS/RPC/index/storage work. No hosted Supabase mutation occurred in this audit.

### Proposed Future Changed-File Surface

After dependency/owner approval, the smallest expected surface is:

- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_settings_page.dart` — TNYX-68-owned shell/entry surface;
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_categories_settings_page.dart` — TNYX-67 management UI;
- one feature-owned Meal Categories controller/state file under the existing Nutrition presentation boundary;
- the smallest Nutrition presentation/public export updates;
- `apps/core/lib/src/routing/routes/app_routes.dart` — route contracts only;
- `apps/app/lib/app/router.dart` — route registration, top-bar/secondary navigation, and controller injection;
- `apps/app/lib/app/network_providers.dart` — one controller provider composed from the existing repository provider;
- focused Nutrition widget/controller tests and app route/navigation tests.

No Core component/theme contract change is currently justified. If the top-bar action cannot be composed without changing the public shell contract, that becomes a separately reviewed cross-package decision inside the approved TNYX-68 boundary.

### Proposed Future Test Surface

- defaults and customized/archived rendering;
- rename/add with stable ID; reorder persists order only;
- maximum-eight Add/reactivate disabling and reason;
- archive frees a slot; archived identity remains; reactivation below/at cap;
- blank and normalized-duplicate rejection;
- initial loading, load failure/retry, save failure with retained draft, and successful confirmed save;
- malformed/future config fails closed without fallback overwrite;
- Light/Dark/OLED/System, compact width, large text, keyboard reachability, semantics, focus, drag handles, and tap targets;
- both approved navigation entries reach one route/controller; no direct Supabase access;
- Quick Add/Meal Editor Meal Type remains inactive and unchanged in Slice C.

### Slice C Readiness Classification

`BLOCKED — TNYX-68/TNYX-54 route/settings ownership readiness is not open yet, and owner-visible archived-category presentation remains unapproved. Restore Defaults is safely excluded rather than treated as a blocker for the future minimal Slice C. Do not create a temporary route, orphan screen, production UI, or Slice D implementation.`

Exact dependency sequence:

1. Close this readiness-doc handoff.
2. Run a fresh TNYX-66 readiness refresh specifically for TNYX-54.
3. Reconcile/close the TNYX-54 boundary if possible.
4. Run fresh TNYX-68 readiness.
5. Obtain owner approval for the minimal Meal Diary Settings route/top-bar shell.
6. Refresh TNYX-67 Slice C readiness.
7. Only then begin source implementation.

Linear TNYX-66 readiness-refresh comment: `0c57801f-e994-45e2-815d-a3f7a5b5c832`.

## 14. Slice C Settings UI Readiness Refresh — 2026-09-08 (post TNYX-68 merge)

### Dependency Reconciliation

The blocker recorded in Section 13 is cleared. TNYX-68's minimal Meal Diary Settings shell is merged.

```text
main == origin/main == 5f06a72b3a1404b1d315ee987c281605d706b738
TNYX-68 PR #226 squash-merged from ae8ea7bf546765cb88291f8576dba6b85b3945b2
TNYX-54  Done      Nutrition IA/domain boundaries closed
TNYX-66  Backlog   readiness gate; this section is its refresh for Slice C
TNYX-67  In Progress
TNYX-68  In Progress — only the shell slice is closed, later preferences remain
TNYX-158 Done      Quick Add shell; Meal Type activation is still later work
TNYX-58  Backlog   full Meal Editor
```

TNYX-68 auto-transitioned to `Done` on merge through tracker automation and was corrected back to `In Progress`, because only the shell slice closed. `Show meal times`, `Meal Notes`, `Show note preview` and `Meal Reminders` remain unbuilt inside that issue. No dependency relation was changed.

### What TNYX-68 Now Provides

```text
AppRoutes.mealDiarySettings        /settings/nutrition/meal-diary
AppRoutes.mealCategoriesSettings   /settings/nutrition/meal-diary/categories
both ChromePolicy.fullScreen, both registered on the root navigator
```

Two approved entries reach the same Meal Diary Settings route: `Meal Diary -> More / vertical ellipsis` and `Settings -> Nutrition Settings -> Meal Diary Settings`. The Meal Categories row navigates to `MealCategoriesDestinationPage`, which today renders a themed title and a back affordance over an empty body and reads no provider.

Slice C therefore **fills that existing destination**. It must not add a third page or a second route.

### Existing Domain and Data Surface — Complete for Slice C

Verified in current `main`:

```text
apps/features/nutrition/lib/src/domain/models/
  meal_category.dart                      id / defaultKey / displayName / active / order
  meal_categories_config.dart             versioned config, resolve(null) -> canonicalDefaults
  meal_category_defaults.dart             meal_slot_1..4 / breakfast..snacks
  meal_categories_policy.dart             schemaVersion 1, maxActiveMealCategories 8,
                                          duplicate id/order/defaultKey, custom UUID-v4 id shape,
                                          normalized active duplicate-name rejection,
                                          missing-canonical-default rejection
  meal_categories_transition_policy.dart  retained identity may never be dropped by upsert
  meal_categories_validation.dart         typed failure codes
apps/features/nutrition/lib/src/domain/usecases/
  meal_category_id_generator.dart         UUID-v4 custom ids that avoid retained ids
apps/features/nutrition/lib/src/domain/repositories/meal_categories_repository.dart
apps/features/nutrition/lib/src/data/in_memory_meal_categories_repository.dart
apps/features/nutrition/lib/src/data/repositories/supabase_meal_categories_repository.dart
apps/app/lib/app/network_providers.dart   mealCategoriesRepositoryProvider (Supabase or in-memory)
```

Every product rule in the Slice C contract — durable non-semantic IDs, rename touching only `displayName`, reorder touching only `order`, archive and reactivate retaining identity, the eight-active cap rejected rather than truncated, blank and normalized-duplicate rejection — is already owned and enforced by the domain. Slice C adds presentation and one controller; it adds no new rule.

### Proposed Slice C File Surface

```text
modify
  apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_categories_destination_page.dart
      fill the existing boundary; do not add a page
  apps/features/nutrition/lib/src/meal_diary/presentation/presentation.dart
      export the controller/state if it is not internal
  apps/app/lib/app/router.dart
      inject the controller into the existing route builder

add
  apps/features/nutrition/lib/src/meal_diary/presentation/controllers/meal_categories_controller.dart
  focused Nutrition widget/controller tests under apps/features/nutrition/test/meal_diary/
  app route/navigation test additions where behavior crosses the composition root

unchanged
  apps/core/**                              no component or token contract change is justified
  apps/app/lib/app/network_providers.dart   unless controller injection genuinely needs a provider
  supabase/**                               no migration, schema, RLS, RPC or index work
```

### State Ownership

One feature-owned `MealCategoriesController` with immutable state: loading, load failure, confirmed config, working draft, saving, save failure, and derived active count.

```text
read     MealCategoriesRepository.read()      -> confirmed + draft
edit     draft only                              confirmed is untouched
save     validate draft, then upsert() once      confirmed updates only on success
fail     draft retained, safe retry              no invented rollback, no widget Supabase call
```

The repository stays the single durable source. No second repository, no screen-local default list, no hard-coded Breakfast/Lunch/Dinner/Snacks in presentation — defaults resolve through `MealCategoriesConfig.resolve(null)`. The controller maps typed `MealCategoriesValidationCode` failures to safe copy without leaking database detail.

### Archived Presentation — Decision Requested, Now Resolved

Slice C's contract requires reactivation, and reactivation requires archived categories to be reachable in the UI. Without an approved surface for them, archive becomes a one-way action with no way back, which contradicts the retained-identity contract.

TNYX-67 specifies archive and reactivate semantics, but its Settings UX sketch shows only the active list plus `+ Add Meal Category`. The archived surface is genuinely unspecified, so it cannot be chosen silently.

Smallest decision required — how archived categories appear on the Meal Categories screen:

```text
A  a separate "Archived" section below the active list, each row reactivate-able
B  archived items inline in one list, visually de-emphasised, with an active/archived filter
C  archived items behind an "Archived (n)" entry that opens its own sub-screen
```

Recommendation was **A**, and the owner selected A. The locked contract follows.

### Archived Presentation — OWNER-LOCKED (Option A)

The decision recorded above as open was made by the owner on 2026-09-08. **Option A is locked.** One screen, two sections, no sub-route.

```text
Meal Categories

ACTIVE
  active categories
  rows are reorderable
  rename and archive management lives here

  + Add Meal Category

ARCHIVED
  rendered only when at least one archived category exists
  rows are NOT reorderable
  each row exposes Reactivate
```

Contract details that follow from the lock:

- The `ARCHIVED` section is absent — not empty, not a zero-state — while no archived category exists.
- Reactivation restores the **same** stable `MealCategory.id`. It never mints a new identity, which is what keeps historical `MealLogEntry.mealCategoryId` resolvable.
- Archived rows carry no drag handle and no reorder semantics; `order` is meaningful only among active categories.
- No second route, sub-screen, or dialog-hosted archive list. `AppRoutes.mealCategoriesSettings` remains the only Meal Categories route, and Slice C fills the destination TNYX-68 already shipped.

### Max-Eight UX — locked

```text
active count < 8   Add Meal Category enabled
                   Reactivate enabled on archived rows

active count = 8   Add Meal Category unavailable
                   Reactivate unavailable
                   reason, verbatim: "Maximum 8 active meal categories"

archive            frees exactly one active slot
persist 9 active   rejected by the domain, never truncated
```

Retained inactive categories never count toward eight, so total retained items may exceed eight over a user lifetime. Nothing is deleted to satisfy the cap.

### Restore Defaults — Still Excluded

Excluded from the initial Slice C, and this is not a blocker. Ordinary upsert cannot remove retained identities, and the contract does not define whether restore should archive custom active items, preserve them, or how to reassign order. Writing `NULL` or replacing the config with four items is forbidden. It needs its own historical-safe contract later.

### Quick Add and Shared Footer Boundary

Not in Slice C. The next consumer slice after Slice C is **shared `MealLogActionFooter` Meal Category selector activation**, not a Quick Add-only picker. That footer is the Nutrition-owned reusable surface carrying the category control, the date/time control and the primary action; Quick Add is only its first runtime consumer, and the future full Meal Editor, Photo, AI-text, Voice, Search, Recent, Saved Meal and existing-log-edit flows reuse it. The selector must resolve active categories from the existing repository/state rather than hard-coding the four defaults.

### Proposed Test Matrix

```text
state        canonical defaults from NULL; load success; load error and retry
edit         rename; reorder; add custom; internal ID never rendered
validation   blank name rejected; normalized duplicate rejected
lifecycle    archive; archived identity retained; reactivate restores the same id
archived UI  ARCHIVED section absent while none archived; present once one exists;
             archived rows expose Reactivate and carry no reorder affordance;
             one route only, no Archived sub-screen
limit        active max 8; Add unavailable at 8; reactivate unavailable at 8;
             exact reason copy "Maximum 8 active meal categories";
             archive frees a slot
persistence  failed save retains draft; successful save updates confirmed state;
             repository rejection surfaced without corrupting UI state
theme        Light, Dark, OLED, System-dark
layout       compact width, large text scale
a11y         semantics, focus order, tap targets, drag-handle reachability
navigation   both entries reach one route/controller; back behavior
boundaries   zero Quick Add or footer activation; zero MealLog persistence;
             zero Supabase access from presentation
```

Reorder has no production `ReorderableListView` precedent in this repository, so its gesture and accessibility coverage has to be written rather than copied.

### Hosted Supabase Boundary

Fresh read-only verification: project `oykupyiitspujzpwwvuj` is `ACTIVE_HEALTHY` on Postgres 17.6.1.155; the migration ledger holds 40 entries with latest `20260907065602_add_meal_categories_config`. Slice C requires zero migration, schema, RLS, RPC, index or storage work and consumes the existing adapter. No hosted mutation occurred in this audit.

### Slice C Readiness Classification

`READY — Slice C may be implemented as one named slice.`

Every dependency, domain rule, repository, provider and route now exists in `main`; the TNYX-68 blocker is cleared; and the last open item — archived presentation — is owner-locked to Option A as recorded above. Slice C fills the existing `MealCategoriesDestinationPage` with a two-section Active/Archived screen and one feature-owned controller. It requires no new route, no second repository, no Core component or token change, and no migration.

Implementation still requires its own start: this classification authorizes one named slice, not the consumer work after it. `Restore Defaults`, the shared `MealLogActionFooter` category-selector activation, Quick Add/Meal Editor changes, MealLog persistence, Supabase mutation and `services/api` all remain excluded.

## 15. Slice C Implementation — 2026-09-08

### Handoff

```text
base    72b267b1f3c4b56ac511bb91d99e2f5f7c2078b0
branch  tnyx/tnyx-67-meal-categories-settings-ui
PR      #228, Draft — https://github.com/im-tnyx/tio-world/pull/228
```

**Implementation owner:** Claude, active for this slice only.
**Status:** implemented and validated; awaiting owner UI approval, then merge authorization.
**Not authorized by this slice:** Restore Defaults, the shared `MealLogActionFooter` category selector, Quick Add / Meal Editor changes, MealLog persistence, Supabase mutation, `services/api`.

### Changed files

```text
added     .../meal_diary/presentation/controllers/meal_categories_controller.dart
          .../nutrition/test/meal_diary/meal_categories_settings_test.dart
modified  .../meal_diary/presentation/pages/meal_categories_destination_page.dart
          .../meal_diary/presentation/presentation.dart
          apps/app/lib/app/router.dart
          apps/app/test/app/app_mode_router_test.dart
          .../nutrition/test/meal_diary/meal_diary_settings_shell_test.dart
```

`apps/core`, `supabase/` and `apps/app/lib/app/network_providers.dart` are unchanged.

### What was built

The TNYX-68 destination is filled rather than replaced: no new route, no second screen. The page renders the owner-locked two-section shape, and `MealCategoriesController` owns state and repository sequencing.

The controller adds **no product rule**. Durable non-semantic IDs, rename touching only `displayName`, reorder touching only `order`, archive/reactivate retaining identity, the eight-active cap rejected rather than truncated, blank and normalized-duplicate rejection, and UUID-v4 custom IDs that never reuse a retained identity are all already enforced by the domain. Presentation duplicates no validation algorithm; the single exception is refusing to submit an empty field, which is about an empty form rather than a rule.

### Behaviour contracts this slice pins

```text
open page        reads once, writes never — an untouched user keeps inheriting
                 the canonical four rather than materialising them
no-op edit       short-circuits before the write, for the same reason
save order       build -> domain validates -> write -> only then adopt confirmed
failed write     confirmed untouched; the attempt is retained and retryable in
                 one tap, because the name sheet has already closed
rejected write   surfaced but not offered as a retry — it would fail identically
reactivate       appended after every active item, explicitly, because an
                 archived category can legitimately hold a lower stored order
cap              Add and Reactivate unavailable at 8, reason verbatim
                 "Maximum 8 active meal categories"
```

### Review findings, all fixed

Codex raised one P1 and six P2s on `cd9d4930`. Every one was valid and none was argued down.

| Finding | Resolution |
|---|---|
| P1 task brief not updated with implementation truth | this section |
| failed save discarded the attempted edit | state carries `pendingRetry`; the failure surface offers Retry |
| reactivated category could land mid-list | `reactivate` appends after all active items explicitly |
| load failure showed mutation-oriented copy | separate `_loadMessageFor` for read-time failures |
| nested reorderable list could not auto-scroll | page is a `CustomScrollView`; the active list is a `SliverReorderableList`, so there is exactly one scroll view and a drag can move it |
| no-op rename persisted a configuration | write short-circuits when `next == confirmed` |
| disabled icons still looked enabled | icon colour derives from `enabled` rather than a fixed value |

The sliver fix changed structure: `_ActiveSection` is gone and each `_ActiveRow` paints its own slice of the group surface, rounded only at the ends, so the list still reads as one card while living somewhere that can actually scroll.

### Validation

```text
flutter analyze  apps/core                No issues found
flutter analyze  apps/features/nutrition  No issues found
flutter analyze  apps/app                 No issues found
flutter test     apps/core                266 passed
flutter test     apps/features/nutrition  359 passed
flutter test     apps/app                 305 passed
git diff --check                          clean
exact-head CI    run 34219878241 on cd9d4930   SUCCESS (pre-review-fix head)
```

Mutation checks — each breaks one invariant and the named test fails:

```text
adopt confirmed before the write succeeds     failure-safety test fails
archive deletes instead of retaining          retained-identity test fails
archived section always rendered              visibility test fails
no-op short-circuit removed                   writes 1 instead of 0
reactivate sorts by stored order              lands first, not last
load uses mutation copy                       "Enter a category name." leaks
failed write keeps no retryable attempt       retry test fails
disabled icons keep the enabled colour        colour assertion fails
```

One further mutation is recorded honestly rather than as coverage: removing the controller's cap guard changes nothing observable, because the domain rejects the ninth active one layer down with the same message. That guard is redundant defence, not untested behaviour.

Four defects were found during implementation and fixed rather than tested around: a sheet text controller disposed while the sheet was still animating out; a route builder rebuilding the controller on every rebuild and orphaning the page's listener; a 9dp overflow at 320dp under a 1.6x text scale; and a reorder `Semantics` that produced no node because its child was a bare `Icon`.

### Owner UI status

`AWAITING OWNER UI APPROVAL`. Evidence covers the default active list, add and rename with the blank-name disabled state, archive confirmation, one and two archived items, the max-eight state with both actions disabled, 320dp compact and 320dp at 1.6x text, across Light, Dark and OLED. The capture harness was temporary and is not in the branch; nothing ships under `lib/` and no golden baseline is committed.

### Next slice

Shared `MealLogActionFooter` Meal Category selector activation, consuming the same active-category source. Not started, and not authorized by this slice.

## 16. Active and Ordering Invariants — 2026-09-08

Owner correction applied inside the Slice C branch, not as a new slice.

### Active count

```text
1 <= active <= 8
```

The maximum was already enforced; the minimum is new. A configuration with
nothing active is not a state the app can be in — every meal has to be filed
under something — so the last active category cannot be archived. Archived
identities are excluded from the count, and the retained total may exceed
eight over a lifetime.

Enforced in `MealCategoriesPolicy`, which every boundary already runs through:
the `MealCategoriesConfig` constructor, `MealCategoriesConfigCodec.encode` and
`decode`, and `MealCategoriesRepository.upsert`. A hostile or corrupted
persisted row is rejected rather than repaired, and nothing is reactivated to
paper over it.

### Canonical relative order

```text
breakfast < lunch < dinner < snacks
```

Anchored to durable identity, never to `displayName`. Renaming `meal_slot_2`
from "Lunch" to "Pre Workout" leaves it occupying the Lunch anchor, so ordering
never follows what a category happens to be called.

Checked across **every** item, archived ones included. That is what makes
restore correct: an archived default keeps its slot, so bringing it back lands
it between the right neighbours instead of at the end of the list. Archiving no
longer moves anything — it only flips `active`.

### What may move

```text
canonical defaults   fixed relative to one another; not user-reorderable
custom categories    free to sit before, between, or after any anchor
```

Valid, and covered by tests:

```text
Pre Workout · Breakfast · Morning Snack · Lunch · Post Workout · Dinner ·
Snacks · Late Meal
```

Rejected with `canonicalDefaultOrderViolated`:

```text
Dinner · Breakfast · Lunch · Snacks
Breakfast · Dinner · Lunch · Snacks
```

A reorder is applied to the full ordered list — archived items included —
because that list carries the anchors. Only the moved custom changes place;
everything else is renumbered in sequence, so the anchors cannot invert. The
controller refuses a request to move a default rather than ignoring it
silently.

### Rows

Default rows carry no drag handle and advertise no reorder semantics — a
disabled grip still reads as "drag me", and these rows genuinely cannot move.
The handle slot stays reserved, so category names sit in one vertical column
whether or not the row has a grip.

Archive stays a left-swipe reveal followed by confirmation. At one active
category the swipe exposes nothing to reveal, and the row publishes the reason
as its semantics hint: `At least one meal category is required.` No
confirmation is offered for an archive that would be refused.

### Not in scope

No clock-time restriction was added and none is implied. Fixed ordering is
display organisation; `MealLogEntry.consumedAt` remains the separate truth
about when something was actually eaten. Breakfast can be logged at midnight.

Slice B is not started. No Supabase migration, adapter or hosted change; no
MealLog persistence; no `services/api`.

### Validation

```text
flutter analyze  core / nutrition / app     No issues found
flutter test     core 266 · nutrition 392 · app 305    all passed
git diff --check origin/main...HEAD         clean
```
