# TNYX-217 — Detailed MealLog Physical Persistence Foundation

**Status:** Needs decision
**Primary owner:** Supabase + Nutrition persistence boundary
**Affected platforms:** Supabase/Postgres schema; Flutter runtime intentionally unchanged in this slice

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** `AWAITING OWNER APPROVAL`
**Approval evidence:** Owner approved planning/audit setup on 2026-09-17 by saying `Go with agent.md @Linear @GitHub`. This authorizes tracker/task-brief preparation only; it does not approve the proposed DDL shape below.
**Approved product/UI/data-shape boundaries:** None yet. Exact parent widening + child-table shape below awaits explicit owner approval before migration implementation.
**Explicit non-changes:** No UI, repository create/read wiring, Meal Editor final save activation, parser/API/AI/provider wiring, Search Food/barcode/photo/voice, membership/ads coupling, provider provenance columns, normalized serving mechanics, or backend/service work.

## Active Handoff

**Planning owner:** ChatGPT planning/review role
**Implementation owner:** Unassigned
**Review owner:** Unassigned
**Implementation ownership state:** Blocked
**Ownership transition:** Not applicable
**Repository state last verified:** Remote `main` verified at `7ecdd6c572083a869b095b5c138607eaa504a711`; connector-only session cannot inspect or sync the user's local working tree, so local post-merge sync is not claimed.
**Branch:** `tnyx/tnyx-217-n20a-8-detailed-meallog-physical-persistence-foundation`
**HEAD SHA:** Branch created from `7ecdd6c572083a869b095b5c138607eaa504a711`; task-brief commit advances branch after creation.
**Observed working-tree state:** Local working tree unavailable through connector.
**Observed uncommitted/dirty files:** Unknown; no destructive local action attempted.
**PR / tracker:** Linear TNYX-217; GitHub #272; no PR yet.
**Current implementation state:** Planning/governance only. No migration/schema mutation exists for TNYX-217.
**Relevant execution surface:** `supabase/migrations/*`, live `public.meal_log_entries`, future `public.meal_log_item_snapshots`; current Nutrition repository remains manual-only.
**Validation completed at SHA:** Read-only repository/live-Supabase audit against remote `main` `7ecdd6c...` on 2026-09-17.
**Validation remaining:** After approval/implementation: migration review, live schema/constraint/RLS/grant checks, Supabase security/performance advisors, regression checks for manual MealLog persistence.
**Current blocker:** Explicit owner approval of exact Supabase table/column shape.
**Open review finding IDs:** None.
**Next exact action:** Present exact proposed shape and compatibility impact to owner. If approved, assign one Implementation owner and implement only this physical persistence slice.

## Global UI / Design-System Guardrail

No Flutter production UI change is in scope. Existing Meal Editor rendering and `MealLogActionFooter` behavior must remain unchanged.

## 1. Discovery

### User Outcome

Make the database capable of representing the already-merged canonical detailed MealLog aggregate without weakening historical snapshot truth or breaking existing manual MealLog history.

### Success Criteria

- Existing manual MealLog rows and behavior remain compatible.
- `public.meal_log_entries` can distinguish `manual` and `detailed` modes.
- Manual mode keeps exactly one authoritative meal-level `manual_nutrition_snapshot`.
- Detailed mode has no manual meal-level snapshot and derives nutrition from durable ordered child item snapshots.
- Child items preserve durable identity, parent identity, deterministic order, display facts, positive finite quantity, serving unit, and canonical `NutritionSnapshot` JSON.
- Child ownership is enforced through parent ownership with RLS.
- Parent + child aggregate invariants cannot commit a partial detailed MealLog.
- No repository/UI/parser activation is included.

### Scope

Schema-foundation only:

1. widen existing `public.meal_log_entries` mode/snapshot constraints for detailed mode;
2. add `public.meal_log_item_snapshots` with the minimal canonical V1 columns;
3. add FK/order/value constraints;
4. add RLS + explicit grants for the child table;
5. add the smallest database integrity mechanism required to prevent invalid manual/detailed aggregate states;
6. preserve all existing manual rows and manual persistence contracts.

### Non-Goals

- `MealLogRepository.createDetailed(...)` or detailed read decoding;
- transactional RPC/client activation for detailed create;
- Meal Editor `Log Meal` activation;
- natural-language parsing or provider integration;
- provider/source identifiers or raw payload persistence;
- serving catalog/normalization/unit conversion;
- detailed edit/delete product workflow;
- meal-level detailed total column;
- UI changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `.ai/tasks/README.md`, `docs/POST_MERGE_SYNC.md`, `docs/SUPABASE_STRATEGY.md`, `docs/MODULE_OWNERSHIP.md`, TNYX-113/TNYX-207/TNYX-216, GitHub #269/#271, current shared `MealLogEntry`/`MealLogItemSnapshot`, current `MealLogRepository` and `SupabaseMealLogRepository`, manual MealLog migrations, live Supabase table/constraints/indexes/RLS/grants/advisors.
- Existing pattern to follow: additive migration discipline from TNYX-194/TNYX-196/TNYX-203; owner-scoped RLS uses `(select auth.uid())`; explicit grants are handled separately from RLS; canonical `private.is_valid_nutrition_snapshot_v1(jsonb)` already validates snapshot envelopes.
- Tests or validation already present: shared domain tests for manual/detailed aggregate invariants; Nutrition repository tests for manual create/read/update/idempotency/range behavior; migration/RLS validation patterns from existing Supabase slices.

Live `tio-world` evidence on 2026-09-17:

```text
public.meal_log_entries rows: 8
mode distribution: manual = 8
RLS: enabled
mode constraint: mode = 'manual'
manual_nutrition_snapshot: NOT NULL
unique create identity: (user_id, client_mutation_id)
revision: bigint >= 1
child detailed table: absent
```

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep one canonical `meal_log_entries` parent rather than a second detailed parent table | Proposed | Manual and detailed are modes of one canonical actual-history aggregate; preserves identity and existing reads | Owner approval required as part of shape |
| Widen `mode` to `manual | detailed` | Proposed | Required to persist merged domain mode | Owner approval required |
| Make `manual_nutrition_snapshot` nullable with mode-coupled invariant | Proposed | Detailed truth lives only in child snapshots; avoids competing totals | Owner approval required |
| Add normalized child table `meal_log_item_snapshots` | Proposed | Durable child identity, ordered items, future safe edits/reads; avoids JSON-array parent blob | Owner approval required |
| Do not duplicate `user_id` on child | Chosen engineering direction | Parent already owns user identity; avoids denormalized ownership drift | Planning owner |
| Add store-only `position integer` | Proposed | Dart aggregate is ordered but domain item has no order field; persistence must round-trip list order deterministically | Owner approval required |
| No child `created_at`/`updated_at` in V1 | Proposed | Parent timestamps/revision own aggregate history; child timestamps are not required by current domain and would widen shape without current use | Owner approval required |
| No detailed meal-total column | Chosen | Detailed totals derive from child snapshots; a second authoritative total can drift | Canonical TNYX-113 rule |
| Detailed create must be atomic | Chosen | Separate REST parent/item writes can commit partial history | Architecture requirement |
| Use deferred aggregate integrity in DB so a detailed parent cannot commit empty | Chosen engineering approach, implementation pending | Enforces canonical invariant even before repository activation; later atomic RPC can insert parent+children in one transaction | Planning owner |

## 4. Architecture Design

### Chosen Approach

#### Existing parent widening

Proposed exact parent changes:

```text
public.meal_log_entries.mode
  text NOT NULL
  CHECK mode IN ('manual', 'detailed')

public.meal_log_entries.manual_nutrition_snapshot
  jsonb NULL
```

Replace the current manual-only/snapshot constraint with one mode-coupled invariant:

```text
(mode = 'manual'   AND manual_nutrition_snapshot IS NOT NULL)
OR
(mode = 'detailed' AND manual_nutrition_snapshot IS NULL)
```

Existing 8 manual rows satisfy this invariant unchanged.

#### New child table

Proposed exact V1 columns:

```text
public.meal_log_item_snapshots

id uuid PRIMARY KEY DEFAULT gen_random_uuid()
meal_log_entry_id uuid NOT NULL
position integer NOT NULL

display_name text NOT NULL
brand_name text NULL
quantity numeric NOT NULL
serving_unit text NOT NULL
nutrition_snapshot jsonb NOT NULL
```

No child timestamp/provenance/normalized-serving/meal-total columns in V1.

Proposed physical constraints:

```text
FOREIGN KEY (meal_log_entry_id)
  REFERENCES public.meal_log_entries(id)
  ON DELETE CASCADE

UNIQUE (meal_log_entry_id, position)
CHECK (position >= 0)
CHECK (btrim(display_name) <> '')
CHECK (brand_name IS NULL OR btrim(brand_name) <> '')
CHECK (quantity > 0 AND quantity is finite)
CHECK (btrim(serving_unit) <> '')
CHECK (private.is_valid_nutrition_snapshot_v1(nutrition_snapshot))
```

The implementation must use a PostgreSQL-safe finite numeric check because `numeric` supports special values; `quantity > 0` alone is insufficient for domain parity.

#### Aggregate integrity

Required committed-state invariant:

```text
manual parent
→ manual_nutrition_snapshot present
→ zero item snapshots

detailed parent
→ manual_nutrition_snapshot absent
→ one or more item snapshots
```

A simple row CHECK cannot enforce child cardinality. The recommended database approach is a deferred constraint trigger (or equivalent smallest safe deferred mechanism) that validates aggregate state at transaction end. This intentionally means detailed parent creation must occur in the same transaction as its item snapshots; a later repository slice can expose that transaction through an audited `SECURITY INVOKER` RPC or equivalent approved boundary.

#### RLS / grants

`meal_log_item_snapshots` does not store `user_id`. Policies derive ownership by requiring an owned parent row, using optimized `(select auth.uid())` semantics through the parent relationship. INSERT/UPDATE must additionally prevent attaching an item to a non-detailed parent.

RLS and Data API/table privileges are separate controls. The migration must explicitly reset/regrant only the intended roles/operations, matching current repository conventions.

### Ownership and Data Flow

```text
MealLogEntry parent
  ├─ manual → manual_nutrition_snapshot
  └─ detailed → ordered meal_log_item_snapshots[]
                       └─ nutrition_snapshot = historical consumed truth
```

Later, outside this slice:

```text
Meal Editor confirmed draft
→ DetailedMealLogCreate contract
→ atomic repository/RPC transaction
→ meal_log_entries + meal_log_item_snapshots
→ canonical MealLogEntry.detailed(...)
```

### Alternative Rejected

1. Store detailed items as one JSON array on `meal_log_entries`: rejected because child identity/order/queryability and future safe item edits become opaque, while the merged domain already models durable item identities.
2. Add `user_id` to every item row: rejected because ownership already exists on parent and duplication can drift.
3. Store a detailed meal-level nutrition total as canonical data: rejected because TNYX-113 says detailed totals derive from durable item snapshots.
4. Create parent then items via independent client REST requests: rejected because network failure can leave a committed empty detailed parent.
5. Add provider IDs/source payload now: rejected as speculative provenance beyond the merged provider-independent V1 domain.

### Failure and Accessibility States

No UI/accessibility surface changes in this task. Database failures must be deterministic constraint/RLS failures and must not partially commit a detailed aggregate.

## 5. Implementation Plan

Blocked until owner approves exact table/column shape.

After approval only:

- [ ] Reconstruct repository/local state and complete required post-merge/local-sync checks before source edits.
- [ ] Assign one Implementation owner.
- [ ] Create one additive migration using the repository's current Supabase migration workflow.
- [ ] Replace manual-only parent constraints with manual/detailed mode-coupled constraints.
- [ ] Create `public.meal_log_item_snapshots` with only approved columns.
- [ ] Add FK/order/value/NutritionSnapshot constraints.
- [ ] Add deferred aggregate-integrity mechanism.
- [ ] Enable child RLS and explicit grants/policies through parent ownership.
- [ ] Validate all existing manual rows remain valid and existing manual repository behavior remains unchanged.
- [ ] Run Supabase security/performance advisors and record only task-relevant findings.
- [ ] Run applicable migration/security tests and `git diff --check`.
- [ ] Open a focused PR; do not include repository/UI/parser activation.

## 6. Quality Review

### Validation Run

```text
Planning audit only.
No TNYX-217 DDL has been implemented or applied.
```

Read-only live checks confirmed current manual-only table shape, constraints, indexes, RLS, grants and row-mode distribution. Security/performance advisors were read; existing unrelated advisor warnings are not silently widened into this slice.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| T217-P1 | P1 | Open | Exact Supabase table/column shape requires explicit owner approval before DDL implementation. | `7ecdd6c...` | Owner Approval Gate |

## 7. Final Handoff

### Changed Files

Planning-only branch change at this checkpoint:

1. `.ai/tasks/tnyx-217-detailed-meal-log-physical-persistence.md`

### Actual Behavior

No runtime/database behavior changed. Linear TNYX-217 and GitHub #272 now track the bounded physical-persistence proposal and exact approval gate.

### Known Limitations

Local working-tree post-merge sync cannot be performed or verified through the GitHub connector. Before implementation, the actual implementation owner must inspect local Git state and follow `docs/POST_MERGE_SYNC.md` without discarding user changes.

Detailed repository mapping, atomic create RPC/adapter, Meal Editor final save and parser flow remain deferred.

### Final Status

`BLOCKED` — planning is approval-ready; implementation is blocked only on explicit approval of the proposed Supabase table/column shape.
