# GitHub #569 — M1 Existing-Program Routine Move (DB)

**Status:** In progress — committed to isolated branch; SQL/runtime validation and independent review pending.
**Primary owner:** GitHub-connected implementation session (single implementation owner).
**Affected platforms:** Supabase Postgres/RLS. No Flutter, Watch, service/API, UI, or deployed database changes.

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product feature slice.
**Approval status:** Approved by owner in GitHub #569 and 2026-10-17 conversation: “Go start @Supabase @Linear @GitHub Follow agent.md” after fresh audit.
**Approved scope:** M1 only: atomic owner-checked move of one persisted Routine between two already persisted owner-owned Programs, preserving its UUID, Exercise/Set child IDs and order. Add one least-privilege RPC, SQL negative tests, review handoff.
**Explicit non-changes:** No Supabase table/column/constraint shape change, no direct client UPDATE(program_id) grant; no canonical My Program resolution (#568), quota numeric ceilings (#554), Create & Move, Program Delete (#567), Flutter provider/3-dot UI activation, UI redesign, production deployment or new services/api.

## Active Handoff

**Planning owner:** GitHub #569; Linear TNYX-81 broader W4 and TNYX-267 W6B.
**Implementation owner:** GitHub-connected implementation session.
**Review owner:** Independent reviewer pending.
**Implementation ownership state:** Active; isolated branch, not deployed.
**Repository state last verified:** 2026-10-17 via GitHub API.
**Branch:** `tnyx/issue-569-m1-existing-program-move-db`
**Base/main HEAD SHA:** `acd74a618234127e675cdedef8f9a0c2d2201ea5`
**Observed working-tree state:** GitHub repository API branch only. Local Windows working tree and `git status -sb` not accessible from this session. No local files modified.
**PR / tracker:** GitHub #569; TNYX-81 remains Backlog; draft review PR pending.
**Relevant execution surface:** `supabase/migrations/` and `supabase/tests/database/`.
**Validation completed:** Live read-only check confirmed 62 migrations, absent Move RPC, protected Routine revision/hash fields, existing atomic Edit/Delete EXECUTE and no authenticated direct UPDATE(program_id). SQL security/advisor baseline inspected. No local SQL execution/psql or CI PASS claimed.
**Validation remaining:** Local/disposable Supabase CLI `supabase migration new` filename/workflow check, full migration replay and SQL test, two-session concurrency (Edit/Move, Move/Move, Delete/Move, Program deletion), security advisor after test deployment, GitHub exact-head review/CI.
**Current blocker:** No local Supabase CLI/psql or hosted disposable database is available inside this connected session; never test destructive fixtures on production.
**Next exact action:** Independent SQL/security review, migration replay + race suite in disposable database, amend findings, and reconcile PR gate before any merge/deploy.

## Verified Discovery

- `AGENTS.md`, `apps/features/AGENTS.md`, canonical architecture/ownership/Supabase docs, `.ai/FEATURE_DEVELOPMENT.md`, task protocol, push/PR templates were read.
- Live Tio-world `ACTIVE_HEALTHY`; 62 applied migrations through `20261016220000`; no Move RPC; existing aggregate `composition_revision`, `last_composition_mutation_id`, `last_routine_update_request_hash`.
- Existing `delete_user_workout_routine` takes account key-share, parent Program key-share, private routine UUID lock and routine row FOR UPDATE. New M1 RPC maintains compatible lock ordering and deterministic ordering of both Program locks.
- Existing Edit checks parent Program ID and revision. A->B->A without revision increment would allow ABA stale edits; M1 bumps aggregate revision on *every* move and overwrites most-recent mutation marker/hash.
- Child Exercises/Sets are keyed to stable Routine UUID and owner, so a parent-only reparent operation preserves composition rather than copying or deleting.
- Supabase Security Advisor before this code lists nine existing callable SECURITY DEFINER functions. After deployment, the new intentional authenticated RPC may be an additional WARN that requires scoped authorization justification, not blanket removal.

## Contract and Failure Semantics

`public.move_user_workout_routine(p_routine_id uuid, p_source_program_id uuid, p_destination_program_id uuid, p_expected_revision bigint, p_client_mutation_id uuid) returns bigint`.

- Signed-in owner only; account + BOTH parent Programs verified and locked; foreign/deleted/missing concealed via P0002; same destination or invalid input 22023.
- UUID identity lock serializes with permanent Delete anti-resurrection; routine row lock serializes with Edit, legacy Rename and composition Save.
- Revision compare-and-swap prevents stale writes and ABA. One transaction updates only the parent Routine's Program, revision and existing protected replay fields; no child modification.
- Frozen exact-request retry returns the same committed revision only if the marker/hash still match, destination is still current, and revision is exactly expected+1. After a different aggregate mutation, never infer success.
- Different same-token requests, stale revisions, unavailable/deleted destination and auth failures fail closed. Unknown-result recovery in future Flutter adapter must re-read authoritative owner/program/revision and NEVER generate a new token automatically.
- Read committed required for visibility after lock waits, matching existing Routine retirement guard.
- No numeric quota invented; #554 policy must be reconciled before full UX release.
- Rejected design: copy Routine into target then delete source; violates stable identity/child reference preservation. Rejected: broad authenticated UPDATE(program_id) permission; bypasses authorization/CAS/atomic retry.

## Implemented Branch Files

- `supabase/migrations/20261017100000_move_user_workout_routine_between_owned_programs.sql`
- `supabase/tests/database/tnyx_569_existing_program_routine_move.test.sql`
- This task brief. No live migration, direct client grants or Flutter Move capability changes.

## Quality and Handoff Status

**Partial / REVIEW:** Source work is committed but not locally executed, not independently reviewed, and not production deployed. Do not claim the Move UX is enabled. The preexisting task-index #526 Slice B status is stale versus verified merged PR #587; that unrelated documentation reconciliation remains its own task.
