# TNYX-218 — Detailed MealLog Repository + Atomic Create/Read Foundation

**Status:** In progress
**Primary owner:** Nutrition persistence / Supabase
**Affected platforms:** Nutrition Dart repository + Supabase/Postgres; no UI change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product/persistence slice
**Approval status:** Approved
**Approval evidence:** Owner said `go` on 2026-09-17 and explicitly required following root `AGENTS.md` after the TNYX-217 post-merge audit created TNYX-218.
**Approved product/UI/data-shape boundaries:** Add provider-neutral detailed create inputs/capability, one authenticated atomic detailed-create RPC, canonical detailed parent/item read mapping, batch item reads, and same-mutation idempotency/reconciliation.
**Explicit non-changes:** No Meal Editor `Log Meal` activation, parser/provider/API wiring, UI/controller change, detailed update/delete, new parent/child table or column, provider IDs/payloads, serving catalog, membership/ads, or future `services/api` implementation.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Independent fallback review at handoff
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main` = `80009fbb55fae50834fb9bab13c89b9f0ac2515b` (PR #273 squash merge)
**Branch:** `tnyx/tnyx-218-n20a-9-detailed-meallog-repository-atomic-createread`
**HEAD SHA:** branch created from `80009fbb55fae50834fb9bab13c89b9f0ac2515b`; this brief is the first branch commit
**Observed working-tree state:** Connector-only session; no local working tree is available and no destructive git action is used
**Observed uncommitted/dirty files:** Not observable through connector; branch was created directly from verified `main`
**PR / tracker:** Linear TNYX-218 In Progress; GitHub issue #274 open
**Current implementation state:** Readiness/architecture frozen; source implementation starts after this brief
**Relevant execution surface:** `apps/features/nutrition`, `supabase/migrations`, `supabase/tests/database`, focused Supabase DB CI
**Validation completed at SHA:** Fresh source/docs/live-Supabase audit only
**Validation remaining:** Dart analyze/tests, SQL migration/RPC matrix, exact-head CI/scope audit, independent review
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Implement the bounded repository/RPC/read slice without activating Meal Editor or parser paths

## 1. Discovery

### User Outcome

Make canonical `MealLogEntry.detailed(...)` persistence usable through the Nutrition repository without exposing direct child writes or allowing retries to duplicate durable meal history.

### Success Criteria

- Detailed create callers provide only confirmed provider-neutral facts, not durable IDs.
- Parent + ordered child snapshots commit atomically.
- Authenticated identity comes from `auth.uid()` only.
- Same logical retry uses the same `clientMutationId` and resolves the same aggregate.
- Same mutation ID with materially different facts fails closed.
- `readById`, selected-day reads, and range reads decode both manual and detailed rows.
- List/range detailed hydration uses one batch child query, not one child query per parent.
- Existing manual create/read/update/idempotency/revision behavior remains unchanged.

### Scope

- Nutrition-owned `DetailedMealLogCreate` / item input and optional create capability.
- In-memory deterministic mirror for tests/local composition.
- Supabase repository RPC seam plus batch item-read seam.
- One narrow Postgres RPC/function for authenticated atomic create.
- Focused database and Dart regression tests.

### Non-Goals

Meal Editor submit activation, `What did you eat?` parser flow, provider/catalog provenance, detailed mutation after creation, UI, membership/ads, or server workspace creation.

## 2. Codebase Exploration

### Verified Evidence

- `main` is `80009fbb55fae50834fb9bab13c89b9f0ac2515b`.
- `MealLogEntry.detailed(...)` and `MealLogItemSnapshot` already own canonical durable detailed history.
- `MealLogRepository` currently owns manual create + common reads; optional update/range capabilities already use separate interfaces.
- `InMemoryMealLogRepository` mirrors manual create idempotency and revision behavior.
- `SupabaseMealLogRepository` currently maps only manual rows through `_decodeManualRow`.
- `public.meal_log_entries` allows `manual | detailed`; `public.meal_log_item_snapshots` has deferred aggregate cardinality enforcement.
- Authenticated has parent CRUD but child `SELECT` only; service role has child CRUD.
- Existing project pattern `public.set_active_body_goal(...)` proves atomic Postgres RPC use where client multi-write would create invalid intermediate state.
- Current Supabase docs recommend `SECURITY INVOKER` by default; this slice cannot use invoker-only child insert without re-granting direct child INSERT, so the atomic function requires a narrowly hardened elevated boundary.
- Supabase breaking-change scan found no RPC/function change that blocks this design; Data API auto-exposure changes reinforce explicit function/table grants.

### Existing Pattern to Follow

- Optional repository capability interfaces rather than widening every test double.
- Stable `clientMutationId`, `MealLogCreateOutcomeUnknown`, and `MealLogCreateMutationConflict` semantics.
- Empty `search_path`, explicit grants, `auth.uid()` ownership, rollback-only SQL matrices.

### Stale Documentation Drift

`docs/MODULE_OWNERSHIP.md` and `docs/DEVELOPMENT_SETUP.md` still contain historical `future supabase/` / `backend/*` wording. Current root `AGENTS.md`, README, `docs/README.md`, and `docs/ARCHITECTURE.md` win: `supabase/` is active and future protected server path is `services/api`. This drift is not widened into this persistence slice.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep base `MealLogRepository` source-compatible; add `DetailedMealLogCreateRepository` capability | Locked | Existing optional-capability pattern avoids forcing unrelated manual-only test doubles to implement unused create APIs | Nutrition |
| Detailed create inputs contain no parent/item durable IDs | Locked | DB owns UUIDs/timestamps/revision/user identity | Nutrition persistence |
| Atomic DB boundary is one `public.create_detailed_meal_log(...)` RPC | Locked | Deferred parent/child cardinality cannot safely span separate client requests | Supabase |
| RPC accepts no `user_id` and derives caller from `auth.uid()` | Locked | Prevents cross-user ownership selection | Supabase/Auth |
| RPC is narrowly `SECURITY DEFINER`, `search_path=''`, EXECUTE only for authenticated | Locked | Child direct INSERT is intentionally revoked; invoker-only cannot insert children without reopening direct client writes | Supabase |
| RPC returns durable parent UUID only; repository performs canonical parent+batch-item read | Locked | Keeps one mapping path for create/read and reduces duplicate payload contracts | Nutrition data |
| Same-key existing aggregate is compared inside RPC and in repository reconciliation | Locked | Handles concurrent retries and response-loss without duplicate history | Persistence |
| Detailed list/range item hydration uses batch `inFilter` query | Locked | Avoids N+1 requests and is supported by current Supabase Dart API | Nutrition data |

## 4. Architecture Design

### Exact RPC Contract

```text
public.create_detailed_meal_log(
  p_client_mutation_id uuid,
  p_meal_category_id text,
  p_meal_name text,
  p_note text,
  p_consumed_at timestamptz,
  p_consumed_local_date date,
  p_consumed_timezone_id text,
  p_consumed_utc_offset_minutes integer,
  p_capture_source text,
  p_items jsonb
) returns uuid
```

Security contract:

- `SECURITY DEFINER` only because authenticated child table INSERT remains revoked.
- `set search_path = ''` and fully qualified relations/functions.
- caller UUID is `(select auth.uid())`; null caller is rejected.
- no caller-supplied `user_id` or durable row IDs.
- revoke default `PUBLIC`, `anon`, and `service_role` execute; grant only `authenticated`.
- existing child table grants remain `authenticated: SELECT only`.

Idempotent create algorithm:

```text
normalize blank optional parent text to null
validate nonblank category + nonempty JSON item array
find existing (auth.uid, clientMutationId)
  → if found: require detailed revision=1 + exact parent facts + exact ordered item facts
               else raise meal_log_create_mutation_conflict
  → return existing id
insert detailed parent ON CONFLICT DO NOTHING RETURNING id
  → if conflict won concurrently: re-run exact existing comparison
insert ordered child snapshots with WITH ORDINALITY
return parent id
```

Item JSON accepts only persistence facts:

```text
display_name
brand_name
quantity
serving_unit
nutrition_snapshot
```

Table constraints remain the final validation for positive finite quantity, nonblank fields and canonical `NutritionSnapshot` shape.

### Ownership and Data Flow

```text
caller / later Meal Editor
  → DetailedMealLogCreateRepository
  → SupabaseMealLogRepository
  → public.create_detailed_meal_log RPC
  → meal_log_entries + meal_log_item_snapshots (one transaction)
  → canonical parent read + batch item read
  → MealLogEntry.detailed(...)
```

### Alternative Rejected

Separate PostgREST parent insert followed by child inserts is rejected because a detailed parent cannot validly commit without children, failure between requests would create an invalid/failed operation boundary, and re-granting direct child INSERT would bypass the intended atomic/revision boundary.

### Failure States

- signed out: fail before gateway/RPC access;
- known validation/security rejection: surface original database error;
- same-key different payload: `MealLogCreateMutationConflict`;
- ambiguous RPC/transport outcome: reconcile by same mutation ID, otherwise `MealLogCreateOutcomeUnknown` with the same key;
- malformed/missing child snapshots during read: fail closed, never fabricate a manual row or silently drop items.

## 5. Implementation Plan

- [x] Reconcile Linear/GitHub/main/docs/live Supabase state.
- [x] Freeze exact RPC/security/repository boundaries.
- [ ] Add detailed create contract/capability.
- [ ] Add in-memory detailed create/idempotency mirror.
- [ ] Add Supabase RPC + batch child read gateway capabilities.
- [ ] Add manual+detailed canonical row decoding.
- [ ] Add atomic RPC migration and SQL matrix.
- [ ] Wire focused DB matrix into Supabase CI.
- [ ] Add/extend Dart tests for create, retry/conflict, response loss, read/order/batch hydration, and manual regressions.
- [ ] Run quality review and exact branch scope audit.
- [ ] Open PR and reconcile Linear to In Review.

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

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Detailed update/delete, Meal Editor save, and parser/provider activation remain later slices.

### Final Status

`PARTIAL` until implementation and validation complete.
