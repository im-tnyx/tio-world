# TNYX-196 — Manual MealLog create idempotency & retry reconciliation

**Status:** Validated — ready for final review; merge requires separate owner authorization
**Primary owner:** Nutrition
**Affected platforms:** Flutter phone app + Supabase persistence

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-11 after the TNYX-116 manual-create reliability readiness audit proposed this bounded slice, the V1 online-required final-save policy, and the exact additive `client_mutation_id` shape; owner then said `Go` again to begin implementation.
**Approved product/UI/data-shape boundaries:** Add nullable `public.meal_log_entries.client_mutation_id uuid`; enforce owner-scoped uniqueness with `UNIQUE (user_id, client_mutation_id)`; use one stable mutation identity for one logical manual-create attempt; retry/reconciliation reuses that identity; V1 final save is online-required with the caller preserving the same draft/mutation identity on failure.
**Explicit non-changes:** No Quick Add activation or visible UI/UX change; no edit/delete concurrency; no `version` field; no durable offline queue; no detailed item persistence; no Diary selected-day read model/cards/totals; no `services/api`; no service-role client; no ads/membership work.

## Active Handoff

**Planning / implementation owner:** ChatGPT
**Review owner:** ChatGPT manual Codex-style review
**Implementation ownership state:** Implementation and exact-source validation complete; PR remains Draft until handoff reconciliation is reviewed.
**Repository base:** GitHub `main` at `7370189856159b465c56fabd77d28a2f68548238`.
**Branch:** `tnyx/tnyx-196-n20d-1-manual-meallog-create-idempotency-retry`
**Validated source HEAD:** `dbf30c8a504c6b31d11751a2697d77f10270957e`
**PR / tracker:** GitHub PR #255; Linear `TNYX-196`, parent `TNYX-116`.
**Current implementation state:** Bounded manual-create idempotency/retry reconciliation implemented. Quick Add remains disabled and no visible UI was changed.
**Live Supabase state:** Migration applied successfully to project `oykupyiitspujzpwwvuj`; live migration ledger version is `20260911143309`, matching repository migration `supabase/migrations/20260911143309_add_meal_log_client_mutation_id.sql`. Live checks confirmed nullable UUID column, `UNIQUE (user_id, client_mutation_id)`, RLS still enabled, the existing four authenticated owner CRUD policies/grants intact, anon DML absent, and `meal_log_entries` left with zero rows after validation.
**Validation completed at source SHA:** Flutter CI #2378 / run `34611242563` PASS; Supabase Database CI #27 / run `34611242549` PASS.
**Scope audit at source SHA:** base is exact merge-base; 10 commits ahead / 0 behind; 8 changed files, all TNYX-196-owned; no Quick Add/UI/app-shell files.
**Open review finding IDs:** None.
**Current blocker:** None in implementation. Only final docs-only handoff review/Ready transition remains; merge is not authorized.
**Next exact action:** Verify this docs-only reconciliation commit against the validated source head, reconcile PR/Linear review state, submit final non-blocking review evidence, and mark PR Ready for review. Do not merge without a new owner `Go`.

## Global UI / Design-System Guardrail

No production UI change is in scope. Quick Add presentation and its disabled `Log Meal` behavior remain unchanged. Any later submit wiring/visual change requires its own approved slice.

## 1. Discovery

### User Outcome

Prevent one logical manual MealLog create from becoming duplicate nutrition history when the database commit succeeds but the response is lost, the client retries, or equivalent ambiguous network behavior occurs.

### Success Criteria

- one logical manual-create attempt has one stable `clientMutationId`;
- database uniqueness is the final duplicate guard per authenticated owner;
- same-key retry/reconciliation converges on the same durable MealLog row;
- the same key reused with different meal facts fails closed;
- existing historical rows remain compatible without backfill;
- signed-out and active-category safety remain preserved;
- V1 does not claim offline durable success;
- Quick Add remains disabled in this slice.

### Scope

- additive nullable UUID mutation identity on `meal_log_entries`;
- owner-scoped unique database invariant;
- manual-create repository/input/gateway mapping and reconciliation only;
- deterministic in-memory equivalent;
- focused database/repository tests;
- explicit outcome-unknown and mutation-conflict failures required by the bounded create path.

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

- Root and feature `AGENTS.md` governance followed.
- Existing Nutrition repository/gateway ownership preserved.
- Authenticated user identity continues to come from Supabase session; RLS remains final ownership authority.
- Existing active Meal Category validation remains at the Nutrition repository boundary for new creates.
- Existing strict MealLog row decoding, time/local-date semantics, capture-source semantics, and `NutritionSnapshot` codec are reused.
- TNYX-194/TNYX-195 manual-path persistence/repository foundations remain the immediate runtime base.
- No current production caller for `ManualMealLogCreate` exists yet, so making `clientMutationId` required does not break a production Quick Add caller in this slice.

Tracker/runtime drift retained as context:

- TNYX-113 remains a broad Backlog umbrella even though the completed manual-path children are sufficient prerequisites for this slice.
- `docs/SUPABASE_STRATEGY.md` has known future-backend namespace drift; current root `AGENTS.md` remains authoritative and TNYX-196 introduces no backend service namespace.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| V1 final save is online-required; no durable offline queue | Approved | Smallest safe V1 | Owner |
| Add `client_mutation_id uuid NULL` | Approved + implemented | Stable logical create identity | Owner |
| Enforce `UNIQUE (user_id, client_mutation_id)` | Approved + implemented | Closes concurrent/pre-check race | Owner |
| Mutation identity remains distinct from MealLog row `id` | Approved + implemented | Different ownership/semantics | Owner |
| Same logical retry reuses same mutation ID | Approved + implemented | Prevents duplicate actual history | Owner |
| No `version` field in this slice | Approved boundary | Edit concurrency remains later TNYX-116 work | Owner |

## 4. Architecture Design

### Implemented Flow

```text
future caller/controller
  -> stable clientMutationId generated once per logical create
  -> MealLogRepository.createManual(input)
  -> require authenticated user
  -> owner+mutation pre-reconciliation read
       -> existing canonical row: validate same facts and return it
       -> no row: validate current Meal Category activity
  -> insert manual row carrying client_mutation_id
       -> success: decode/validate canonical row
       -> uniqueness/ambiguous failure: owner+mutation reconciliation read
            -> canonical matching row: return it
            -> matching key but different facts: mutation conflict
            -> cannot confirm durable outcome: outcome-unknown with same key
```

Database uniqueness, not the pre-read, is the final concurrent duplicate guard. The pre-read exists to make same-key retry cheap and to recover an already-committed historical fact before current category-activity validation.

### Failure Contract

- `MealLogCreateOutcomeUnknown`: durable outcome cannot be confirmed; caller must retain/reuse the same mutation ID rather than creating a fresh logical attempt.
- `MealLogCreateMutationConflict`: one mutation ID was reused for different manual MealLog facts; fail closed.
- Known database/auth/domain validation failures remain their original failures rather than being mislabeled as successful or silently retried.

### Rejected Alternatives

- submit-button disabling as the only duplicate guard;
- new mutation ID per retry;
- using durable MealLog row ID as mutation identity;
- durable offline queue in this slice;
- adding edit `version` semantics early.

## 5. Implementation Plan

- [x] Verify main/base/branch/tracker/overlap.
- [x] Move TNYX-196 to In Progress.
- [x] Add nullable `client_mutation_id uuid` migration.
- [x] Add `UNIQUE (user_id, client_mutation_id)` without changing ownership/RLS policy shape.
- [x] Extend SQL tests for historical null compatibility, same-owner uniqueness, cross-owner reuse, and RLS isolation.
- [x] Extend `ManualMealLogCreate` with required stable mutation identity.
- [x] Add owner+mutation gateway lookup and repository reconciliation.
- [x] Add explicit outcome-unknown and mutation-conflict failure types.
- [x] Add deterministic in-memory idempotency equivalent.
- [x] Preserve active Meal Category validation and signed-out fail-closed behavior.
- [x] Preserve time/local-date/snapshot/capture-source contracts.
- [x] Cover first create, same-key retry, uniqueness race, response loss, unavailable reconciliation, key/payload conflict, and archived-category-after-commit paths.
- [x] Keep Quick Add/UI untouched.
- [x] Run exact-source Flutter/Dart CI.
- [x] Run exact-source Supabase migration/SQL/concurrency/lint CI.
- [x] Apply approved additive migration to live Supabase and verify schema/security/empty-row state.
- [x] Audit exact base-to-source-head scope.
- [x] Perform final Codex-style diff review; no P1/P2 implementation blocker found.
- [x] Reconcile stale planning handoff before Ready transition.

## 6. Quality Review

### Validation Run

Validated source head: `dbf30c8a504c6b31d11751a2697d77f10270957e`

```text
Flutter CI #2378 / run 34611242563: PASS
- bootstrap: PASS
- Flutter analyze: PASS
- Dart analyze: PASS
- Flutter tests: PASS
- Dart tests: PASS

Supabase Database CI #27 / run 34611242549: PASS
- baseline/replay migrations: PASS
- complete migration ledger: PASS
- private helper boundary: PASS
- existing SQL matrices: PASS
- TNYX-194/TNYX-196 MealLog SQL matrix: PASS
- two-session concurrency test: PASS
- database lint regression guard: PASS
```

Live Supabase post-apply verification:

```text
client_mutation_id: uuid NULL
constraint: UNIQUE (user_id, client_mutation_id)
RLS: enabled
owner policies: 4, unchanged
authenticated CRUD grants: intact
anon DML: absent
meal_log_entries rows after verification: 0
migration ledger: 20260911143309 add_meal_log_client_mutation_id
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence / resolution |
|---|---|---|---|---|---|
| QR-1 | P3 governance | Resolved | Task brief still described planning-only/no-PR/no-validation state after implementation completed. | `dbf30c8a504c6b31d11751a2697d77f10270957e` | This docs-only reconciliation updates implementation, validation, live schema, scope and next-action truth. |

Final code/diff review found no open P1/P2 implementation defects. Review specifically checked database race closure, same-key/different-payload behavior, response-loss reconciliation, category archival after committed create, strict row decoding, snapshot equality semantics, RLS/grants preservation, historical null compatibility, and deployment ordering.

## 7. Final Handoff

### Changed Files

1. `.ai/tasks/tnyx-196-manual-meal-log-create-idempotency.md`
2. `apps/features/nutrition/lib/src/domain/repositories/meal_log_repository.dart`
3. `apps/features/nutrition/lib/src/data/in_memory_meal_log_repository.dart`
4. `apps/features/nutrition/lib/src/data/repositories/supabase_meal_log_repository.dart`
5. `apps/features/nutrition/test/data/in_memory_meal_log_repository_test.dart`
6. `apps/features/nutrition/test/data/supabase_meal_log_repository_test.dart`
7. `supabase/migrations/20260911143309_add_meal_log_client_mutation_id.sql`
8. `supabase/tests/database/tnyx_194_manual_meal_log_entries.test.sql`

### Actual Behavior

Manual MealLog create now requires a stable canonical UUID mutation identity. Supabase and in-memory repositories converge repeated same-key/same-payload creates onto one canonical row. Supabase uses the owner-scoped unique constraint as the final race-safe duplicate guard. Ambiguous outcomes are reconciled by the same key; if the outcome cannot be confirmed, the repository reports `MealLogCreateOutcomeUnknown` so a caller cannot safely invent a new key. Reusing the same key for different meal facts fails closed.

### Known Limitations / Deferred Work

- Quick Add `Log Meal` remains disabled and unwired.
- Diary selected-day actual-history read/display remains separate.
- No durable offline queue/background replay exists.
- Edit/update versioning and delete idempotency remain future TNYX-116 children.
- Detailed MealLog items/atomic detailed aggregates remain separate.
- TNYX-116 remains open after this child completes.

### Final Status

`REVIEW — validated source is clean; docs-only handoff reconciliation complete; safe to move PR #255 to Ready after verifying this commit is the only delta from validated source. Merge requires separate owner authorization.`
