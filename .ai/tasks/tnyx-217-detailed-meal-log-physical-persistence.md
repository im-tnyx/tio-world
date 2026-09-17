# TNYX-217 — Detailed MealLog Physical Persistence Foundation

**Status:** In review
**Primary owner:** Nutrition persistence / Supabase
**Affected platforms:** Supabase/Postgres only; Flutter runtime unchanged in this slice

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change  
**Approval status:** Approved  
**Approval evidence:** Owner explicitly approved the exact V1 physical shape on 2026-09-17 and later authorized the final review/merge sequence with `go` while asking agents to follow root `AGENTS.md`.

Approved shape:

- widen `public.meal_log_entries.mode` to `manual | detailed`;
- make `manual_nutrition_snapshot` nullable with a mode-coupled invariant;
- add `public.meal_log_item_snapshots` with only `id`, `meal_log_entry_id`, `position`, `display_name`, nullable `brand_name`, `quantity`, `serving_unit`, and `nutrition_snapshot`;
- keep detailed meal nutrition derived from durable item snapshots rather than adding a competing parent total;
- keep direct authenticated child writes disabled until the later atomic repository/RPC boundary.

Explicit non-changes: no provider/source IDs, raw provider payload, child timestamps or `user_id`, Meal Editor final save activation, parser/API/AI/provider wiring, UI change, membership/ads coupling, or unrelated Supabase cleanup.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT independent fallback review because the requested Codex review hit its usage limit  
**Implementation ownership state:** Complete; current repository edit is governance-only handoff reconciliation  
**Branch:** `tnyx/tnyx-217-n20a-8-detailed-meallog-physical-persistence-foundation`  
**Base:** `main` at `7ecdd6c572083a869b095b5c138607eaa504a711`  
**Source/test review checkpoint:** `216a353a122ee3e0b446c0710dd3d046025d15f6` before this governance-only handoff commit  
**Checkpoint compare:** 9 commits ahead / 0 behind; merge-base equals base SHA; exactly 6 changed files  
**Observed working-tree state:** Connector-only session cannot inspect local `git status`; no destructive local action attempted  
**PR / tracker:** Linear `TNYX-217` In Review; GitHub issue #272; GitHub PR #273 open and Ready for Review  
**Current implementation state:** Physical schema, deferred aggregate integrity, RLS/grant hardening, SQL regression coverage, and Supabase CI wiring are implemented. Repository/UI/parser activation remains deferred.  
**Validation completed at source/test checkpoint:** Supabase Database CI run #51 SUCCESS; complete API scope audit; 0 unresolved GitHub review threads; independent fallback source/test review found no new P1/P2 finding.  
**Codex review status:** requested review did not execute because the Codex code-review usage limit was reached.  
**Validation remaining after this governance-only commit:** verify the resulting exact HEAD is still 0 behind, confirm the expected 6-file scope plus this same task-brief update only, confirm required CI/check state, then merge only under the owner's explicit authorization.  
**Current blocker:** none if exact-head gates remain green.  
**Open review finding IDs:** none.

## 1. Discovery

### User Outcome

Persist canonical `MealLogEntry.detailed(...)` history without weakening manual history, bypassing optimistic-revision semantics, or creating a second authoritative nutrition truth.

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

## 2. Verified Architecture

Parent invariant:

```text
meal_log_entries.mode: manual | detailed
manual   => manual_nutrition_snapshot IS NOT NULL
detailed => manual_nutrition_snapshot IS NULL
```

Child shape:

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
- Trigger helpers are `SECURITY INVOKER` with an empty search path.

Access:

```text
anon          => no child-table privileges
authenticated => SELECT only + owner RLS
service_role  => SELECT / INSERT / UPDATE / DELETE
```

Authenticated INSERT/UPDATE/DELETE RLS policies remain defined but dormant behind table grants. The next atomic repository/RPC slice must explicitly establish its write boundary and parent `revision` semantics.

## 3. Implementation

- [x] Exact table/column shape approved.
- [x] Apply `20260917083552_add_detailed_meal_log_persistence`.
- [x] Apply `20260917083919_tighten_detailed_meal_log_item_grants`.
- [x] Verify columns, constraints, trigger deferrability, RLS, policies, grants and existing manual rows.
- [x] Add focused SQL regression matrix `tnyx_217_detailed_meal_log_persistence.test.sql`.
- [x] Update legacy manual persistence matrix for the mode-coupled nullable parent column.
- [x] Wire the TNYX-217 SQL matrix into `supabase-db-ci.yml`.
- [x] Exercise rollback-only aggregate invariant and ownership tests.
- [x] Run security/performance advisor checks and isolate task-relevant findings.
- [x] Open PR #273 and perform exact source/test checkpoint review.

## 4. Quality Review

Live/post-migration evidence recorded for this slice:

```text
existing parent rows: 8
existing parent modes: manual = 8
new child rows: 0
manual_nutrition_snapshot nullable: YES
child RLS: enabled
constraint triggers: DEFERRABLE INITIALLY DEFERRED
```

Behavioral checks recorded as passing:

```text
atomic detailed parent + child
existing manual create/update DB boundary
owner/non-owner child read isolation
empty detailed parent rejection
manual parent + detailed child rejection
infinite quantity rejection
last-child deletion rejection
parent delete cascade
```

Final grants verified:

```text
authenticated: SELECT=true, INSERT=false, UPDATE=false, DELETE=false
anon: no child-table DML
service_role: SELECT/INSERT/UPDATE/DELETE
```

Source/test checkpoint review on `216a353a122ee3e0b446c0710dd3d046025d15f6`:

- base/merge-base `7ecdd6c572083a869b095b5c138607eaa504a711`;
- 9 ahead / 0 behind;
- exactly 6 scoped files;
- Supabase Database CI run #51 SUCCESS;
- 0 unresolved review threads;
- independent fallback review found no new P1/P2 finding;
- requested Codex review did not execute because the code-review usage limit was reached.

Local `git diff --check` and local working-tree cleanliness cannot be truthfully claimed from this connector-only session. GitHub API ancestry, commit, changed-file and CI evidence are used under `docs/PUSH_TEMPLATE.md`.

### Review Findings

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| T217-P1 | P1 | Resolved | Exact table/column shape required owner approval. | Owner approved exact V1 shape on 2026-09-17. |
| T217-RF1 | P1 | Resolved | Full authenticated child DML could bypass parent `revision` semantics. | Grant-hardening migration leaves authenticated clients SELECT-only until the atomic write boundary lands. |

No open P1/P2 finding remains at the source/test review checkpoint.

## 5. Final Handoff

### Changed Files at Source/Test Checkpoint

1. `.ai/tasks/tnyx-217-detailed-meal-log-physical-persistence.md`
2. `.github/workflows/supabase-db-ci.yml`
3. `supabase/migrations/20260917083552_add_detailed_meal_log_persistence.sql`
4. `supabase/migrations/20260917083919_tighten_detailed_meal_log_item_grants.sql`
5. `supabase/tests/database/tnyx_194_manual_meal_log_entries.test.sql`
6. `supabase/tests/database/tnyx_217_detailed_meal_log_persistence.test.sql`

### Actual Behavior

Supabase can represent canonical detailed MealLog aggregates with ordered consumed item snapshots and DB-enforced committed-state integrity. Existing manual history remains valid. Direct authenticated child mutation is intentionally not activated.

### Known Limitations / Next Bounded Slice

After merge and `docs/POST_MERGE_SYNC.md` reconciliation, perform a fresh audit for:

```text
detailed MealLog repository
+ atomic create/read decoding
+ idempotency / parent revision boundary
```

Do not activate Meal Editor final save or `TNYX-207` parser flow in this slice.

### Final Status

`REVIEW` — implementation/source review is clean at the recorded checkpoint. This governance-only refresh must receive an exact-head gate check before the owner-authorized merge is executed.
