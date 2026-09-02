# TNYX-141 — Additional Nutrient Goals V1

**Status:** In progress
**Primary owner:** Flutter mobile / Nutrition feature
**Affected platforms:** Flutter Android and iOS; local Supabase migration

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; product-visible UI/UX change; Supabase column shape change
**Approval status:** Approved
**Approval evidence:** Linear TNYX-141 `READY — OWNER AUTHORIZED`, frozen 2026-09-02 against `main` `b1747a9d00bd492b1d894eec87c5e5ef6433f736`; this implementation prompt authorizes branch, source/tests, one local migration, validation, commit/push, Draft PR, and tracker evidence.
**Approved product/UI/data-shape boundaries:** Exactly `saturated_fat`, `trans_fat`, `sodium`, and `vitamin_d`; one nullable `public.user_nutrition_targets.additional_nutrient_goals jsonb` column with an object-or-null check; a nested Additional Nutrient Goals screen under Nutrition Targets; typed domain contracts and V1 serialization.
**Explicit non-changes:** No other nutrient; no reference-sex/life-stage fields; no core-five storage change; no `customized_fields` or `recommendation_metadata` change; no RLS/RPC/trigger change; no hosted DDL/apply/push; no migration-history repair; no GitHub #24 mutation; no merge; no Linear Done.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Owner (final substantive review); Codex performs implementation self-review only
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-02
**Branch:** `codex/tnyx-141-additional-nutrient-goals-v1`
**HEAD SHA:** `b1747a9d00bd492b1d894eec87c5e5ef6433f736`
**Observed working-tree state:** Clean before this task brief
**Observed uncommitted/dirty files:** None before implementation
**PR / tracker:** No open PR at baseline; Linear TNYX-141 is `In Progress`; GitHub #24 remains OPEN/PAUSED and untouched
**Current implementation state:** Domain, persistence, migration file, UI and routing complete; validated locally
**Relevant execution surface:** `apps/features/nutrition`, `apps/app`, `apps/core` route contract, `supabase/migrations`
**Validation completed at SHA:** Analyzer, formatting and full test suites for `apps/shared`, `apps/core`, `apps/features/nutrition`, `apps/app`; `git diff --check`
**Validation remaining:** Physical-device acceptance, exact-head CI, hosted migration authorization
**Current blocker:** None for implementation. Hosted rollout is gated on migration-ledger repair (see below) and separate owner authorization.
**Open review finding IDs:** None open; three found and fixed during implementation (see Review Findings)
**Next exact action:** Push the branch, open the Draft PR, and attach evidence to Linear. Do not apply hosted DDL or merge.

## Global UI / Design-System Guardrail

`apps/core/lib/src/theme/README.md`, `apps/features/AGENTS.md`, the existing
Nutrition settings surfaces, and the core component barrel were inspected.
This slice reuses `TioGroupCard`, settings rows, input/editor-sheet and button
contracts. It introduces no token, theme contract, or unrelated visual change.

## 1. Discovery

### User Outcome

An eligible adult can open Settings → Nutrition & Diet → Nutrition Targets →
Additional Nutrient Goals and configure exactly four governed goals. Each goal
can use the current recommendation, carry an explicit custom override including
zero, or be disabled without changing the five core targets.

### Success Criteria

- Only the four authorized canonical `NutrientId` values are exposed.
- Recommendations derive at runtime; only configuration/override state persists.
- Missing required canonical inputs and age under 19 show unavailable; no value
  is fabricated and `Use Recommended` is disabled.
- V1 serialization distinguishes absent, null, custom, and explicit zero.
- Unknown V1 fields survive edits; malformed known V1 is rejected; unsupported
  future schema is read-only and never rewritten.
- Core-five writes preserve the JSONB column, and focused local PostgREST proof
  demonstrates omitted-key preservation and explicit-null clearing.

### Scope

Typed domain rules, one persistence envelope/codec, repository support, one
additive local migration, the nested route/screen, focused tests, validation,
and a reviewed Draft PR.

### Non-Goals

All Nutrition backlog outside the four IDs; hosted mutation; migration-history
repair; production rollout; RLS/RPC/trigger changes; child tables; per-nutrient
columns; copied Profile/Body truth; new design-system contracts.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: canonical `NutrientId`, Nutrition target domain and
  repositories, Supabase adapter, providers, router, current target pages/tests,
  migration directory/config, and hosted `user_nutrition_targets` metadata.
- Existing pattern to follow: app-owned provider/router composition; feature-owned
  typed domain and UI; current whole-row core-target upsert; core settings widgets.
- Hosted table currently has 11 columns and no `additional_nutrient_goals`;
  RLS is enabled with four owner policies, existing constraints and update trigger;
  no dependent views/functions were found.
- Repository/hosted migration timestamps do not reconcile. This pass may create
  and validate a local migration but may not repair history or apply hosted DDL.

### Migration-ledger reconciliation (read-only, performed this pass)

```text
repo migrations                38 files (37 pre-existing + 1 new)
hosted applied migrations      26
hosted latest                  20260831064841_add_nutrition_other_free_text
repo latest (pre-existing)     20260831064500_add_nutrition_other_free_text
new local migration            20260902041627_add_nutrition_additional_nutrient_goals.sql
hosted migrations missing from repo   none
```

Two distinct kinds of drift exist, and they matter for rollout in different
ways.

**1. Eleven repo migrations were never recorded in the hosted ledger.** All of
them are timestamped `20260814000001` through `20260816000004`, and the
earliest hosted entry is `20260817090811` — the hosted ledger simply begins
after them. Several are visibly from the sibling `tnyx-hub` lineage
(`create_tnyxhub_canonical_tables`, `create_user_devices_table`,
`add_plan_to_users_table`). Their objects exist in the database; only the
ledger rows are missing.

**2. Three migrations exist under both names but at different versions.**

| Migration | Repo version | Hosted version |
|---|---|---|
| `refine_username_suggestions` | 20260826072000 | 20260826075218 |
| `set_active_body_goal_rpc` | 20260830055341 | 20260830074411 |
| `add_nutrition_other_free_text` | 20260831064500 | 20260831064841 |

**Deployment gate this creates.** The new migration's version is later than the
hosted latest, so it is correctly ordered. But a plain `supabase db push` would
first try to replay the eleven unrecorded `202608140000xx`–`202608160000xx`
migrations, which create objects that already exist. That would fail, and if
forced could damage existing data. **The ledger must be repaired first** — the
eleven marked applied, and the three version mismatches resolved — before this
migration can be deployed by the normal flow. Recording it here as a mandatory
rollout gate; it does not block local implementation, and no repair was
attempted in this pass.
- Some broad architecture/setup strategy wording is stale relative to the active
  root/product contract; runtime source and current root architecture remain truth.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| V1 set is exactly four canonical IDs | Approved | Frozen TNYX-141 boundary | Owner |
| V1 recommendation eligibility is age >= 19 | Approved | No pediatric policy or fabricated default | Owner |
| Persist only `custom_value` within versioned JSON | Approved | Runtime recommendation remains current canonical truth | Owner |
| Unknown V1 data is opaque and merge-preserved | Approved | Forward-compatible read-modify-write | Owner |
| Future schema is unsupported/read-only | Approved | An old client must never downgrade future data | Owner |
| Hosted apply waits for separate authorization and ledger reconciliation | Approved | Current migration ledger is mismatched | Owner |

## 4. Architecture Design

### Chosen Approach

- Domain owns `AdditionalNutrientGoalSet`, `AdditionalNutrientGoal`, policy types,
  capability state, recommendation derivation and effective-value resolution.
- Data owns a V1 persistence envelope/codec. Raw maps never enter UI contracts.
- Core-target `upsert` omits the new column, preserving new-client state when an
  old/core-only writer updates the existing row.
- A dedicated repository operation re-reads and merge-updates only additional
  goals, preserving unknown V1 content and refusing future schema rewrites.
- App composition supplies canonical Calories and DOB-derived age to the feature.

### Ownership and Data Flow

```text
Additional Goals UI -> typed domain policy -> NutritionTargetsRepository
  -> V1 persistence codec/envelope -> Supabase/PostgREST

Profile DOB + canonical target Calories -> runtime recommendations only
```

### Alternative Rejected

Loose `Map<String, dynamic>` through domain/UI, per-nutrient columns, a child
table, persisted recommendation values, and duplicating age/calorie truth were
rejected because they violate the frozen contract.

### Failure and Accessibility States

Unavailable recommendations are explicit and non-actionable; saved custom values
remain visible. Save failures keep the editor retryable. Rows retain semantic
labels, standard navigation affordances, and existing touch/keyboard behavior.

## 5. Implementation Plan

- [x] Add typed goal/recommendation contracts and pure policy tests.
- [x] Add V1 persistence codec and repository preservation tests.
- [x] Create one canonical additive local migration.
- [x] Add the nested route and feature-owned goals screen.
- [x] Add widget and route-level persistence/preservation tests.
- [~] Prove old-client semantics through local PostgREST — **not executable
  here**; strongest available repository-level proof provided instead (see
  Compatibility proof).
- [x] Run focused and package-level validation plus self-review.
- [ ] Commit, push, open reviewed Draft PR, and attach exact evidence to Linear.

### Compatibility proof — why it is a gateway-payload test

Docker is not installed, the Supabase CLI is not on PATH, and `npx supabase`
requires a network download, so a live PostgREST integration test cannot run in
this environment. Rather than fake it with a mapper-only assertion, the proof
pins the half of the contract that lives in this repository: the exact payload
sent to PostgREST.

That is a real guarantee because PostgREST's upsert compiles to
`INSERT ... ON CONFLICT (user_id) DO UPDATE SET <payload columns>`. A column
absent from the payload is never written; one present with an explicit null is
written as null. So two assertions decide the preservation behaviour:

- the core-five upsert payload **omits** `additional_nutrient_goals` entirely,
  so an old-client-shaped write cannot clear it;
- the goals-only write payload contains **only** `user_id` and
  `additional_nutrient_goals`, so it cannot disturb the core five.

Both are asserted, along with a re-read-before-merge test proving concurrent
unknown data is not lost. The remaining half is documented PostgreSQL
semantics, and is listed as a deployment-gate verification item to confirm once
the hosted migration is authorized.

## 6. Quality Review

### Validation Run

```text
dart format   (all changed source and test files)          PASS

flutter analyze  apps/shared                               PASS - No issues found
flutter test     apps/shared                               PASS - 36 tests

flutter analyze  apps/core                                 PASS - No issues found
flutter test     apps/core                                 PASS - 177 tests

flutter analyze  apps/features/nutrition                   PASS - No issues found
flutter test     apps/features/nutrition                   PASS - 223 tests
                                                           (was 133 at baseline; +90)

flutter analyze  apps/app                                  PASS - No issues found
flutter test     apps/app                                  PASS - 267 tests

git diff --check                                           PASS
```

Affected packages were determined from actual imports: the new domain, codec
and screen live in `apps/features/nutrition`; `apps/core` owns the new route
contract; `apps/app` composes the route and supplies canonical Calories and
date of birth; `apps/shared` owns `NutrientId` and was read but not modified.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence or follow-up |
|---|---|---|---|---|
| F1 | Blocking | Fixed | The V1 codec did not compile. `custom_value` was read into an `Object?` and the guard `if (raw != null && raw is! num) throw` does not promote, so `raw?.toDouble()` failed to resolve. Restructured into an explicit null / `is num` / else-throw chain. | `additional_nutrient_goals_v1_codec.dart` |
| F2 | Blocking | Fixed | Same file carried an unused `tio_shared` import. Confirmed safe to drop: `storageValue` is an enum field, not an extension getter, so it resolves without the import. | `additional_nutrient_goals_v1_codec.dart` |
| F3 | High | Fixed | The new route was missing from `shellChromePolicyForPath`, so it fell through to `noBottomBar` and would have rendered shell chrome over a full-screen settings page. Added, and the existing policy test extended to cover all three nutrition sub-routes rather than two. | `router.dart`, `nutrition_settings_route_test.dart` |
| F4 | Medium | Fixed | The row overflowed by 18px at 390dp: "Recommended" beside a label like "Saturated Fat" does not fit the core settings row's label/annotation pair. Moved the state caption under the amount in the value column, which also keeps both states visible. | `additional_nutrient_goals_page.dart` |
| F5 | Medium | Fixed | Thousands grouping was initially applied by a single formatter used for both prose and the editor's text field, so a custom value of 1500 would have rendered as "1,500" and then failed `double.tryParse` on save. Split into a grouped formatter for prose and an ungrouped one for anything parsed back. | `additional_nutrient_goals_page.dart` |

### Contract deviation recorded for review

The pre-existing test `additional nutrient goals are not exposed here` asserted
that the literal string "Additional Nutrient Goals" must not appear on the
Nutrition Targets page. TNYX-141 section 18 requires exactly that entry to be
added there. The test's underlying intent — that individual nutrient rows must
not appear beside the core five — is preserved and still asserted; the string
assertion was inverted to match the new contract, and a navigation test was
added. Flagging it because it is a deliberate change to an existing guard
rather than an incidental test update.

### Open UX question for owner review

Section 15 forbids using a new arbitrary Custom value to bypass an unavailable
recommendation. The implementation follows that literally: when a
recommendation is underivable the editor offers turn-on and turn-off but no
value entry, and the row reads "Unavailable". A user under 19, or with no date
of birth, can therefore enable a goal that shows nothing and cannot be set.
That is the behaviour the frozen policy implies, but it is a dead end worth an
explicit product decision — either accept it, or decide such nutrients should
not be enableable at all until the inputs exist. No behaviour was invented
beyond the contract.

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-141-additional-nutrient-goals-v1.md
supabase/migrations/20260902041627_add_nutrition_additional_nutrient_goals.sql

apps/core/lib/src/routing/routes/app_routes.dart

apps/features/nutrition/lib/src/domain/models/additional_nutrient_goal.dart
apps/features/nutrition/lib/src/domain/models/nutrient_recommendation.dart
apps/features/nutrition/lib/src/domain/models/nutrition_targets_data.dart
apps/features/nutrition/lib/src/domain/models/models.dart
apps/features/nutrition/lib/src/domain/repositories/nutrition_targets_repository.dart
apps/features/nutrition/lib/src/domain/usecases/additional_nutrient_recommendation_policy.dart
apps/features/nutrition/lib/src/domain/usecases/nutrition_target_editor.dart
apps/features/nutrition/lib/src/domain/usecases/usecases.dart
apps/features/nutrition/lib/src/data/additional_nutrient_goals_v1_codec.dart
apps/features/nutrition/lib/src/data/in_memory_nutrition_targets_repository.dart
apps/features/nutrition/lib/src/data/repositories/supabase_nutrition_targets_repository.dart
apps/features/nutrition/lib/src/data/data.dart
apps/features/nutrition/lib/src/presentation/pages/additional_nutrient_goals_page.dart
apps/features/nutrition/lib/src/presentation/pages/nutrition_targets_settings_page.dart
apps/features/nutrition/lib/src/presentation/pages/pages.dart

apps/features/nutrition/test/domain/additional_nutrient_recommendation_policy_test.dart
apps/features/nutrition/test/domain/additional_nutrient_goal_set_test.dart
apps/features/nutrition/test/data/additional_nutrient_goals_v1_codec_test.dart
apps/features/nutrition/test/data/additional_nutrient_goals_persistence_test.dart
apps/features/nutrition/test/presentation/additional_nutrient_goals_page_test.dart
apps/features/nutrition/test/presentation/nutrition_targets_settings_page_test.dart

apps/app/lib/app/router.dart
apps/app/test/app/nutrition_settings_route_test.dart
```

### Actual Behavior

Settings → Nutrition & Diet → Nutrition Targets now carries an ADDITIONAL
section linking to a nested Additional Nutrient Goals screen. That screen lists
exactly saturated fat, trans fat, sodium and vitamin D. Each row reads Not set,
the effective amount with a Recommended or Custom caption, or Unavailable.
Tapping a row opens an editor offering a custom override, Use Recommended, and
turn off; sodium's guidance states the strict "less than 2,000 mg/day"
boundary. Recommendations are derived at runtime from canonical Calories and
Profile date of birth and are never stored. Core-five targets are unchanged in
value, provenance and write path.

### Known Limitations

- Hosted Supabase is unmigrated; the column does not exist in production yet,
  so the screen will read an absent column as "no goals configured" until the
  migration is authorized and the ledger repaired.
- Old-client preservation is proven at the request-payload boundary rather than
  against a live PostgREST instance, because the local Supabase stack cannot
  run in this environment.
- The unavailable-recommendation enable path is a product question, recorded
  above.

### Final Status

`AWAITING REVIEW` — implementation and validation complete; Draft PR, hosted
migration authorization and physical-device acceptance remain.
