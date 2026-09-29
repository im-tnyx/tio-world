# My Program persistence foundation

**Status:** Validated
**Completion date:** 2026-09-29
**Primary owner:** Workout user-owned Program persistence
**Affected platforms:** Supabase + Flutter Workout data/domain boundaries

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice + Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner said `Go` after the read-only audit proposed the exact minimal `public.user_workout_programs(id, user_id, name, created_at, updated_at)` shape, owner-only RLS, least-privilege authenticated CRUD, and a minimal feature repository persistence adapter with destructive lifecycle semantics deferred.
**Approved product/UI/data-shape boundaries:** Add only `public.user_workout_programs` with `id uuid`, `user_id uuid`, `name text`, `created_at timestamptz`, and `updated_at timestamptz`; enforce user ownership and non-blank names; add the minimum Workout feature repository/data adapter required to list/create/rename user-owned Programs.
**Explicit non-changes:** No Routine persistence or domain implementation; no Program image/Storage; no Tio/Coach authoritative source Program persistence; no provenance/source/revision fields; no TrainingPlan fields; no generated `Program N` naming behavior; no UI/routes/controllers; no archive/soft-delete column; no destructive Program repository operation until lifecycle semantics are separately locked; no future backend/service scaffolding.

## Active Handoff

**Planning owner:** None; task completed.
**Implementation owner:** None; implementation merged.
**Review owner:** Completed.
**Implementation ownership state:** Inactive.
**Repository state:** Program persistence merged via PR #461 as `50cca711e8f617cd8eda3d9be590ef7e2ed33d19`.
**Hosted state:** Live Supabase contains `public.user_workout_programs`; hosted migration identity is `20260929040034_create_user_workout_programs`.
**Validation:** PR exact-head Flutter CI and Supabase Database CI passed before merge; live schema/RLS/grants were verified after deployment.
**Final limitation:** Destructive Program lifecycle API, media, provenance/source persistence, generated naming, UI and TrainingPlan behavior remain separate future slices.

## 1. Discovery

### User Outcome

Persist user-owned My Programs behind the existing Supabase + feature-repository boundary so later Program UI/Routine composition can rely on a canonical owner-safe store.

### Success Criteria

- `user_workout_programs` has exactly the approved five columns.
- Program `id` remains the durable `ProgramId`; `user_id` owns access.
- Names cannot be blank.
- RLS restricts CRUD to the authenticated owner.
- Authenticated grants are limited to SELECT/INSERT/UPDATE/DELETE.
- Feature repository can list, create, and rename Programs without exposing Supabase to presentation.
- No delete/archive API is invented in this slice.

### Scope

Migration, RLS/grants, repository contract, Supabase adapter, and focused tests.

### Non-Goals

Everything listed in Explicit non-changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, canonical Supabase strategy, ADR-0015, live public schema/migrations/RLS, existing Workout repositories.
- Existing pattern to follow: `public.users(id)` is the canonical domain FK root; feature-owned Supabase repositories sit behind domain interfaces; newer owner policies use `(select auth.uid()) = user_id`.
- Tests or validation already present: existing repository unit-test patterns and GitHub Flutter CI; no Program persistence tests exist yet.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Exact five-column table shape | Approved | Owner-approved bounded schema | Owner |
| Hard delete vs archive | Deferred | Lifecycle semantics are not locked | Future slice |
| Source/provenance persistence | Deferred | Separate source/adoption slice | Future slice |

## 4. Architecture Design

### Chosen Approach

`apps/shared` keeps canonical Program identity/entity. Workout feature owns repository and Supabase mapping. Supabase owns durable user rows and RLS.

### Ownership and Data Flow

```text
Future UI -> Controller/Use case -> ProgramRepository -> SupabaseProgramRepository -> public.user_workout_programs
```

### Alternative Rejected

Do not mix authoritative Tio/Coach Programs into the user table; ADR-0015 requires separate physical persistence boundaries.

### Failure and Accessibility States

No UI in this slice. Missing auth must fail writes rather than creating unowned data.

## 5. Implementation Plan

- [ ] Add focused migration with table, constraints, updated_at trigger, RLS, grants and owner policies.
- [ ] Add minimal Program repository interface.
- [ ] Add Supabase adapter with explicit row mapping.
- [ ] Add focused repository tests.
- [ ] Validate exact branch scope and CI.

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

Pending.

### Actual Behavior

Pending.

### Known Limitations

No local checkout in this connector-only session; local commands cannot be claimed.

### Final Status

`VALIDATED`


## Post-merge reconciliation

On 2026-09-29 the repository migration filename was reconciled, without changing its SQL body, from `20260929000001_create_user_workout_programs.sql` to the already-applied hosted identity `20260929040034_create_user_workout_programs.sql`. The migration blob is byte-for-byte unchanged. This is repository lineage repair only, not a second deployment.
