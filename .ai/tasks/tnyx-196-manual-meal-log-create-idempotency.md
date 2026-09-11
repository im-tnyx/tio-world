# TNYX-196 — Manual MealLog create idempotency & retry reconciliation

**Status:** Ready
**Primary owner:** Nutrition
**Affected platforms:** Flutter phone app + Supabase persistence

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-11 after the TNYX-116 manual-create reliability readiness audit proposed the bounded slice, V1 online-required final-save policy, and exact additive `client_mutation_id` shape.
**Approved product/UI/data-shape boundaries:** Add nullable `public.meal_log_entries.client_mutation_id uuid`; enforce owner-scoped uniqueness with `UNIQUE (user_id, client_mutation_id)`; use one stable mutation identity for one logical manual-create attempt; retry/reconciliation reuses that identity; V1 final save is online-required with local draft preserved on failure.
**Explicit non-changes:** No Quick Add activation or visible UI/UX change; no edit/delete concurrency; no `version` field; no durable offline queue; no detailed item persistence; no Diary selected-day read model/cards/totals; no `services/api`; no service-role client; no ads/membership work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** Not assigned / not started
**Review owner:** Not assigned
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main` at `7370189856159b465c56fabd77d28a2f68548238`; TNYX-196 branch created from that exact SHA. Owner separately reported local `main...origin/main` clean/aligned after PR #254 post-merge sync.
**Branch:** `tnyx/tnyx-196-n20d-1-manual-meallog-create-idempotency-retry`
**HEAD SHA:** task-brief commit created after base `7370189856159b465c56fabd77d28a2f68548238`
**Observed working-tree state:** No mounted checkout in this agent session; remote branch isolated from fresh GitHub `main`.
**Observed uncommitted/dirty files:** Not observable in this session; owner last reported clean local `main` before this branch was created remotely.
**PR / tracker:** Linear `TNYX-196`, parent `TNYX-116`; no PR yet.
**Current implementation state:** Planning/readiness only. No migration, repository, UI, or live Supabase mutation has been performed for TNYX-196.
**Relevant execution surface:** `supabase/migrations/*`, `supabase/tests/database/*`, `apps/features/nutrition/lib/src/domain/repositories/meal_log_repository.dart`, `apps/features/nutrition/lib/src/data/repositories/supabase_meal_log_repository.dart`, `apps/features/nutrition/lib/src/data/in_memory_meal_log_repository.dart`, focused Nutrition repository tests.
**Validation completed at SHA:** Readiness audit only; no TNYX-196 implementation validation yet.
**Validation remaining:** migration/database tests, RLS/ownership regression checks, focused repository tests, workspace analyze/test, exact-head diff review.
**Current blocker:** None for planning. Implementation requires a separate explicit owner `Go` because this checkpoint intentionally stops before source/schema changes even though the exact shape is already approved.
**Open review finding IDs:** None.
**Next exact action:** On owner `Go`, move TNYX-196 to `In Progress`, verify branch/base/overlap again, then implement the approved additive idempotency migration and bounded manual-create repository reconciliation with tests.

## Global UI / Design-System Guardrail

No production UI change is in scope. If later work touches Quick Add presentation, stop and run the Flutter UI/design-system gate separately; TNYX-196 must preserve current rendering and disabled `Log Meal` behavior.

## 1. Discovery

### User Outcome

Prevent one logical manual MealLog create from becoming duplicate nutrition history when the database commit succeeds but the response is lost, the client retries, or equivalent ambiguous network behavior occurs.

### Success Criteria

- one logical manual-create attempt has one stable `clientMutationId`;
- the database provides the final duplicate guard per authenticated owner;
- retry/reconciliation with the same mutation identity returns/converges on the same durable MealLogEntry instead of inserting a duplicate;
- existing historical rows migrate without backfill requirements;
- signed-out and active-category safety remain unchanged;
- V1 does not claim offline durable success;
- Quick Add remains disabled in this slice.

### Scope

- additive nullable UUID mutation identity on `meal_log_entries`;
- owner-scoped unique database invariant;
- manual-create repository/input/gateway mapping and reconciliation only;
- deterministic in-memory equivalent;
- focused database/repository tests;
- minimal failure classification required to distinguish safe reconciliation from a new logical attempt.

### Non-Goals

- edit/update stale-write/version contract;
- delete idempotency;
- durable offline queue/replay;
- background jobs/queues/workers;
- detailed MealLog items/atomic detailed aggregate save;
- selected-day Diary list/read models or UI refresh;
- Quick Add submit wiring/button enablement;
- broad TNYX-116 completion.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - root `AGENTS.md` and `apps/features/AGENTS.md`;
  - `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`;
  - `apps/features/nutrition/.../meal_log_repository.dart`;
  - `apps/features/nutrition/.../supabase_meal_log_repository.dart`;
  - current Quick Add editor/runtime shell;
  - TNYX-194 migration;
  - live `public.meal_log_entries` columns, indexes, and RLS policies;
  - Linear TNYX-113/114/115/116/194/195 and completed manual-path children.
- Existing pattern to follow:
  - Nutrition-owned repository contract + injectable Supabase table gateway;
  - authenticated owner identity from Supabase session;
  - RLS as final ownership authority;
  - strict canonical row decoding;
  - database-enforced invariant rather than client-only pre-check for duplicate safety.
- Tests or validation already present:
  - TNYX-194 migration/RLS database tests;
  - TNYX-195 Supabase repository + in-memory repository + app-composition tests;
  - PR #254 exact-head Flutter/Dart analyze/tests passed before merge.

Current live schema evidence at readiness:

```text
meal_log_entries
- id uuid PK default gen_random_uuid()
- user_id uuid NOT NULL
- manual MealLog fields from TNYX-194
- NO client_mutation_id
- NO version field

indexes
- meal_log_entries_pkey(id)
- idx_meal_log_entries_user_local_date_consumed_at(user_id, consumed_local_date, consumed_at DESC)

RLS
- own-row SELECT/INSERT/UPDATE/DELETE for authenticated
```

Current repository evidence:

```text
MealLogRepository
- createManual(ManualMealLogCreate)
- readById(String)

SupabaseMealLogRepository
- validates authenticated owner
- validates active Meal Category
- inserts one row and returns hydrated DB identity/timestamps
- explicitly performs no retries/idempotency reconciliation today
```

Tracker/runtime drift recorded:

- TNYX-113 remains a broad Backlog umbrella even though manual-path children TNYX-188 through TNYX-195 are complete. TNYX-196 uses those completed manual prerequisites and does not pretend detailed-item work is complete.
- `docs/SUPABASE_STRATEGY.md` still mentions a future `backend/` namespace. Current root `AGENTS.md` is authoritative for repository direction and permits only future `services/api`; TNYX-196 introduces neither.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| V1 offline final-save policy = online-required; no offline-success/queue | Approved | Smallest safe V1; avoids half-offline durable uncertainty | Owner |
| Add `client_mutation_id uuid NULL` to `meal_log_entries` | Approved | Stable mutation identity must survive ambiguous response loss | Owner |
| Enforce `UNIQUE (user_id, client_mutation_id)` | Approved | Database must close concurrent/pre-check race; null keeps old rows compatible | Owner |
| Keep mutation identity distinct from MealLog row `id` | Approved | Row identity and logical create-attempt identity have different semantics | Owner |
| Retry/reconcile same logical attempt with same mutation ID | Approved | Prevent duplicate actual-history effects | Owner |
| Do not add `version` in this slice | Approved boundary | Edit concurrency remains a later TNYX-116 child | Owner |

## 4. Architecture Design

### Chosen Approach

Conceptual create flow:

```text
manual-create caller/controller (future TNYX-115)
  -> stable clientMutationId generated once per logical create attempt
  -> MealLogRepository.createManual(..., clientMutationId)
  -> validate auth + active Meal Category
  -> Supabase gateway create/reconcile
       -> database uniqueness (user_id, client_mutation_id)
       -> successful first insert returns canonical row
       -> same-key retry/conflict reconciles to canonical existing row
  -> canonical MealLogEntry
```

The exact PostgREST/RPC-free reconciliation implementation must be chosen during implementation from current Supabase client behavior and tested against the database invariant. Do not use a client-only `read then insert` check as the sole guard.

### Ownership and Data Flow

```text
future Quick Add controller (not this slice)
  -> Nutrition MealLogRepository
  -> SupabaseMealLogRepository / MealLogTableGateway
  -> public.meal_log_entries + own-row RLS + unique mutation invariant
```

`apps/app` remains composition-only. No widget calls Supabase.

### Alternative Rejected

- **Disable submit button only:** rejects rapid double taps but does not protect response-loss/retry ambiguity.
- **Generate a new mutation ID on every retry:** converts one logical attempt into multiple durable effects and defeats idempotency.
- **Use MealLog row UUID as client mutation identity:** conflates store-owned row identity with client logical-operation identity and breaks the TNYX-195 ownership boundary.
- **Durable offline queue now:** broader product/storage/lifecycle surface than needed for the first safe create path.
- **Add `version` now:** premature; belongs to edit concurrency, not manual create dedupe.

### Failure and Accessibility States

No visible UI changes in TNYX-196. The repository/data contract must distinguish at least:

```text
confirmed durable success
known failure before durable commit
auth/domain validation failure
ambiguous/duplicate-create path requiring same-key reconciliation
```

Future TNYX-115 owns how these states are presented. It must not treat an ambiguous outcome as a fresh logical create.

## 5. Implementation Plan

- [ ] Freshly verify `main`, branch ancestry, Linear state, and PR/branch overlap.
- [ ] Move TNYX-196 to `In Progress` when source implementation begins.
- [ ] Add approved additive migration for nullable `client_mutation_id uuid`.
- [ ] Add owner-scoped unique invariant without changing existing row ownership/RLS.
- [ ] Extend Supabase database tests for null-history compatibility, uniqueness, cross-owner semantics, and own-row access.
- [ ] Extend `ManualMealLogCreate` with stable mutation identity while preserving DB-owned MealLog row identity/timestamps.
- [ ] Extend table gateway/repository create reconciliation so same owner + same mutation ID converges on one canonical row.
- [ ] Add deterministic equivalent to `InMemoryMealLogRepository`.
- [ ] Preserve active Meal Category validation, signed-out fail-closed behavior, time/local-date, snapshot, and capture-source contracts.
- [ ] Add focused tests for first create, same-key retry, concurrent/duplicate conflict reconciliation seam, and distinct-key independent creates.
- [ ] Keep Quick Add UI disabled and untouched.
- [ ] Run Supabase database validation plus proportional Flutter/Dart analyze/tests.
- [ ] Audit exact base-to-head scope and prepare review handoff; no merge without separate owner authorization.

## 6. Quality Review

### Validation Run

```text
Not run yet. No TNYX-196 source/schema implementation has started.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Planning checkpoint only:

- `.ai/tasks/tnyx-196-manual-meal-log-create-idempotency.md`

### Actual Behavior

No runtime/database behavior changed at this checkpoint. The approved scope, exact data-shape decision, ownership, risks, and validation plan are now durable and branch-isolated.

### Known Limitations

- Quick Add remains disabled.
- Diary actual-history read/display remains separate.
- TNYX-116 still owns later edit/delete/concurrency/offline/read-model reliability.
- `docs/SUPABASE_STRATEGY.md` contains known future-backend namespace drift; current `AGENTS.md` governs and this slice does not touch backend runtime.

### Final Status

`REVIEW`
