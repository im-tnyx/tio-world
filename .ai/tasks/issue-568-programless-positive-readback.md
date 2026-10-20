# GitHub #568 — programless Create positive read-back identity guard

**Status:** In progress
**Primary owner:** Workout domain verification contract
**Affected platforms:** Flutter Workout pure-domain contract and unit tests; no visible UI or hosted writes

## Owner Approval and Scope Boundary

**Trigger:** None. This is an internal verification subtask of owner-approved GitHub #568 direct Library Create Routine → canonical default My Program.
**Approval status:** Within existing #568 scope; user authorized continuation on 2026-10-20.
**Approved behavior:** A lost RPC ACK may only become confirmed through authenticated owner/login-cycle-scoped positive reads of the server-owned `is_default` Program, the same persisted Routine belonging to that Program, and exact mutation/ordered composition.
**Explicit non-changes:** No new Library entry, UI geometry, composer refactor, app-shell provider, RPC grant, Supabase DDL, live writes, Move/Undo activation, automatic replay, or release flag.

## Active Handoff

**Planning owner:** GitHub #568 / Linear TNYX-78. Downstream #569 / TNYX-81.
**Implementation owner:** Connected GitHub session, this read-back contract + tests only.
**Review owner:** Independent GitHub reviewer requested once PR is ready.
**Implementation ownership state:** Active; prior #638 implementation is merged and does not hold these paths.
**Ownership transition:** Prior #638 merged to main `604ff62a949315654fdd927305308c9a1ebe65c7`; new nonoverlapping #568 subtask.
**Repository state last verified:** GitHub remote protected `main@604ff62a949315654fdd927305308c9a1ebe65c7`.
**Branch:** `tnyx/issue-568-programless-positive-readback-20261020`
**HEAD SHA:** Pending final GitHub compare.
**Observed working-tree state:** GitHub API branch; owner's Windows working tree inaccessible/unknown.
**Observed uncommitted/dirty files:** Not inspected locally; no claim.
**PR / tracker:** #568, #569, TNYX-78 In Progress, TNYX-81 Backlog.
**Current implementation state:** Dormant My Program RPC adapter and `Program.isDefault` projection already merged; this slice adds only the positive proof boundary needed for future UNKNOWN reconciliation.
**Relevant execution surface:** `apps/features/workout/lib/src/domain/repositories/my_program_routine_create_repository.dart` and focused existing repository test, plus this handoff/index.
**Validation completed at SHA:** Read-only main/source, 66 hosted migrations; Move, Create+Move and first-Routine RPC authenticated EXECUTE still denied on 2026-10-20. CI for this slice not yet run.
**Validation remaining:** Compare file scope/parent ancestry; exact-PR-head Flutter CI and independent review; owner-local `git diff --check` and device QA before activation.
**Current blocker:** First-Routine grant/UI and full owner-cycle pending controller remain gated. This helper must not be mistaken for a complete user-visible Create flow.
**Open review finding IDs:** None yet.
**Next exact action:** Implement focused read-back helper and negative tests, create review PR, then inspect exact-head validation.

## 1. Discovery

### User Outcome
Prevent the programless first Routine Create from being reported successful based only on a matching Program display name or unrelated/superseded composition.

### Success Criteria
- Require persisted Program with `isDefault=true`, same `RoutineId`, owner Program relation and submitted Routine name.
- Also require exact revision-one mutation and ordered Exercise/Set content via existing `confirmsPersistedRoutine` check.
- A renamed canonical default is accepted; ordinary Program named `My Program` is rejected.
- Other Program, other Routine, renamed/superseded Routine, changed mutation or composition fail closed.
- This helper is positive evidence only. Caller still must enforce owner/login-cycle-authenticated reads.

### Non-Goals
No asynchronous pending state/controller or UI navigation in this subtask; no server/privilege changes.

## 2. Codebase Exploration

- Read root and `apps/features/AGENTS.md`, ADR-0015, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md` and PR template, #568/#569, Linear TNYX-78/TNYX-81.
- Current `MyProgramRoutineCreateCommand.confirmsPersistedRoutine` checks revision/mutation/composition but explicitly does not prove default Program ownership.
- Current canonical `Program` has server-derived `isDefault`; `Routine` holds `programId`.
- Reuse these immutable entities. No duplicate reconciliation model or read service.
- Linear `get_agent_context` returned Tool not found in this session; direct Linear issue retrieval succeeded.

## 3. Clarification

Existing approved identity contract suffices; no additional Owner Approval trigger. Choose a pure predicate, not a new network adapter or UI-specific object.

## 4. Architecture Design

Caller performs owner/login-cycle-verified `ProgramRepository.list`, `RoutineRepository.list` and `RoutineCompositionRepository.read`, then invokes command's positive proof predicate. Negative read does **not** prove rollback; preserve frozen mutation IDs and UNKNOWN state.

## 5. Implementation Plan

- [ ] Add pure positive verification predicate using `Program.isDefault`, `Routine`, and existing composition verification.
- [ ] Add focused positive/negative unit regressions.
- [ ] Inspect exact changed file list and GitHub CI at final PR head.

## 6. Quality Review

**Validation Run:** Not run yet for this branch; no local Flutter SDK/checkout available to this GitHub-connected session.
**Acceptance evidence:** Awaiting exact-head CI.
**Review provenance:** Awaiting independent review; no claimed approval.

## 7. Final Handoff

**Changed files:** Pending.
**Actual behavior:** Pending.
**Known limitations:** This safe helper does not activate the client operation; authenticated EXECUTE remains denied and later controller/app-shell integration is mandatory.
**Final status:** REVIEW pending verification.
