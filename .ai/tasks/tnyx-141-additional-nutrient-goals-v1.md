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
**Current implementation state:** Baseline gates passed; implementation not started
**Relevant execution surface:** `apps/features/nutrition`, `apps/app`, `apps/core` route contract, `supabase/migrations`
**Validation completed at SHA:** Read-only Git/Linear/GitHub/hosted-schema baseline only
**Validation remaining:** Domain/data/widget/route tests, analyzer, formatting, migration validation, local PostgREST compatibility proof, physical-device checklist, exact-head CI
**Current blocker:** Local Docker/Supabase CLI availability is not yet established; hosted migration ledger mismatch remains a rollout gate, not an implementation blocker
**Open review finding IDs:** None
**Next exact action:** Implement typed contracts and V1 persistence codec, then create the additive local migration using the canonical Supabase CLI flow.

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

- [ ] Add typed goal/recommendation contracts and pure policy tests.
- [ ] Add V1 persistence codec and repository preservation tests.
- [ ] Create one canonical additive local migration.
- [ ] Add the nested route and feature-owned goals screen.
- [ ] Add widget and route-level persistence/preservation tests.
- [ ] Prove old-client semantics through local PostgREST.
- [ ] Run focused and package-level validation plus self-review.
- [ ] Commit, push, open reviewed Draft PR, and attach exact evidence to Linear.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Task brief only so far.

### Actual Behavior

No runtime behavior changed yet.

### Known Limitations

Hosted migration remains not applied. Physical-device acceptance and exact-head
CI remain downstream gates.

### Final Status

`PARTIAL`
