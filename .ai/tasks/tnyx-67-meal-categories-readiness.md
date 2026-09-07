# TNYX-67 — Meal Type / Meal Categories Readiness

**Status:** In progress
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Supabase Postgres repository migration for Slice B1; Flutter Android + iOS behavior is unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice; future Supabase column shape change; future product-visible UI/UX change
**Approval status:** Slice A approved, implemented, merged, and post-merge validated; Slice B1 repository implementation and Draft PR handoff are approved; hosted apply and Slice B2/C/D remain unapproved and unstarted
**Approval evidence:** TNYX-67 owner-locked semantics updated 2026-09-06; the 2026-09-06 Slice A authorization; the 2026-09-07 TNYX-66 Slice B readiness-refresh authorization; and the 2026-09-07 explicit Slice B1 repository implementation authorization.
**Approved product/data direction:** Meal Category is separate from `MealLogEntry.mealName`; four resolved defaults; maximum eight active categories; stable non-semantic IDs; profile-owned nullable versioned JSONB direction.
**Explicit non-changes:** No Flutter UI, Supabase adapter, hosted Supabase mutation, MealLog persistence, `services/api`, Weight, or Workout work. No Slice B2, C, or D implementation.

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** Codex `/root` for Slice B1 only
**Review owner:** Codex `/root` for PR #221 post-CI P1 remediation and final independent review
**Implementation ownership state:** Slice A closed; Slice B1 repository implementation active; Slice B2/C/D unstarted
**Ownership transition:** Owner-authorized transition from readiness planning to `/root` Slice B1 implementation on 2026-09-07
**Repository state last verified:** 2026-09-07 after fresh Git/GitHub/Linear/Supabase read-only verification
**Branch:** `tnyx/tnyx-67-meal-categories-db-guards`
**Base SHA:** `1f31153543c20fd44a42b84f4defe897e0d48a2d`
**Observed working-tree state:** Slice B1 branch starts at `main == origin/main == 1f31153543c20fd44a42b84f4defe897e0d48a2d`; PR #218/#219/#220 are merged; no open TNYX-67/Meal Categories PR existed at the implementation safety gate; the unrelated root `pubspec.lock` modification remains unstaged and excluded
**Observed uncommitted/dirty files:** pre-existing `pubspec.lock` plus scoped PR #221 remediation source/test/task-brief changes; preserve and exclude the lock exactly
**PR / tracker:** PR #218/#219/#220 merged. Linear drift was corrected from TNYX-67 `Done` to `In Progress`; `blockedBy TNYX-66` remains unchanged. TNYX-66 remains Backlog.
**Current implementation state:** Slice A is closed, merged, and post-merge validated. Slice B1 post-CI P1 remediation is active on the dedicated branch; hosted mutation and adapter implementation have not started. Readiness chooses schema-first B1 followed by separately authorized adapter B2.
**Relevant execution surface:** Nutrition domain/data; later Nutrition Meal Diary Settings and meal-logging presentation
**Validation completed:** Slice A validation remains green. For Slice B1, exact P1-remediation implementation head `bf31923d4ab8ea59256536ad467cc81ef21d609f` passed full Supabase Database CI run `34120860985`: disposable base initialization, baseline replay/lint, clean full replay, dynamic repository-file/ledger parity, B1 version exactly once, private-schema exposure, exhaustive SQL/RLS/DELETE/account-cascade/large-archived matrix, real two-session stale-writer concurrency, and B1-introduced lint comparison.
**Validation remaining:** Evidence-doc head CI, hosted read-only unchanged proof, review-thread replies/resolution, and final independent review. Any hosted apply requires separate explicit authorization and fresh verification.
**Current blocker:** No source/test blocker remains after run `34120860985`; PR #221 remains in review closeout until the four findings are replied/resolved and the final independent review is clean. Hosted rollout remains intentionally blocked by missing explicit apply authorization. Later settings UI remains coupled to TNYX-68/N14 and TNYX-54.
**Open review finding IDs:** `3949432003`, `3949432006`, `3949432012`, and `3949432017` are fixed and exact-head validated but remain open until evidence replies are posted.
**Next exact action:** Validate this evidence-doc head, reverify hosted state read-only, reply/resolve all four threads, then perform final independent review. Do not merge, start B2, or apply hosted DDL.

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
- Slice C remains dependency-gated by TNYX-68/TNYX-54 and needs owner-approved visible UI behavior, including historical-safe Restore Defaults semantics.
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
- Hosted Supabase remains untouched; a fresh read-only unchanged check remains before final closeout.

### Slice B1 Final Classification

`READY FOR THREAD CLOSEOUT / FINAL REVIEW` — all four P1 source/test fixes passed exact-head disposable database CI. Hosted unchanged proof, thread closeout, and final independent review remain; hosted apply, merge, and every later slice remain unauthorized and unstarted.
