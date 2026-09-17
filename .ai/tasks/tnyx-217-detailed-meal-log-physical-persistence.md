# TNYX-217 — Detailed MealLog Physical Persistence Foundation

**Status:** In progress
**Primary owner:** Nutrition persistence / Supabase
**Affected platforms:** Supabase/Postgres only; Flutter runtime unchanged in this slice

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner explicitly approved the exact V1 physical shape in chat on 2026-09-17 by saying `Go` after the approval-ready schema was presented.
**Approved product/UI/data-shape boundaries:** Widen `public.meal_log_entries` for `manual | detailed`; make `manual_nutrition_snapshot` nullable with a mode-coupled invariant; add `public.meal_log_item_snapshots` with only `id`, `meal_log_entry_id`, `position`, `display_name`, nullable `brand_name`, `quantity`, `serving_unit`, and `nutrition_snapshot`.
**Explicit non-changes:** No child timestamps, child `user_id`, provider/source IDs, raw provider payload, detailed meal-total column, repository create/read mapping, RPC/client activation, Meal Editor final save, parser/API/AI/provider wiring, UI, membership/ads, or unrelated Supabase cleanup.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned until implementation checkpoint
**Implementation ownership state:** Active
**Repository state last verified:** Remote `main` at `7ecdd6c572083a869b095b5c138607eaa504a711`. Connector-only session cannot claim local working-tree sync.
**Branch:** `tnyx/tnyx-217-n20a-8-detailed-meallog-physical-persistence-foundation`
**Current implementation state:** Exact schema approved; migration/RLS/constraint implementation authorized. No repository/UI/parser activation authorized.
**Relevant execution surface:** `supabase/migrations/*`, live `public.meal_log_entries`, new `public.meal_log_item_snapshots`.
**Current blocker:** None inside approved slice.
**Next exact action:** Implement one additive migration, apply/verify it against `tio-world`, run advisors/regression checks, then open a focused PR for review.

## 1. Discovery

### User Outcome

Persist the merged canonical `MealLogEntry.detailed(...)` shape without weakening manual history or creating a competing detailed nutrition truth.

### Success Criteria

- Existing manual rows remain valid.
- Parent supports `manual` and `detailed` modes.
- Manual mode requires `manual_nutrition_snapshot`; detailed mode requires it to be null.
- Detailed items persist as ordered durable child snapshots.
- Child nutrition reuses `private.is_valid_nutrition_snapshot_v1(jsonb)`.
- Owner-only RLS and explicit grants protect the child table.
- Committed state cannot contain manual parents with items or detailed parents without items.
- Repository/UI/parser behavior remains unchanged.

### Non-Goals

Detailed repository mapping/atomic create API, Meal Editor save activation, parser/provider work, detailed edit workflow, child provenance, unit catalog, UI changes, or unrelated security/performance cleanup.

## 2. Codebase Exploration

### Verified Evidence

- Current live `public.meal_log_entries`: 8 rows, all `mode = 'manual'`.
- Current mode constraint is manual-only and `manual_nutrition_snapshot` is `NOT NULL`.
- Existing owner RLS and explicit authenticated/service-role DML grants are present.
- Existing unique create identity `(user_id, client_mutation_id)` and `revision >= 1` remain untouched.
- `private.is_valid_nutrition_snapshot_v1(jsonb)` exists.
- `public.meal_log_item_snapshots` does not exist.
- Shared domain already has provider-independent `MealLogItemSnapshot` and `MealLogEntry.detailed(...)`.
- PostgreSQL `numeric` accepts `NaN`/infinity; verified live that `quantity > 0` alone would allow `NaN`/`Infinity`, so the child constraint must also require `quantity < 'Infinity'::numeric`.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| One canonical `meal_log_entries` parent | Approved | Manual/detailed are modes of one history aggregate. |
| `mode IN ('manual','detailed')` | Approved | Matches canonical domain. |
| `manual_nutrition_snapshot` nullable, mode-coupled | Approved | Detailed nutrition truth lives only in child snapshots. |
| New normalized `meal_log_item_snapshots` table | Approved | Durable identity and deterministic order. |
| No child `user_id` | Approved | Ownership derives from parent; avoids drift. |
| `position integer` store metadata | Approved | Ordered Dart list must round-trip deterministically. |
| No child timestamps | Approved | Parent timestamps/revision own aggregate-level history. |
| No detailed meal-total column | Approved | Prevents competing authoritative totals. |
| Deferred aggregate integrity | Chosen engineering mechanism | Allows parent+items in one transaction but rejects invalid committed aggregates. |

## 4. Architecture Design

Approved parent changes:

```text
meal_log_entries.mode: text NOT NULL, manual | detailed
meal_log_entries.manual_nutrition_snapshot: jsonb NULLABLE

manual   => manual_nutrition_snapshot IS NOT NULL
detailed => manual_nutrition_snapshot IS NULL
```

Approved child columns:

```text
public.meal_log_item_snapshots
  id uuid primary key default gen_random_uuid()
  meal_log_entry_id uuid not null
  position integer not null
  display_name text not null
  brand_name text null
  quantity numeric not null
  serving_unit text not null
  nutrition_snapshot jsonb not null
```

Physical constraints:

- FK to `meal_log_entries(id) ON DELETE CASCADE`.
- Unique `(meal_log_entry_id, position)`.
- `position >= 0`.
- `display_name` and `serving_unit` nonblank; `brand_name` null or nonblank.
- `quantity > 0 AND quantity < 'Infinity'::numeric` to reject zero/negative, `Infinity`, `-Infinity`, and `NaN`.
- `private.is_valid_nutrition_snapshot_v1(nutrition_snapshot)`.

Aggregate committed-state invariant:

```text
manual parent   => zero detailed children
detailed parent => one or more detailed children
```

Use deferred constraint triggers so a later atomic create transaction can insert the detailed parent and children in either safe sequence before commit. Standalone detailed-parent REST creation must fail at transaction end.

RLS/grants:

- No `anon` child-table privileges.
- `authenticated` and `service_role`: SELECT/INSERT/UPDATE/DELETE table grants.
- Authenticated policies derive ownership via the parent row and use `(select auth.uid())`.
- INSERT/UPDATE target parent must also be `mode = 'detailed'`.
- Internal aggregate trigger function remains `SECURITY INVOKER`; do not add a privileged bypass function for convenience.

## 5. Implementation Plan

- [x] Exact table/column shape approved.
- [x] Fresh live schema and migration-history audit.
- [ ] Add and apply one additive migration.
- [ ] Verify columns, constraints, trigger deferrability, RLS, policies, grants and existing manual rows.
- [ ] Exercise transactional invariant tests and rollback test data.
- [ ] Run security/performance advisors and isolate only TNYX-217 findings.
- [ ] Record migration in repository and validate branch diff.
- [ ] Open focused PR and hand off to review.

## 6. Quality Review

### Validation Run

Implementation validation pending.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence |
|---|---|---|---|---|
| T217-P1 | P1 | Resolved | Exact table/column shape required owner approval. | Owner approved exact V1 shape on 2026-09-17. |

## 7. Final Handoff

Not complete yet. Detailed repository mapping, atomic create API, Meal Editor final save, and TNYX-207 parser flow remain deferred to later bounded slices.
