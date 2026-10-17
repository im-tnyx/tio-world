# #569 M3A — Existing-Owned-Program Move Repository Adapter

**Status:** In progress — bounded Flutter repository and test slice.
**Primary owner:** Workout domain/data implementation (one remote branch).
**Affected platforms:** Flutter Workout feature package; no UI/runtime activation.

## Owner Approval and Scope Boundary

**Trigger:** None — #569 owner-approved Move capability; this is a bounded implementation subtask.
**Approval status:** Approved in #569 and current user instruction (2026-10-17).
**Approval evidence:** GitHub #569, Linear TNYX-81 and user go-next Work request.
**Approved behavior:** Move existing saved Routine to an existing same-owner Program via atomic M1 RPC without duplicating Routine/child IDs.
**Explicit non-changes:** No new database tables/columns, hosted GRANT change, authentication backend, UI geometry, selector or confirmation, +New Program/Create & Move, canonical My Program #568, Delete Program #567, or deployment.

## Active Handoff

- **Planning owner:** GitHub #569; Linear TNYX-81 W4 Backlog (broad scope; blockers retained).
- **Implementation owner:** `tnyx/issue-569-m3-existing-program-move-adapter` only; no parallel implementation.
- **Review owner:** GitHub manual/CI gate.
- **Implementation ownership state:** Active
- **Repository state last verified:** GitHub `main@20c1d21efe1760109b28daffa8990a9e77b4aca0`; 0 open PR at start.
- **Branch:** `tnyx/issue-569-m3-existing-program-move-adapter`
- **HEAD SHA:** Initial `20c1d21efe1760109b28daffa8990a9e77b4aca0`
- **Observed working-tree state:** Local Windows `G:\projects\Tio-World` unavailable to this GitHub connector; owner previously posted clean `main` sync but cannot infer current local edits.
- **PR / tracker:** #569, TNYX-81.
- **Current implementation state:** New optional feature-owned Move repository capability under development, not wired to app.
- **Validation completed at SHA:** None yet.
- **Validation remaining:** Exact-head Flutter workout CI/analyzer and focused tests, PR review.
- **Current blocker:** Hosted `authenticated` Move EXECUTE intentionally revoked; UI adapter+controller/selector must be reviewed before distinct activation.
- **Next exact action:** Implement narrow owner/session/revision-frozen Move repository+RPC gateway and regression tests without enabling UI.

## Discovery, Evidence and Design

GitHub source at the verified SHA: M1 Move RPC `move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)` deployed by owner's Supabase CLI. Hosted Supabase 64/64 migrations applied, `UPDATE(name)` and direct `UPDATE(program_id)` denied, authenticated Move EXECUTE denied, protected Rename available. Runtime `SupabaseRoutineRepository` provides owner/cycle-bound metadata reads and Rename; `RoutineDeleteRepository` supplies separate optional inspect/one-use CAS gateway and process-lifetime uncertain-outcome guard. Existing 3-dot sheet has Move placeholder only. My Program stable owner identity #568 unresolved.

**Chosen:** Follow separate Workout domain/data optional Move capability, not add a direct Program UPDATE. Freeze target at owner-read with source Program/revision/name/account/login cycle. Consume one-use target on RPC dispatch, validate destination differs, require exact numeric ACK expected revision+1 for success. No retries after uncertain errors. Lock per owner/Routine across feature repos with an app-supplied attempt gate and block conflicting unconfirmed revision until a later strictly higher revision read. Transport opt-in RPC `retry(enabled:false)`. Keep outcome exceptions sanitized; no raw provider/health data exposed.

**UI/Design:** No rendered UI changes. App composition will later create one process-lived gate and conditionally pass a Move callback only after separately approved Move EXECUTE grant and destination UX/security integration.

## Quality Review

To be updated with exact source head, CI jobs and tests. No validation has been claimed yet.

## Handoff

**Current:** Repository-only adapter slice. Do not merge on start or grant Move EXECUTE. Continue with app-shell/feature selector as a separate bounded slice after review.
