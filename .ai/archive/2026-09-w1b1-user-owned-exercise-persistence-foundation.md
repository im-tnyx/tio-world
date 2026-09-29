# W1B1 — User-owned Exercise persistence foundation

**Status:** Validated
**Completion date:** 2026-09-29
**Primary owner:** Workout Exercise capability + Supabase persistence
**Affected platforms:** Phone Workout data layer + Supabase; no visible UI in this slice

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** APPROVED
**Approval evidence:** Owner explicitly approved the exact W1B1 minimum shape in chat on 2026-09-29 with `Go`.
**Approved product/UI/data-shape boundaries:** `public.user_workout_exercises` with exactly `id`, `user_id`, `display_name`, `status`, nullable immutable `based_on_catalog_exercise_id`, `created_at`, `updated_at`; no bundled catalog mirroring and no additional W3D fields in this slice.
**Explicit non-changes:** No live Supabase mutation before merge/deploy approval; no UI, route, Favorites, Folders, Routine composition, instructions, media, Storage, AI/Coach exercise provenance, or WorkoutSession changes.

## Active Handoff

**Planning owner:** Completed
**Implementation owner:** Completed on `tnyx/w1b1-user-exercise-persistence-readiness`
**Review owner:** Codex exact-head review plus manual Supabase security verification
**Implementation ownership state:** Completed
**Repository state last verified:** 2026-09-29 after PR #476 merge and hosted deployment; remote `main@b9ad993ed076d98ec78f79882658b3e345443d2a`
**Branch:** `tnyx/w1b1-user-exercise-persistence-readiness` (merged via PR #476; cleanup remains optional)
**Trackers:** TNYX-78 remains In Progress for broader W1; TNYX-264 remains Backlog for visible W3D Custom Exercise capability
**Current implementation state:** Validated on `main` and deployed to hosted Supabase. Migration `20260929181247_create_user_workout_exercises` is applied live and the repository/live migration ledger is aligned 53 / 53.
**Current blocker:** None for this bounded persistence foundation.
**Next exact action:** None for W1B1. Any visible Custom Exercise UI/editor work remains a separate TNYX-264 slice with fresh audit and owner approval.

## 1. Discovery

W1B0 Program privilege hardening is merged, deployed, verified and archived.

W3A is complete. W3C Favorites, W3D Custom Exercises and W3E Folders all require an approved W1 persistence boundary before their dynamic user data can ship.

Canonical `ExerciseRef` has two variants:
- bundled catalog: stable `ex_*` string;
- user-created: canonical UUID.

Built-in catalog truth remains bundled application content and must not be mirrored into Supabase.

At discovery time, live Supabase had no dynamic Exercise table.

## 2. Why This Foundation Comes First

Favorites, Folders and Routine composition may all reference a user-created Exercise UUID. Without a canonical owner-scoped user Exercise table, those relationship/composition tables cannot enforce or resolve user-created Exercise ownership safely.

This slice therefore establishes only the durable user-created Exercise identity/lifecycle target. It is not the full W3D editor.

## 3. Approved Physical Boundary

### Table

`public.user_workout_exercises`

This table stores only user-owned dynamic Exercises. Bundled `ex_*` catalog Exercises remain outside Supabase.

### Approved columns

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

## 7. Validation

- [x] migration filename generated with pinned Supabase CLI v2.116.0: `20260929181247_create_user_workout_exercises.sql`;
- [x] feature-owned `UserExerciseRepository` contract implemented;
- [x] Supabase user Exercise adapter/gateway implemented;
- [x] focused repository unit tests added;
- [x] approved migration SQL implemented with owner RLS, column-level authenticated grants, immutable lineage, archive-not-delete and server-owned timestamps;
- [x] focused SQL matrix added for grants/RLS and allow/deny paths;
- [x] Supabase Database CI wired to run the focused matrix;
- [x] full migration replay on exact PR head;
- [x] focused SQL matrix pass on exact PR head;
- [x] repository unit tests pass on exact PR head;
- [x] exact-head Flutter + Supabase Database CI pass; current connector did not expose the external required-check/ruleset list, so no unseen-check claim is made;
- [x] security review/advisor delta disposition;
- [x] post-merge owner-run `db push --dry-run` then explicit live push;
- [x] hosted migration/grant/RLS/advisor verification;
- [x] canonical Supabase inventory refresh in the archive follow-up branch;
- [x] task archive only after live verification.

## 8. Quality Review

### Exact-Head PR Validation

PR #476 reviewed head `b741844b48747caa5ec08810b2d4af5d2fae494a`:

- Flutter CI run `36611023104`: PASS (bootstrap, Flutter analyze, Dart analyze, Flutter tests, Dart tests).
- Supabase Database CI run `36611023066`: PASS (full replay, complete ledger, all existing matrices, focused W1B1 matrix, concurrency test, lint-diff).
- Codex exact-head review: “Didn't find any major issues.”
- Unresolved review threads: 0.
- Manual RLS/grant/schema review: no blocker.
- PR #476 squash-merged to `main` as `b9ad993ed076d98ec78f79882658b3e345443d2a`.

### Post-Deploy Validation

Owner-run Supabase CLI v2.116.0:

- `db push --dry-run` reported only `20260929181247_create_user_workout_exercises.sql`;
- live `db push` applied that migration successfully;
- post-push `migration list` shows local/remote `20260929181247` aligned;
- local `main` is clean and matches `origin/main`.

Hosted structural verification confirms:

- `public.user_workout_exercises` exists with RLS enabled;
- exact seven-column approved shape is live;
- PK, owner FK, `(id, user_id)` unique constraint, three CHECK constraints, composite list index, and `updated_at` trigger are live;
- `anon`: no table privileges;
- `authenticated`: table SELECT; column INSERT on `id/user_id/display_name/based_on_catalog_exercise_id`; column UPDATE on `display_name/status`; no DELETE and no table-wide INSERT/UPDATE;
- owner SELECT/INSERT/UPDATE RLS policies are present; no DELETE policy;
- `service_role`: full CRUD;
- migration ledger contains `20260929181247` and is aligned 53 / 53.

Advisor disposition:

- Security Advisor: no `user_workout_exercises`-specific finding. Existing warnings concern unrelated authenticated SECURITY DEFINER RPCs and leaked-password protection.
- Performance Advisor: the only new-table item is INFO `unused_index` for `idx_user_workout_exercises_user_status_created_at`, expected for a newly deployed table with no established workload yet. No corrective schema expansion is justified by this initial observation.
- Existing unrelated Routine FK/index and older RLS-initplan findings remain outside this slice.

The September 2026 Supabase breaking-change review also confirms explicit grants are the correct Data API direction; this migration already uses explicit least-privilege grants.

## 9. Final Handoff

### Actual Behavior

User-created canonical Exercises now have a durable owner-scoped Supabase persistence target. Bundled catalog Exercises remain application-owned content and are not mirrored into Postgres. Authenticated clients can list, create the approved minimum row, rename, and archive; they cannot hard-delete rows or mutate identity, ownership, lineage, or server-owned timestamps.

### Known Limitations

This foundation does not implement visible Custom Exercise UI/editor flows, richer taxonomy/instructions/media, Favorites, Folders, Routine composition, or completed-session snapshots. Those remain separate approved slices.

## 10. Final Status

`PASS / VALIDATED`: PR #476 merged to `main` as `b9ad993ed076d98ec78f79882658b3e345443d2a`, migration `20260929181247_create_user_workout_exercises` deployed successfully, live schema/RLS/grants/advisors verified, and canonical Supabase inventory refreshed. TNYX-78 remains In Progress for broader W1; TNYX-264 remains Backlog for visible W3D work.
