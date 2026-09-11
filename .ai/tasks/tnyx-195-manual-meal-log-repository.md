# TNYX-195 — N20A-6 Manual MealLog repository & Supabase adapter foundation

**Status:** Validated — PR #254 review findings resolved; ready for final review
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
**Review owner:** Owner / manual PR review
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-11
**Branch:** `tnyx/tnyx-195-n20a-6-manual-meallog-repository-supabase-adapter-foundation`
**HEAD SHA:** validated source/fix head `b83d96970943cf1c9c62f72e035ed8406f1465e1`; this handoff reconciliation is docs-only
**Observed working-tree state:** Connector-managed remote branch. A local clone could not be created because the container has no outbound GitHub DNS/network access; GitHub API ancestry/scope evidence was used per `docs/PUSH_TEMPLATE.md`.
**Observed uncommitted/dirty files:** Not observable through GitHub connector; all writes were isolated to the TNYX-195 branch.
**PR / tracker:** PR #254; Linear TNYX-195 `In Review`
**Current implementation state:** Bounded repository contract, Supabase adapter/gateway, active Meal Category create validation, strict instant decoding, non-durable fallback, app composition, and focused tests implemented and validated. P1/P2 review threads are resolved.
**Relevant execution surface:** `apps/features/nutrition` domain/data/tests plus `apps/app/lib/app/meal_log_repository_provider.dart` and its focused test
**Validation completed at SHA:** `b83d96970943cf1c9c62f72e035ed8406f1465e1`
**Validation remaining:** Final exact-head review of this docs-only reconciliation and PR metadata. No implementation-source validation remains.
**Current blocker:** None
**Open review finding IDs:** None; `P1-active-meal-category-write-integrity` and `P2-explicit-instant-offset-decoding` are resolved at `b83d969` with CI #2373.
**Next exact action:** Reconcile PR body to the current validated evidence, perform final exact-head review, then move PR #254 from Draft to Ready for review. Do not merge, enable Quick Add, add idempotency fields, or widen schema from this handoff.

## Global UI / Design-System Guardrail

No Flutter production UI or visible product behavior changed. Quick Add remains visually and behaviorally unchanged with `Log Meal` disabled.

## 1. Discovery

### User Outcome

Establish the canonical app-side persistence boundary between manual `MealLogEntry` semantics and the already-live Supabase `meal_log_entries` table so a later reliability slice can safely wire Quick Add without widgets calling Supabase or inventing a second history owner.

### Success Criteria

- One Nutrition `MealLogRepository` contract exists for the bounded manual create/read foundation.
- Create does not require a caller-fabricated DB row ID or database timestamps; the durable inserted row is returned as canonical `MealLogEntry`.
- Supabase access is behind an injectable gateway and derives `user_id` from the authenticated session, never from caller input.
- New MealLog writes require a current active resolved Meal Category identity; missing/archived IDs fail before persistence while historical reads retain archived identities.
- Exact current manual fields round-trip through existing shared codecs.
- Persisted timestamps decode only when they encode an explicit instant (`Z` or numeric UTC offset), avoiding device-timezone-dependent reinterpretation.
- Signed-out Supabase access fails closed before gateway mutation/read.
- App composition selects Supabase in configured sessions and an explicitly non-durable in-memory fallback otherwise.
- Quick Add remains disabled and no database shape changes occur.

### Scope

Nutrition domain repository contract + data adapters/mapping + app provider composition + focused tests + active task handoff.

### Non-Goals

TNYX-115 UI lifecycle, TNYX-116 mutation reliability, detailed item persistence, read-model aggregation, media, serving semantics, schema changes, backend services, monetization.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root/nested `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, task template, root/docs architecture references, TNYX-194 handoff, current Nutrition repositories/data exports, current app composition, Quick Add source, shared `MealLogEntry`, `NutritionSnapshot`, `MealLogLocalDate`, mode/capture-source contracts, Supabase live table state, Linear TNYX-113/115/116/194/195.
- Existing pattern followed: Nutrition repository contract → injectable Supabase table gateway/adapter → app Riverpod composition with in-memory fallback.
- Live Supabase state: `public.meal_log_entries` already exists with TNYX-194 RLS/grants/index/trigger/manual contract; this task introduced no migration.
- Current Supabase Dart reference confirms `.insert(...).select()` returns inserted rows, allowing DB-generated UUID/timestamps to hydrate the canonical aggregate.
- TNYX-194 locked DB UUID ↔ opaque domain `String` identity and deliberately deferred repository/idempotency wiring.
- TNYX-67 locked Meal Category integrity at the Nutrition domain/repository boundary because categories remain JSONB rather than relational FK targets: new logs require an active resolved ID; archived IDs remain valid historical identity only.
- Quick Add still owns only route-local draft state and has no primary submit callback.
- Documentation drift was observed but intentionally not bundled: stale older `backend/*`/future-Supabase wording remains in parts of general docs while root `AGENTS.md`, root README and `ARCHITECTURE.md` are current authority.

### Tests or validation already present

- Shared tests cover `MealLogEntry.manual`, `NutritionSnapshot`, and local-date semantics.
- Existing Nutrition repository tests established the injectable-gateway style.
- TNYX-194 database matrix already validates physical schema/RLS/grants/index/trigger/validator behavior; no DB test change was needed.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Repository lives in Nutrition feature domain | Locked | Keeps persistence semantics out of app shell/widgets and follows existing Nutrition ownership | Existing pattern / TNYX-195 |
| Create input carries no `id`, `userId`, `mode`, `createdAt`, or `updatedAt` | Locked | DB/session own those facts; avoids fake identity/timestamps and future idempotency confusion | TNYX-194/TNYX-116 boundary |
| `createManual` returns persisted `MealLogEntry` | Locked | Hydrates DB UUID/default timestamps and preserves one canonical aggregate | TNYX-195 |
| Minimal read API is `readById` | Locked for this slice | Proves canonical decoding without prematurely freezing Diary query APIs | Bounded foundation |
| New writes require an active resolved Meal Category ID | Locked | No DB FK exists for JSONB categories; invalid/archived new writes must fail without remapping while historical reads stay resolvable | TNYX-67 / P1 review |
| Persisted timestamps require explicit instant offset | Locked | Offset-less parsing would depend on the device timezone and violate canonical-instant semantics | TNYX-114 / P2 review |
| Supabase signed-out create/read fail closed | Locked | Missing auth is not equivalent to empty durable history | Security boundary |
| In-memory fallback uses local synthetic identity only | Locked | Test/local constructibility without pretending durability | Existing composition pattern |
| Unknown future mode/capture source fails instead of remapping | Locked | Guessing would fabricate semantic meaning | Shared contracts |
| Unknown future nutrient identities remain forward-compatible | Locked | Existing `NutritionSnapshot.fromJson` ignores unknown nutrient identities while validating known values | Shared codec |

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

`ManualMealLogCreate` is a creation command, not a competing persisted DTO. It carries only manual meal facts already resolved by the responsible feature boundary. Supabase/session/database own user identity, row UUID and timestamps.

### Ownership and Data Flow

```text
Future Nutrition controller
→ MealLogRepository
→ feature-owned data adapter/gateway
→ Supabase Postgres + existing RLS
```

`apps/app` owns only provider composition. Presentation remains untouched.

### Alternative Rejected

- Passing a fully constructed `MealLogEntry` into create: would require caller-fabricated DB identity/timestamps.
- Client-generating physical row UUID: unnecessary and risks conflating row identity with TNYX-116 mutation identity.
- Widget/raw-Supabase access: violates feature/data ownership.
- Adding Diary/date-range reads now: prematurely freezes later read-model semantics.
- Adding update/delete now: prematurely couples this foundation to TNYX-115/TNYX-116 concurrency semantics.

### Failure and Accessibility States

No UI/accessibility state changes. Signed-out durable access fails before gateway calls. Missing/archived Meal Category IDs fail before create persistence. Malformed/unsupported returned rows, including offset-less timestamps, fail explicitly rather than being guessed or defaulted.

## 5. Implementation Plan

- [x] Reconcile Linear/GitHub/current source/Supabase state
- [x] Read required root/nested agent and workflow guidance
- [x] Create isolated TNYX-195 branch from exact current `main`
- [x] Move Linear TNYX-195 to `In Progress`
- [x] Add `ManualMealLogCreate` + `MealLogRepository`
- [x] Add deterministic non-durable `InMemoryMealLogRepository`
- [x] Add `MealLogTableGateway` + `SupabaseMealLogRepository` with strict row decoding
- [x] Export new domain/data contracts
- [x] Add app-level `mealLogRepositoryProvider`
- [x] Add focused Nutrition repository/mapping tests
- [x] Add focused app provider selection tests
- [x] Audit exact base-to-head scope and open Draft PR #254
- [x] Run repository Flutter CI at initial implementation head
- [x] Resolve P1 active-category write integrity finding in both repository implementations
- [x] Resolve P2 explicit-instant timestamp decoding finding
- [x] Run full Flutter CI at exact review-fix head `b83d969`
- [x] Reply to and resolve both GitHub review threads with exact-head validation evidence
- [x] Refresh task handoff for final review

## 6. Quality Review

### Validation Run

Validated source/fix head: `b83d96970943cf1c9c62f72e035ed8406f1465e1`.

Flutter CI run #2373 / `34603902661` passed every gate on that exact head:

```text
Bootstrap workspace          PASS
Analyze Flutter packages     PASS
Analyze Dart packages        PASS
Test Flutter packages        PASS
Test Dart packages           PASS
```

Earlier implementation head `a969540c86ae544babae86feff72971a42a2a568` also passed Flutter CI run #2371 / `34601813672`; that result is historical evidence only after review fixes moved source HEAD.

GitHub API scope audit against `main@618df923ce2d6ec01f0055a1cc456ac5f6d4d63f` at source/fix head `b83d969`:

```text
merge base = declared base   PASS
ahead / behind = 4 / 0       PASS
changed files = 10           PASS; all TNYX-195 owned paths
```

Local `git status`/`git diff --check` could not be run because no repository checkout is mounted and outbound `git clone` is unavailable in the container. Per `docs/PUSH_TEMPLATE.md`, equivalent GitHub API ancestry, commit and complete changed-file evidence was collected and reviewed. No local validation is claimed.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| `P1-active-meal-category-write-integrity` | P1 | Resolved | New writes could persist a missing/archived/arbitrary `mealCategoryId` despite the TNYX-67 repository-owned integrity contract | `a13e75a9` | Fixed at `b83d969`: both Supabase and in-memory create paths validate current resolved active category; focused tests + CI #2373 pass; GitHub thread resolved |
| `P2-explicit-instant-offset-decoding` | P2 | Resolved | Offset-less timestamp strings could be interpreted through device-local timezone before `.toUtc()` | `a13e75a9` | Fixed at `b83d969`: decoder requires `Z` or `±HH:MM`; rejection/normalization tests + CI #2373 pass; GitHub thread resolved |

Manual final review after these fixes found no new P1/P2 blocker. Provider placement in a dedicated app composition file and the duplicated two-implementation active-category guard remain non-blocking organization/refactor considerations and are not widened into this slice.

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-195-manual-meal-log-repository.md
apps/features/nutrition/lib/src/domain/repositories/meal_log_repository.dart
apps/features/nutrition/lib/src/domain/repositories/repositories.dart
apps/features/nutrition/lib/src/data/in_memory_meal_log_repository.dart
apps/features/nutrition/lib/src/data/repositories/supabase_meal_log_repository.dart
apps/features/nutrition/lib/src/data/data.dart
apps/features/nutrition/test/data/in_memory_meal_log_repository_test.dart
apps/features/nutrition/test/data/supabase_meal_log_repository_test.dart
apps/app/lib/app/meal_log_repository_provider.dart
apps/app/test/app/meal_log_repository_provider_test.dart
```

### Actual Behavior

- Defines one canonical Nutrition `MealLogRepository` manual create/read foundation.
- Uses `ManualMealLogCreate` so callers cannot fabricate persisted row UUID/user/mode/database timestamps.
- Supabase adapter derives current authenticated `user_id`, validates the selected Meal Category against current resolved active categories, inserts only canonical manual facts, then hydrates the returned DB-generated row into `MealLogEntry.manual`.
- In-memory fallback enforces the same active-category create invariant while remaining explicitly non-durable.
- Historical `readById` does not revalidate category activity, so retained archived category identities remain readable without remapping.
- Strict decoding checks required columns, authenticated ownership, manual mode, known capture-source identity, explicit-offset timestamps, local-date/snapshot shape and required timezone context.
- `NutritionSnapshot` remains the only nutrition truth and preserves current missing-vs-explicit-zero/unknown-future-nutrient behavior.
- Adds app-level Riverpod selection between Supabase and in-memory implementations.
- Does not alter Quick Add, Supabase schema, RLS/grants/indexes/functions, or reliability semantics.

### Known Limitations

Quick Add remains disabled. Create idempotency/retry/offline safety, edit/delete/concurrency, detailed item/serving semantics, Diary aggregate/read models and media remain intentionally deferred to their dedicated slices.

### Final Status

`REVIEW` — bounded implementation and both review fixes are validated. PR #254 may move to Ready for review after this docs-only handoff/PR metadata reconciliation is exact-head reviewed. Merge still requires separate owner authorization.