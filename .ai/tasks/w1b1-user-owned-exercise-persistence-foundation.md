# W1B1 — User-owned Exercise persistence foundation

**Status:** In progress
**Primary owner:** Workout Exercise capability + Supabase persistence
**Affected platforms:** Phone Workout data layer + Supabase; no visible UI in this slice

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** APPROVED
**Approval evidence:** Owner explicitly approved the exact W1B1 minimum shape in chat on 2026-09-29 with `Go`.
**Approved product/UI/data-shape boundaries:** `public.user_workout_exercises` with exactly `id`, `user_id`, `display_name`, `status`, nullable immutable `based_on_catalog_exercise_id`, `created_at`, `updated_at`; no bundled catalog mirroring and no additional W3D fields in this slice.
**Explicit non-changes until approval:** No migration, live Supabase mutation, repository implementation, UI, route, Favorites, Folders, Routine composition, instructions, media, Storage, AI/Coach exercise provenance, or WorkoutSession changes.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Current repository agent
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Repository state last verified:** 2026-09-29, `main@50b74fd5c48c1f41d1a24806e259a45ead483e06`
**Branch:** `tnyx/w1b1-user-exercise-persistence-readiness`
**Trackers:** TNYX-78 (W1) and TNYX-264 (W3D)
**Current blocker:** Migration filename must be generated with the repository-pinned Supabase CLI before the migration file can be added. Source/repository work that does not require the filename may proceed.
**Next exact action:** Implement the approved repository/data contract and tests, then generate the migration filename with the pinned Supabase CLI and add the locked table/RLS/grant SQL + focused DB matrix.

## 1. Discovery

W1B0 Program privilege hardening is merged, deployed, verified and archived.

W3A is complete. W3C Favorites, W3D Custom Exercises and W3E Folders all require an approved W1 persistence boundary before their dynamic user data can ship.

Canonical `ExerciseRef` has two variants:
- bundled catalog: stable `ex_*` string;
- user-created: canonical UUID.

Built-in catalog truth remains bundled application content and must not be mirrored into Supabase.

Live Supabase currently has no dynamic Exercise table.

## 2. Why This Foundation Comes First

Favorites, Folders and Routine composition may all reference a user-created Exercise UUID. Without a canonical owner-scoped user Exercise table, those relationship/composition tables cannot enforce or resolve user-created Exercise ownership safely.

This slice therefore establishes only the durable user-created Exercise identity/lifecycle target. It is not the full W3D editor.

## 3. Proposed Physical Boundary — OWNER APPROVAL REQUIRED

### Table

`public.user_workout_exercises`

This table stores only user-owned dynamic Exercises. Bundled `ex_*` catalog Exercises remain outside Supabase.

### Proposed columns

| Column | Type | Null | Default | Contract |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | canonical `UserCreatedExerciseRef` |
| `user_id` | `uuid` | no | none | owner; FK to `public.users(id)` |
| `display_name` | `text` | no | none | nonblank user-visible name |
| `status` | `text` | no | `'active'` | `active | archived` |
| `based_on_catalog_exercise_id` | `text` | yes | null | immutable optional lineage to a bundled `ex_*` Exercise |
| `created_at` | `timestamptz` | no | UTC now | server-owned audit timestamp |
| `updated_at` | `timestamptz` | no | UTC now | trigger-maintained audit timestamp |

### Constraints

- PK: `id`
- FK: `user_id -> public.users(id) on delete cascade`
- UNIQUE: `(id, user_id)` for future owner-safe composite references
- CHECK: `btrim(display_name) <> ''`
- CHECK: `status in ('active','archived')`
- CHECK: `based_on_catalog_exercise_id is null OR based_on_catalog_exercise_id ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'`

### Index

`(user_id, status, created_at desc)`

This supports owner list/custom-smart-view reads without adding speculative taxonomy indexes.

## 4. Data API / RLS Boundary

RLS enabled.

`anon`: no privileges.

`authenticated`:
- SELECT
- INSERT only the client-owned create columns needed for a new row
- UPDATE only `display_name` and `status`
- no DELETE

`service_role`: full CRUD; server-side only.

Owner policies:
- SELECT own
- INSERT own
- UPDATE own with both USING and WITH CHECK
- no DELETE policy

Archive is the lifecycle operation. Hard delete is intentionally not exposed to authenticated clients.

`based_on_catalog_exercise_id` is immutable after insert so provenance cannot be silently rewritten.

## 5. Repository Boundary

Feature-owned repository/data source lives under `apps/features/workout/lib/src/{domain,data}/exercises/`.

It returns the existing canonical `Exercise` read model with:
- `ExerciseRef.userCreated(id)`
- `displayName`
- `status`
- all currently unpersisted taxonomy fields empty/null
- `media = null`

A separate competing `CustomExercise` canonical entity must not be introduced.

The first repository slice needs owner-scoped:
- list active/all user Exercises;
- create minimal user Exercise;
- rename;
- archive.

Exact provenance read-wrapper/API can be added only if the consuming W3D fork/edit slice needs to display lineage. The physical lineage column is established now because TNYX-264 already requires it.

## 6. Explicit Deferrals

Do NOT add in this foundation:

- `muscle_group`
- `primary_muscles`
- `secondary_muscles`
- `primary_equipment`
- `category`
- `levels`
- instructions/notes
- media / Storage
- AI/Coach exercise provenance
- visibility/access fields
- Favorites
- Folders
- Routine composition
- completed-session snapshots

Reason: these fields are not required to establish stable user-created Exercise identity/lifecycle, and several still need concrete W3D/W3B product decisions. Adding them now would pre-authorize speculative schema.

## 7. Validation Required After Approval

- migration filename generated with pinned Supabase CLI; never invented;
- full migration replay;
- focused SQL matrix for grants/RLS and allow/deny paths;
- repository unit tests;
- exact-head repository CI;
- post-merge owner-run `db push --dry-run` then explicit live push;
- hosted migration/grant/RLS/advisor verification;
- canonical Supabase inventory refresh;
- task archive only after live verification.

## 8. Current Audit Findings

- W3A: Done.
- No `user_workout_exercises` or equivalent table exists live.
- No Custom Exercise repository/data source exists.
- Existing `Exercise` can validly represent a minimal user-created Exercise with optional taxonomy empty/null.
- `ExerciseStatus.active/archived` already provides the required non-destructive lifecycle contract.
- `ExerciseRef.userCreated` already locks UUID identity.
- Bundled catalog IDs already have a stable `ex_*` syntax contract.
- Current Supabase guidance requires both least-privilege grants and RLS on exposed tables; column privileges can narrow update capabilities.
- Existing Program/Routine owner-RLS pattern uses `(select auth.uid()) = user_id`.

## 9. Final Status

`IN PROGRESS / OWNER-APPROVED / MIGRATION FILENAME PENDING`
