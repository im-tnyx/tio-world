# TNYX-195 — N20A-6 Manual MealLog repository & Supabase adapter foundation

**Status:** In progress
**Primary owner:** Nutrition domain/data + app composition
**Affected platforms:** Flutter Nutrition package + mobile app composition; no visible UI change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner created/approved the bounded TNYX-195 scope on 2026-09-11 and explicitly instructed implementation to proceed after the read-only readiness audit.
**Approved product/UI/data-shape boundaries:** One Nutrition-owned `MealLogRepository` manual create/read foundation, Supabase adapter/gateway over the already-live `public.meal_log_entries` table, canonical row mapping, deterministic non-durable in-memory fallback, app Riverpod composition, and focused tests.
**Explicit non-changes:** No Quick Add `Log Meal` activation, no edit/delete UI, no controller submit state, no idempotency/offline/concurrency contract, no detailed `MealLogItemSnapshot`, no serving/serving-size, no media, no Diary derived reads, no Supabase schema/RLS/grant/index/function change, no `services/api`, no membership/ads.

## Active Handoff

**Planning owner:** TNYX-113 / TNYX-195
**Implementation owner:** ChatGPT
**Review owner:** Owner / later PR review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-11
**Branch:** `tnyx/tnyx-195-n20a-6-manual-meallog-repository-supabase-adapter-foundation`
**HEAD SHA:** Branch created from `618df923ce2d6ec01f0055a1cc456ac5f6d4d63f`; refresh after implementation checkpoint
**Observed working-tree state:** Connector-managed remote branch; no local checkout is mounted in this session
**Observed uncommitted/dirty files:** Not observable through GitHub connector; writes are isolated to the TNYX-195 branch
**PR / tracker:** Linear TNYX-195 `In Progress`; no PR yet
**Current implementation state:** Readiness reconciled; source edits not yet started
**Relevant execution surface:** `apps/features/nutrition` domain/data, `apps/app/lib/app/network_providers.dart`, focused tests
**Validation completed at SHA:** None for TNYX-195 yet
**Validation remaining:** Focused Nutrition tests/analyze, app provider tests/analyze, branch diff review, CI if PR is opened
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Implement the bounded repository contract, adapter/fallback, composition and focused tests without touching UI or Supabase schema.

## Global UI / Design-System Guardrail

No Flutter production UI or visible product behavior is changed by this task. Quick Add remains visually and behaviorally unchanged with `Log Meal` disabled.

## 1. Discovery

### User Outcome

Establish the canonical app-side persistence boundary between manual `MealLogEntry` semantics and the already-live Supabase `meal_log_entries` table so a later reliability slice can safely wire Quick Add without widgets calling Supabase or inventing a second history owner.

### Success Criteria

- One Nutrition `MealLogRepository` contract exists for the bounded manual create/read foundation.
- Create does not require a caller-fabricated DB row ID or database timestamps; the durable inserted row is returned as canonical `MealLogEntry`.
- Supabase access is behind an injectable gateway and derives `user_id` from the authenticated session, never from caller input.
- Exact current manual fields round-trip through the existing shared codecs.
- Signed-out Supabase access fails closed before gateway mutation/read.
- App composition selects Supabase in configured sessions and an explicitly non-durable in-memory fallback otherwise.
- Quick Add remains disabled and no database shape changes occur.

### Scope

Nutrition domain repository contract + data adapters/mapping + app provider composition + focused tests + active task handoff.

### Non-Goals

TNYX-115 UI lifecycle, TNYX-116 mutation reliability, detailed item persistence, read-model aggregation, media, serving semantics, schema changes, backend services, monetization.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root/nested `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, task template, root/docs architecture references, TNYX-194 handoff, current Nutrition repositories/data exports, `network_providers.dart`, Quick Add source, shared `MealLogEntry`, `NutritionSnapshot`, `MealLogLocalDate`, mode/capture-source value contracts, Supabase live table state, Linear TNYX-113/115/116/194/195.
- Existing pattern to follow: `MealCategoriesRepository` → injectable Supabase table gateway/adapter → `apps/app` Riverpod composition with an in-memory fallback.
- Multi-row history precedent: `SupabaseBodySetupRepository` reads/writes authenticated user-owned log rows while keeping persistence out of widgets.
- Live Supabase state: `public.meal_log_entries` exists with RLS and the TNYX-194 manual contract; this task requires no migration.
- Current Supabase Dart reference confirms `.insert(...).select()` returns inserted rows, allowing DB-generated UUID/timestamps to hydrate the canonical aggregate.
- TNYX-194 locked DB UUID ↔ opaque domain `String` identity and deliberately deferred repository wiring/idempotency.
- Quick Add currently owns only route-local draft state and still has no primary submit callback.
- No open TNYX-195 branch/PR overlap existed before this branch was created.
- Documentation drift observed but out of scope: portions of `MODULE_OWNERSHIP.md`, `DEVELOPMENT_SETUP.md`, and `SUPABASE_STRATEGY.md` still describe older future `backend/*`/Supabase state; root `AGENTS.md`, root README and `ARCHITECTURE.md` are current authority.

### Tests or validation already present

- Shared tests cover `MealLogEntry.manual`, `NutritionSnapshot`, and local-date semantics.
- Nutrition repository tests provide the preferred injectable-gateway test style.
- App `network_providers_test.dart` covers Supabase-vs-in-memory repository composition.
- TNYX-194 database matrix already validated physical table/RLS/grants/index/trigger/validator behavior; no DB test change is needed here.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Repository lives in Nutrition feature domain | Chosen | Matches existing feature repository ownership and keeps persistence semantics out of app shell/widgets | Existing Nutrition pattern |
| Create input carries no `id`, `userId`, `mode`, `createdAt`, or `updatedAt` | Chosen | DB/session own those facts; avoids fabricated identity/timestamps and avoids conflating row ID with future idempotency identity | TNYX-194/TNYX-116 boundary |
| `createManual` returns persisted `MealLogEntry` | Chosen | Hydrates DB UUID/default timestamps and leaves canonical aggregate as product truth | TNYX-195 |
| Minimal read API is `readById` | Chosen | Exercises canonical decoding and supports future edit handoff without prematurely freezing Diary query/read-model APIs | Bounded foundation |
| Supabase signed-out create/read fail closed | Chosen | Missing auth is not equivalent to empty durable history | Security boundary |
| In-memory fallback uses local synthetic identity only | Chosen | Keeps no-Supabase test/local composition constructible while remaining explicitly non-durable | Existing composition pattern |
| Unknown future mode/capture source fails rather than remapping | Locked | Guessing would fabricate semantic meaning | Shared value contracts |
| Unknown future nutrient keys remain forward-compatible | Locked | Existing `NutritionSnapshot.fromJson` ignores unknown nutrient identities while validating known data | Shared codec |

## 4. Architecture Design

### Chosen Approach

```text
ManualMealLogCreate
        ↓
MealLogRepository
        ├─ InMemoryMealLogRepository        // test/local only, non-durable
        └─ SupabaseMealLogRepository
               ↓
        MealLogTableGateway
               ↓
        public.meal_log_entries
               ↓ returned persisted row
        canonical MealLogEntry.manual
```

`ManualMealLogCreate` is a command/input, not a competing persisted DTO. It contains only user-entered/resolved manual meal facts. The persisted result remains the canonical `MealLogEntry`.

### Ownership and Data Flow

```text
Future Nutrition controller
→ MealLogRepository
→ feature-owned data adapter/gateway
→ Supabase Postgres + existing RLS
```

`apps/app` owns only provider composition. Presentation remains untouched.

### Alternative Rejected

- Passing a fully constructed `MealLogEntry` into create: would require fake/client-generated DB identity and timestamps before persistence.
- Generating the physical row UUID in the client: unnecessary because the table already owns `gen_random_uuid()` and risks future confusion with TNYX-116 mutation identity.
- Letting widgets call `SupabaseClient.from('meal_log_entries')`: violates feature/data ownership and existing repository rules.
- Adding Diary/date-range query APIs now: prematurely freezes read-model behavior owned by later Nutrition diary slices.
- Adding update/delete now: prematurely couples this foundation to TNYX-115/TNYX-116 concurrency semantics.

### Failure and Accessibility States

No UI/accessibility state changes. Repository failures propagate to later controllers. Invalid/malformed returned rows fail explicitly; signed-out Supabase access throws before gateway calls.

## 5. Implementation Plan

- [x] Reconcile Linear/GitHub/current source/Supabase state
- [x] Read required root/nested agent and workflow guidance
- [x] Create isolated TNYX-195 branch from exact current `main`
- [x] Move Linear TNYX-195 to `In Progress`
- [ ] Add `ManualMealLogCreate` + `MealLogRepository`
- [ ] Add deterministic non-durable `InMemoryMealLogRepository`
- [ ] Add `MealLogTableGateway` + `SupabaseMealLogRepository` with strict row mapper
- [ ] Export new domain/data contracts
- [ ] Add `mealLogRepositoryProvider` in app composition
- [ ] Add focused Nutrition repository/mapping tests
- [ ] Extend app provider selection tests
- [ ] Run smallest meaningful validation and inspect branch diff
- [ ] Refresh task handoff and reconcile Linear to actual review state

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Not finalized.

### Actual Behavior

Not finalized.

### Known Limitations

Quick Add remains disabled; no idempotency/offline/concurrency/edit/delete/detailed-item/Diary aggregate behavior is included.

### Final Status

`PARTIAL` — implementation in progress.
