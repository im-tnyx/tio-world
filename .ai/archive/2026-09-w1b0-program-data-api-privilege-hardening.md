# W1B0 — Program Data API privilege hardening

**Status:** Validated
**Completion date:** 2026-09-29
**Primary owner:** Supabase Workout persistence + `apps/features/workout`
**Affected platforms:** Supabase Postgres/Data API; no visible client behavior change

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** This is an internal RLS/grant/security-correctness subtask inside the already-approved TNYX-78 W1 persistence scope. It does not introduce a new product capability, visible UI/UX change, or Supabase table/column shape change.
**Approved product/UI/data-shape boundaries:** Preserve the existing `public.user_workout_programs` five-column shape and owner RLS while reducing authenticated client privileges to the actual Program repository contract: SELECT, INSERT, and UPDATE of `name` only.
**Explicit non-changes:** No table/column/constraint/FK/index shape changes; no Program delete/archive product semantics; no ProgramRepository delete/archive API; no Routine changes; no composition/provenance/media/TrainingPlan/WorkoutSession persistence; no UI/routes/controllers; no live deployment from this connector-only session.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Completed on `tnyx/tnyx-78-w1b0-program-privilege-hardening`
**Review owner:** Manual Codex-style review because automated Codex code-review quota is exhausted
**Implementation ownership state:** Completed
**Repository state last verified:** 2026-09-29 after PR #473 merge and hosted deployment; remote `main@69290bd33b104e6633241903a6325f65b5c36e98`
**Branch:** `tnyx/tnyx-78-w1b0-program-privilege-hardening` (merged; branch cleanup not requested)
**Tracker:** TNYX-78 remains In Progress; no focused W1B0 child exists.
**Current implementation state:** Validated on `main` and deployed to hosted Supabase. PR #473 merged as `69290bd33b104e6633241903a6325f65b5c36e98`; migration `20260929133232_harden_user_workout_program_privileges` is applied live. Authenticated Program access is now SELECT/INSERT + `UPDATE(name)` only, with no DELETE or table-wide UPDATE.
**Current blocker:** None for this validated slice. TNYX-78 remains `In Progress` because broader W1 acceptance is still incomplete.
**Next exact action:** None for this slice. Any next W1B0 persistence decision must start from fresh `main`, live Supabase, and current TNYX-78/W3 evidence.

## 1. Discovery

### User Outcome

Keep the current Program list/create/rename runtime intact while preventing authenticated Data API clients from mutating Program identity/ownership/timestamps or deleting Program rows before lifecycle semantics are deliberately implemented.

### Success Criteria

- Existing `public.user_workout_programs` table/columns remain unchanged.
- Existing owner SELECT/INSERT/UPDATE RLS remains owner-scoped.
- Authenticated role keeps SELECT and INSERT.
- Authenticated UPDATE is narrowed from table-wide UPDATE to column-level `UPDATE(name)`.
- Authenticated DELETE privilege is removed.
- `user_workout_programs_delete_own` policy is removed because destructive Program lifecycle remains deferred.
- `ProgramRepository` remains list/create/rename only.
- Program create/list/rename behavior continues to work.
- A focused SQL matrix proves rename allowed, ID/owner/timestamp updates denied, and direct delete denied.
- Supabase Database CI passes on the exact PR head.

### Why This Is Next

W1A3 is merged and archived. W3C Favorites, W3D Custom Exercises and W3E Folders all depend on the broader W1B0 persistence decision. Before adding more Workout dynamic tables, current Program/Routine Data API capability should be internally consistent and least-privilege.

The live Routine table already follows the desired pattern: SELECT + INSERT + column-level UPDATE(name), no authenticated DELETE. The Program table still exposes table-wide UPDATE and DELETE from its earlier persistence foundation.

## 2. Codebase Exploration

### Verified Source

- `ProgramRepository` exposes only `list/create/rename`; its source comment explicitly defers destructive lifecycle semantics.
- `RoutineRepository` also exposes only `list/create/rename`.
- `20260929040034_create_user_workout_programs.sql` grants authenticated SELECT/INSERT/UPDATE/DELETE and creates a DELETE policy.
- `20260929050000_create_user_workout_routines.sql` intentionally uses SELECT/INSERT + `UPDATE(name)`, with no authenticated DELETE.
- Archived Program persistence approval deferred destructive Program repository lifecycle.
- Archived Routine persistence explicitly records rename-only/no-delete Data API access as the least-privilege boundary.

### Verified Live Supabase

Project: `tio-world` (`oykupyiitspujzpwwvuj`)

Current Program authenticated privileges:
- SELECT: yes
- INSERT: yes
- table-wide UPDATE: yes
- DELETE: yes
- UPDATE `name`: yes
- UPDATE `id`: yes
- UPDATE `user_id`: yes
- UPDATE `created_at`: yes
- UPDATE `updated_at`: yes

Current Routine authenticated privileges:
- SELECT: yes
- INSERT: yes
- table-wide UPDATE: no
- DELETE: no
- UPDATE `name`: yes
- UPDATE `program_id`: no
- UPDATE `user_id`: no

Program and Routine owner RLS policies use `(select auth.uid()) = user_id`. This is not a cross-user RLS bypass finding; it is a capability/least-privilege mismatch.

Supabase documentation confirms that RLS and SQL grants are separate controls and exposed tables should grant only the permissions each role needs.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Change Program table/column shape | Rejected | No data-shape change is required for this hardening | Architecture |
| Keep owner UPDATE policy | Locked | Needed for rename; grants will limit which column can change | Architecture |
| Narrow authenticated UPDATE to `name` | Locked | Matches ProgramRepository and validated Routine precedent | Architecture |
| Remove authenticated DELETE privilege | Locked | Destructive Program lifecycle is still deferred | Architecture |
| Drop owner DELETE policy | Locked | Avoid exposing a dormant destructive capability surface | Architecture |
| Change service_role privileges | Rejected | Server/admin lifecycle may require them later; no need for this client hardening | Architecture |
| Restrict INSERT to specific columns | Deferred | Routine precedent currently grants table INSERT too; do not silently widen scope | Future W1B0 audit |

## 4. Architecture Design

### Chosen Approach

Forward-only migration:

```text
revoke delete on public.user_workout_programs from authenticated;
revoke update on public.user_workout_programs from authenticated;
grant update (name) on public.user_workout_programs to authenticated;
drop policy if exists user_workout_programs_delete_own
  on public.user_workout_programs;
```

Preserve:
- table shape;
- SELECT/INSERT;
- owner SELECT/INSERT/UPDATE RLS;
- service_role access;
- existing ProgramRepository/SupabaseProgramRepository behavior.

### Rejected Alternative

Do not add delete/archive UI or repository APIs merely because the original table exposed DELETE. Product lifecycle semantics are explicitly deferred.

## 5. Implementation Plan

- [x] Reconcile root/feature AGENTS, W1/W3/W4 tracker state, archived persistence tasks, current runtime source and live Supabase.
- [x] Verify exact live Program/Routine privilege matrix and RLS.
- [x] Lock the minimum forward-only hardening contract.
- [x] Generate migration filename with local Supabase CLI; do not invent it.
- [x] Add migration with only grant/policy hardening.
- [x] Add focused Program privilege SQL matrix.
- [x] Wire the focused matrix into Supabase Database CI.
- [x] Run exact-head Supabase Database CI and applicable repository checks.
- [x] Run live deployment only after merge through the normal owner/local Supabase workflow.
- [x] Verify live grants/policies and advisors after deployment.
- [x] Archive this task after validated merge/deployment reconciliation.

## 6. Quality Review

### Current Audit Result

PASS / VALIDATED. Hosted migration `20260929133232_harden_user_workout_program_privileges` is applied. Live verification confirms RLS remains enabled, authenticated Program access is narrowed as intended, and service_role full CRUD remains intact.

Post-deploy Security Advisor has no Program-specific finding. Existing warnings concern unrelated SECURITY DEFINER RPC exposure and leaked-password protection. Performance Advisor still reports the pre-existing Routine composite-FK index advisory and unrelated RLS/init-plan/unused-index findings; this Program hardening introduced no new Program-specific advisor finding.

### Validation Completed

PR #473 exact reviewed head `0bb17c30d6ea6cb83d7dd1167707b0d767f2374a`:

- Supabase Database CI #88: PASS
- full repository migration replay: PASS
- complete migration ledger: PASS
- TNYX-78 Program privilege hardening SQL matrix: PASS
- existing DB SQL matrices: PASS
- real two-session concurrency test: PASS
- database lint-diff: PASS
- required Commit attribution guard: PASS
- supplemental GitHub Advanced Security: pre-analysis infrastructure failure because the requested model is unsupported; no repository security finding
- automated Codex code review: unavailable because review quota is exhausted
- manual Codex-style security review: no blocker
- PR review threads: 0

### Post-Deploy Validation

Hosted Supabase verification after owner-run `supabase db push`:

- migration ledger includes `20260929133232_harden_user_workout_program_privileges`;
- `authenticated`: SELECT = yes, INSERT = yes, table-wide UPDATE = no, DELETE = no;
- `authenticated` column UPDATE: `name` = yes; `id`, `user_id`, `created_at`, `updated_at` = no;
- Program RLS remains enabled;
- owner policies present: SELECT / INSERT / UPDATE;
- DELETE policy count = 0;
- service_role SELECT / INSERT / UPDATE / DELETE = yes;
- table remains the same five-column shape;
- no new Program-specific Security or Performance Advisor finding.

Reviewed PR head `0bb17c30d6ea6cb83d7dd1167707b0d767f2374a` and squash merge `69290bd33b104e6633241903a6325f65b5c36e98` have the same tree `2774935e9347b1d8a48c4be01cccae4cc779b3ec`.

### Validation Remaining

None for this bounded slice.

## 7. Final Handoff

### Changed Areas

Migration, focused SQL security matrix, Supabase DB CI wiring, and task governance.

### Actual Behavior

Hosted behavior is now live: authenticated Data API clients retain Program SELECT/INSERT and owner-scoped rename while direct Program DELETE and updates to Program identity, ownership, and timestamps are denied.

### Known Limitations

This slice does not decide Routine composition persistence, Favorites/Custom/Folders tables, Program delete/archive UX, source/adoption provenance, TrainingPlan, or WorkoutSession storage.

### Final Status

`PASS / VALIDATED`: PR #473 merged to `main` as `69290bd33b104e6633241903a6325f65b5c36e98`, migration `20260929133232_harden_user_workout_program_privileges` deployed successfully, and live grants/RLS/advisors verified. Parent TNYX-78 remains `In Progress` for broader W1 work.
