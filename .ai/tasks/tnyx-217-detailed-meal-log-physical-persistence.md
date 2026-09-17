# TNYX-217 — Detailed MealLog Physical Persistence Foundation

**Status:** In progress
**Primary owner:** Nutrition persistence / Supabase
**Affected platforms:** Supabase/Postgres only; Flutter runtime unchanged in this slice

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner explicitly approved the exact V1 physical shape in chat on 2026-09-17 by saying `Go` after the approval-ready schema was presented.
**Approved product/UI/data-shape boundaries:** Widen `public.meal_log_entries` for `manual | detailed`; make `manual_nutrition_snapshot` nullable with a mode-coupled invariant; add `public.meal_log_item_snapshots` with only `id`, `meal_log_entry_id`, `position`, `display_name`, nullable `brand_name`, `quantity`, `serving_unit`, and `nutrition_snapshot`.
**Explicit non-changes:** No child timestamps, child `user_id`, provider/source IDs, raw provider payload, detailed meal-total column, repository create/read mapping, RPC/client write activation, Meal Editor final save, parser/API/AI/provider wiring, UI, membership/ads, or unrelated Supabase cleanup.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Pending focused PR review
**Implementation ownership state:** Handoff pending
**Repository state last verified:** Remote `main` = `7ecdd6c572083a869b095b5c138607eaa504a711`; branch is 4 commits ahead / 0 behind before this handoff refresh. Connector-only session cannot claim local working-tree sync.
**Branch:** `tnyx/tnyx-217-n20a-8-detailed-meallog-physical-persistence-foundation`
**HEAD SHA:** `6f03d3b22fbd8fa6b8c71c97d461133fcddc6be2` before this handoff refresh commit.
**Observed working-tree state:** Local filesystem unavailable through connector; no destructive local action attempted.
**PR / tracker:** Linear TNYX-217; GitHub #272; PR pending.
**Current implementation state:** Physical schema, constraints, deferred aggregate integrity, RLS and grant hardening are applied live and recorded in repository migrations. Repository/UI/parser activation remains deferred.
**Relevant execution surface:** `supabase/migrations/*`, `public.meal_log_entries`, `public.meal_log_item_snapshots`.
**Validation completed:** Live structural checks, authenticated/non-owner RLS checks, rollback-only aggregate tests, security/performance advisors, migration history reconciliation.
**Validation remaining:** API-equivalent final branch audit after this handoff commit; PR checks/review.
**Current blocker:** None for PR handoff.
**Open review finding IDs:** None.
**Next exact action:** Audit final branch delta, open focused PR, then review without merging unless owner explicitly authorizes merge.

## 1. Discovery

### User Outcome

Persist the merged canonical `MealLogEntry.detailed(...)` shape without weakening manual history or creating a competing detailed nutrition truth.

### Success Criteria

- Existing manual rows remain valid.
- Parent supports `manual` and `detailed` modes.
- Manual mode requires `manual_nutrition_snapshot`; detailed mode requires it to be null.
- Detailed items persist as ordered durable child snapshots.
- Child nutrition reuses `private.is_valid_nutrition_snapshot_v1(jsonb)`.
- Committed state cannot contain manual parents with items or detailed parents without items.
- Child rows are owner-readable; direct authenticated child writes remain disabled until the later atomic write boundary.
- Repository/UI/parser behavior remains unchanged.

### Non-Goals

Detailed repository mapping/atomic create API, Meal Editor save activation, parser/provider work, detailed edit workflow, child provenance, unit catalog, UI changes, or unrelated security/performance cleanup.

## 2. Codebase Exploration

### Verified Evidence

Pre-change live state:

```text
public.meal_log_entries rows: 8
mode distribution: manual = 8
manual_nutrition_snapshot: NOT NULL
mode constraint: manual only
child detailed table: absent
```

Existing create identity `(user_id, client_mutation_id)`, `revision >= 1`, owner RLS, selected-day index and `private.is_valid_nutrition_snapshot_v1(jsonb)` were preserved.

PostgreSQL `numeric` supports `NaN` and infinities. Live verification confirmed `quantity > 0` alone accepts `NaN`/`Infinity`, so V1 uses `quantity > 0 AND quantity < 'Infinity'::numeric`.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| One canonical `meal_log_entries` parent | Approved | Manual/detailed are modes of one history aggregate. |
| `mode IN ('manual','detailed')` | Approved | Matches canonical domain. |
| Nullable mode-coupled `manual_nutrition_snapshot` | Approved | Detailed truth lives only in child snapshots. |
| Normalized `meal_log_item_snapshots` table | Approved | Durable identity and deterministic order. |
| No child `user_id` | Approved | Ownership derives from parent; avoids drift. |
| Store-only `position integer` | Approved | Ordered list must round-trip deterministically. |
| No child timestamps/provenance/meal total | Approved | Keep V1 canonical shape minimal. |
| Deferred aggregate integrity | Implemented | Allows atomic parent+items transaction while rejecting invalid committed aggregates. |
| Authenticated child table is SELECT-only | Implemented review hardening | Direct child writes would bypass parent `revision`/concurrency semantics before the atomic repository boundary exists. |

## 4. Architecture Design

Parent:

```text
meal_log_entries.mode: manual | detailed
manual   => manual_nutrition_snapshot IS NOT NULL
detailed => manual_nutrition_snapshot IS NULL
```

Child:

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

Physical rules:

- FK to `meal_log_entries(id) ON DELETE CASCADE`.
- Unique `(meal_log_entry_id, position)`.
- Nonnegative position; nonblank display/unit; optional brand null-or-nonblank.
- Positive finite quantity.
- Canonical NutritionSnapshot validator.
- Deferred constraint triggers enforce `manual => 0 children` and `detailed => >=1 child` at transaction end.
- Trigger helpers are `SECURITY INVOKER`.

Access:

```text
anon          => no child-table privileges
authenticated => SELECT only + owner RLS
service_role  => SELECT / INSERT / UPDATE / DELETE
```

Authenticated INSERT/UPDATE/DELETE RLS policies remain defined but dormant behind table grants; the next atomic repository/RPC slice must explicitly choose its write boundary rather than inheriting direct item mutation accidentally.

## 5. Implementation Plan

- [x] Exact table/column shape approved.
- [x] Fresh live schema and migration-history audit.
- [x] Apply `20260917083552_add_detailed_meal_log_persistence`.
- [x] Apply review hardening `20260917083919_tighten_detailed_meal_log_item_grants`.
- [x] Verify columns, constraints, trigger deferrability, RLS, policies, grants and existing manual rows.
- [x] Exercise rollback-only aggregate invariant tests.
- [x] Run security/performance advisors and isolate task-relevant findings.
- [x] Record migrations in repository.
- [ ] Open focused PR and hand off to review.

## 6. Quality Review

### Validation Run

Live `tio-world` verification after both migrations:

```text
existing parent rows: 8
existing parent modes: manual = 8
new child rows: 0
manual_nutrition_snapshot nullable: YES
child RLS: enabled
constraint triggers: DEFERRABLE INITIALLY DEFERRED
```

Rollback-only behavioral tests passed:

```text
atomic detailed parent + child: PASS
existing manual create/update path at DB boundary: PASS
non-owner child visibility: 0 rows
empty detailed parent rejected: PASS
manual parent + detailed child rejected: PASS
Infinity quantity rejected: PASS
last child deletion from live detailed parent rejected: PASS
parent delete cascades child: PASS
```

Final child grants verified:

```text
authenticated: SELECT=true, INSERT=false, UPDATE=false, DELETE=false
anon: SELECT=false
service_role: SELECT/INSERT/UPDATE/DELETE=true
```

Security Advisor after DDL reported only pre-existing unrelated warnings: four authenticated-callable `SECURITY DEFINER` public functions and leaked-password protection disabled. No new TNYX-217 security finding.

Performance Advisor reported existing unrelated RLS init-plan/unused-index findings and did not flag the new child policies.

Local `git diff --check` cannot be claimed in this connector-only session. GitHub API ancestry/changed-file evidence is used instead, per `docs/PUSH_TEMPLATE.md`.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| T217-P1 | P1 | Resolved | Exact table/column shape required owner approval. | Owner approved exact V1 shape on 2026-09-17. |
| T217-RF1 | P1 | Resolved | Full authenticated child DML would let direct clients mutate detailed history without parent `revision` semantics. | Added `20260917083919_tighten_detailed_meal_log_item_grants.sql`; authenticated is SELECT-only until atomic write boundary lands. |

## 7. Final Handoff

### Changed Files

1. `.ai/tasks/tnyx-217-detailed-meal-log-physical-persistence.md`
2. `supabase/migrations/20260917083552_add_detailed_meal_log_persistence.sql`
3. `supabase/migrations/20260917083919_tighten_detailed_meal_log_item_grants.sql`

### Actual Behavior

Supabase can now represent canonical detailed MealLog aggregates with ordered consumed item snapshots and DB-enforced committed-state integrity. Existing manual history remains valid. Direct authenticated child mutation is intentionally not activated.

### Known Limitations

Detailed repository read/create mapping, atomic write RPC/boundary, Meal Editor final save, detailed edits and TNYX-207 parser flow remain deferred to later bounded slices.

### Final Status

`REVIEW` — implementation and live validation are complete; focused PR/reviewer handoff remains.
