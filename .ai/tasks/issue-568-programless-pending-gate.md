# #568 — Dormant programless first-Routine pending/UNKNOWN gate

**Status:** In Review — 2026-10-21 verified source HEAD `31af4081f31c69159987b1561de49c72645c01f8` Flutter CI 5/5 SUCCESS; independent `im-tio` source review completed with documentation-handoff P2 still open. This documentation correction requires fresh-head CI/re-review; merge and activation not authorized.
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
**Review owner:** `im-tio` performed independent exact-source-HEAD reviews; latest [review `5594916090`](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5594916090) requests changes solely for stale validation handoff, without a new code correctness finding. Fresh docs-HEAD review remains required.
**Implementation ownership state:** Active; no overlap with open PR #641's #569-only documentation paths.
**Ownership transition:** Previous #568 helper PRs #637/#638/#639 are merged, so this uses protected main, not their stale branches.
**Repository state last verified:** Remote `main@da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79`; no owner Windows checkout inspection.
**Branch:** `tnyx/issue-568-programless-pending-gate-20261021`.
**HEAD SHA:** Last CI-validated SOURCE HEAD `31af4081f31c69159987b1561de49c72645c01f8`; current branch HEAD must be read live after this docs-only update, and CI/review reconfirmed at that new SHA.
**Observed working-tree state:** GitHub changes remote only. Owner independently ran read-only PowerShell validation from `G:\projects\Tio-World`; branch and porcelain status before/after were unchanged. Connector did not inspect untracked content, modify the local checkout, or run local Flutter/Dart.
**PR / tracker:** This branch under #568 / TNYX-78; no new issue.
**Current implementation state:** Dormant owner-scoped programless reservation and positive verifier added to existing gate. Existing Program-scoped gate and app runtime entry untouched.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/routines/routine_pending_create_gate.dart`; `apps/features/workout/test/presentation/routine_pending_my_program_create_gate_test.dart`; this task brief and task index.
**Validation completed at source SHA `31af4081f31c69159987b1561de49c72645c01f8`:** GitHub [Flutter CI `39487767044`](https://github.com/im-tnyx/tio-world/actions/runs/39487767044) completed SUCCESS (five successful jobs: Analyze Flutter and Dart/test Dart, nutrition-onboarding, app-workout, core-wear, aggregate Analyze and test); [attribution `39487766869`](https://github.com/im-tnyx/tio-world/actions/runs/39487766869) SUCCESS. Owner-provided Windows guarded `git diff --check` PASS / exit 0 for exact `main@da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79...31af4081f31c69159987b1561de49c72645c01f8`, exactly four reviewed paths; reviewer independently retrieved CI, not the owner-local command. No local Flutter run claimed.
**Validation remaining:** New docs-only HEAD requires fresh GitHub exact-head CI/checks, compare and whitespace inspection, independent `im-tio` re-review/explicit approval of handoff P2, and owner-controlled normal merge. Separately gated first-Routine activation/physical-device QA is not authorized by this PR.
**Current blocker:** Latest independent [review `5594916090`](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5594916090) was CHANGES_REQUESTED for stale task/index evidence only. Hosted `create_user_workout_routine_in_my_program` client `EXECUTE=false` by design; no current app callback consumes this gate. Neither merger nor release activation is yet verified.
**Next exact action:** Verify new docs-only commit SHA, scope/CI and branch checks; request `im-tio` re-review of reconciled handoff. Hold merge for independent formal approval and current protected-branch requirements; separately verify post-merge `main` before continuing #568.

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
- [x] GitHub [Flutter CI `39487767044`](https://github.com/im-tnyx/tio-world/actions/runs/39487767044) 5/5 SUCCESS and [attribution `39487766869`](https://github.com/im-tnyx/tio-world/actions/runs/39487766869) SUCCESS at original source HEAD `31af4081`.
- [x] Owner-provided guarded exact-base/source-HEAD `git diff --check` exit 0 and four-file scope receipt, separate from independent CI verification.
- [x] Independent `im-tio` code review performed; no concrete code P2, handoff P2 identified at [review `5594916090`](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5594916090).
- [ ] Reconfirm checks/CI and clean diff on new docs-only PR HEAD; obtain independent re-review resolving handoff P2.
- [ ] Explicit owner-controlled normal merge after gate closure.

## 5. Quality Review and release guard

**Evidence provenance:** GitHub connector independently read exact source-HEAD Flutter and attribution workflow results. Separately, the owner executed guarded Windows PowerShell `git diff --check` (exit 0) against the exact pre-documentation base/head and supplied the successful transcript; the connector did not execute that local command. New docs commits invalidate literal *current-head* CI/diff-check claims until re-verified. Neither the earlier independent code review nor the local receipt is an `APPROVED` review for a new HEAD.

This slice writes no health or owner data and introduces no client permission. It cannot establish end-to-end RPC behavior, physical-device UX or future five-second Undo. Subsequent programless composer/app-shell integration must use the same session-bound reservation before dispatch and still needs separate grant/release QA.

## 6. Final Handoff

**Current status:** IN REVIEW / HANDOFF P2 FIX STAGED, NOT MERGED, NOT RELEASED. Source HEAD `31af4081` Flutter CI/attribution PASS and owner-local diff-check receipt PASS; latest independent review CHANGES_REQUESTED due to stale documentation (this correction). New doc HEAD requires exact-head CI/re-review; explicit owner merge gate still applies. Production Move and direct My Program RPC permissions remain OFF.
