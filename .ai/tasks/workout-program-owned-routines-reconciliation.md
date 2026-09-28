# Workout Program-owned Routines reconciliation

**Status:** Ready for review
**Owner approval:** 2026-09-28, owner requested audit-first start after approving the Program-owned Routine direction and minimal generated-name creation flow.
**Base:** `main@c0274d03568e0b06c43521918da220bb207c1b89`
**Implementation owner:** current repository agent
**Runtime scope:** None. Planning/canonical docs only.

## Outcome

Lock one pre-implementation contract:

- user-owned Program is the reusable container for one or more user-owned Routines;
- every saved user-owned Routine keeps stable identity but belongs to exactly one user-owned Program;
- Library has no standalone user Routines collection/create action;
- initial Create Program shows a generated non-blank name such as `Program 1` before confirmation and permits rename before OK;
- optional Program/Routine metadata and media are deferred from initial creation;
- scheduling/following remains TrainingPlan-owned.

## Verified evidence

- Root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md` and task governance read before changes.
- Runtime `LibraryPage` currently exposes only Exercises and explicitly capability-gates future sections. No Program/Routine runtime implementation or matching open PR existed at audit start.
- TNYX-78 is In Progress; TNYX-81, TNYX-83 and TNYX-267 were Backlog and still described a standalone Library Routines collection before reconciliation.
- TNYX-259 is Done and explicitly deferred `RoutineId` to W1A3 and `ProgramId` to W1A4.
- Live Supabase audit before this slice found no Program/Routine/Exercise/TrainingPlan persistence tables; only existing workout profile/target tables. No schema change is authorized here.
- Attempt to create a focused Linear child issue failed because the workspace returned `free issue limit exceeded`. Existing trackers are reconciled directly; the GitHub branch intentionally carries no TNYX key so merge cannot auto-complete TNYX-78.

## Scope

- Reconcile TNYX-78, TNYX-81, TNYX-83 and TNYX-267.
- Update ADR-0011, D-020, Module Ownership, Workout/Library/Programs/Routines screen docs and Roadmap.
- Record next domain sequencing without implementing it.

## Non-goals

No Flutter UI/runtime change, Program/Routine entity implementation, repository/data source, Supabase migration/table/column/RLS, Storage bucket/upload, TrainingPlan implementation, Active Workout implementation, or optional metadata editor.

## Decisions

1. Program ownership is structural, not presentation-only.
2. Routine remains a stable entity, not anonymous nested JSON.
3. Generated Program/Routine names are creation-time values, not blank-field fallbacks.
4. Initial Program creation does not require description, image, level, goal, type, duration or schedule.
5. Optional Program/Routine image remains future private Workout media and does not authorize Storage work.
6. TrainingPlan owns user-specific schedule/following state.
7. Next domain implementation must reconcile W1A3/W1A4 ordering because Routine now requires Program ownership; do not implement the old Routine-first deferral mechanically.

## Validation

- GitHub compare against base `c0274d03`: branch is ahead only, behind 0; changed paths are canonical docs plus this task handoff/index, with no runtime or Supabase files.
- Manual scope review confirmed no Flutter production source, migration, RLS, Storage or schema changes.
- Connector-only workspace does not expose a local checkout, so `git diff --check` was not executed locally; PR/CI evidence must be used for repository-side validation.
- Linear TNYX-78/TNYX-81/TNYX-83/TNYX-267 were reconciled to the same Program-owned Routine contract.
- New Linear child creation was attempted and blocked by workspace free issue limit; this limitation is explicit rather than inventing tracker state.

## Handoff

Do not begin Program/Routine runtime or Supabase work until this canonical reconciliation is reviewed/merged. After merge, audit the smallest Program identity/entity foundation slice first, then the Program-owned Routine identity/composition slice.
