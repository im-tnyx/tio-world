# #568 — Dormant programless first-Routine pending/UNKNOWN gate

**Status:** Implementation staged on remote GitHub branch; exact-head Flutter CI, independent review and merge authorization pending.
**Primary owner:** Workout feature presentation state, existing `RoutinePendingCreateGate`
**Affected platforms:** Flutter Workout Android/iOS package tests only; no production entry wiring.

## Owner Approval and Scope Boundary

**Trigger:** None; internal pending/UNKNOWN reconciliation required by already approved GitHub #568 / W1 first direct Library Create Routine flow.
**Approval status:** Within existing approved #568; user directed next remote-only task after 2026-10-20 audit.
**Approved behavior:** Preserve the immutable first-Routine RPC command across auth/login-cycle switches and lost ACK. Only owner/login-cycle-scoped reads establishing one `Program.isDefault`, the exact Routine/name and revision-one composition mutation may release UNKNOWN.
**Explicit non-changes:** No active Library navigation or Create composer wiring; no Program placeholder, extra client Program INSERT, Supabase migration/DDL/RLS/EXECUTE, production Move/Undo, preview flag, visual change or hosted write.

## Active Handoff

**Planning owner:** [GitHub #568](https://github.com/im-tnyx/tio-world/issues/568) / [Linear TNYX-78](https://linear.app/tnyx/issue/TNYX-78) In Progress; downstream [#569](https://github.com/im-tnyx/tio-world/issues/569) / TNYX-81 Backlog.
**Implementation owner:** GitHub-connected session, exclusive to this gate/test subtask and its own documentation brief.
**Review owner:** Independent `im-tio` reviewer requested after PR creation.
**Implementation ownership state:** Active; no overlap with open PR #641's #569-only documentation paths.
**Ownership transition:** Previous #568 helper PRs #637/#638/#639 are merged, so this uses protected main, not their stale branches.
**Repository state last verified:** Remote `main@da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79`; no owner Windows checkout inspection.
**Branch:** `tnyx/issue-568-programless-pending-gate-20261021`.
**HEAD SHA:** Obtain exact live branch commit from GitHub after final index update.
**Observed working-tree state:** GitHub remote only; local `G:\projects\Tio-World` and untracked files not inspected or changed.
**PR / tracker:** This branch under #568 / TNYX-78; no new issue.
**Current implementation state:** Dormant owner-scoped programless reservation and positive verifier added to existing gate. Existing Program-scoped gate and app runtime entry untouched.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/routines/routine_pending_create_gate.dart`; `apps/features/workout/test/presentation/routine_pending_my_program_create_gate_test.dart`; this task brief and task index.
**Validation completed:** Read-only source and GitHub refs, feature ownership, previous merged helper and RPC contract; local compile/analyze/test not run.
**Validation remaining:** GitHub exact-head Flutter CI, full compare diff/whitespace inspection, independent code/security review, owner merge direction and later separately gated physical QA.
**Current blocker:** Hosted `create_user_workout_routine_in_my_program` client `EXECUTE=false` by design; no current app callback uses this gate. No production release possible from this change.
**Next exact action:** Verify current branch diff and CI; submit to `im-tio` for independent exact-head review. Hold merge pending explicit owner direction.

## 1. Discovery

### User Outcome

Prevent a lost first-Routine ACK from starting a second default Program/Routine Create, or reporting an unverified Save as completed. Preserve privacy through account switches.

### Success Criteria

- Freeze one programless first-Routine command per owner, without requiring an invented ProgramId.
- A different command cannot replace/clear the pending identity; a definite rejection can clear only its original command across cycles.
- Read-only verification binds owner and login cycle before/after each asynchronous owner-scoped query.
- Reject zero/multiple default Programs, display-name lookalikes, incorrect Routine ID/Program/name, missing or mismatched snapshot name/mutation/revision/composition.
- Negative or failed reads never clear UNKNOWN or auto-dispatch another RPC.
- Normal Program-scoped Create semantics remain unchanged.

### Non-Goals

No user-visible Create entry, provider/route wiring, backend grant, new domain model or UI styling.

## 2. Codebase Exploration

- Read root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, repo push/PR templates, ADR-0015, Workout ownership docs, GitHub #568/#569 and Linear W1/W4.
- Existing `RoutinePendingCreateGate` retains `RoutineCreateCommand` by owner and ProgramId; direct first-Routine command has *no* ProgramId.
- Merged #637 exposes `MyProgramRoutineCreateCommand` and single-RPC adapter; #638 canonical `Program.isDefault`; #639 pure `confirmsPersistedInCanonicalDefault` predicate.
- Existing `ProgramRepository.list`, `RoutineRepository.list` and `RoutineCompositionRepository.read` supply owner-scoped read contracts. Callers must ensure authenticated SDK owner/login-cycle matches all repositories.

## 3. Clarification and design

Reuse the same `RoutinePendingCreateGate` session binding but keep a separate private owner-keyed programless map. This avoids passing synthetic IDs or changing existing Program-owned Create behavior. Prefer a read-only `verifyMyProgram` against immutable command identity. Do not store fetched Program/Routine content across accounts.

Rejected: introduce a second global provider or a fabricated canonical `ProgramId`. Neither is authorized or needed.

## 4. Implementation and test plan

- [x] Add programless `retainMyProgram`, boolean pending queries and exact instance-based release/definite release.
- [x] Add positive default Program + Routine + composition read-back with auth/session checks between awaits.
- [x] Add focused regressions for zero/default-lookalike, renamed default, missing/wrong name/mutation/revision, duplicate defaults, account A→B→A, auth-switch during read, exact definite rejection and no implicit second Create.
- [ ] GitHub CI test/analyzer validation on exact HEAD.
- [ ] Independent code/security review and review finding disposition.
- [ ] Explicit owner merge authorization.

## 5. Quality Review and release guard

No local Flutter/Dart/`git diff --check` commands have run through the GitHub connector. Do not claim success from a committed test source or from earlier PR CI. GitHub compare can independently confirm changed-file scope and patch whitespace but does not substitute for a locally executed `git diff --check` if required by independent review.

This slice writes no health or owner data and introduces no client permission. It cannot establish end-to-end RPC behavior, physical-device UX or future five-second Undo. Subsequent programless composer/app-shell integration must use the same session-bound reservation before dispatch and still needs separate grant/release QA.

## 6. Final Handoff

**Current status:** REMOTE IMPLEMENTATION / REVIEW GATE, NOT MERGED, NOT RELEASED. Capture verified SHA, CI, review and scope evidence in PR discussion before merge. Production Move and direct My Program RPC permissions remain OFF.
