# #568 — Dormant programless first-Routine pending/UNKNOWN gate

**Status:** In Review / documentary P2 reconciliation (2026-10-21). At reviewed PR HEAD `48793678c79a87289f4d756fec7b4af1407becd6`, Flutter CI 5/5 SUCCESS, attribution SUCCESS and owner-local `git diff --check` PASS; independent `im-tio` review [#5595048802](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595048802) requested this handoff correction, not a code change. Follow-up documentation commit must receive its own current-HEAD checks and independent disposition before merge; production activation stays OFF.
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
**Review owner:** `im-tio`; [exact-HEAD review #5595048802](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595048802) CHANGES_REQUESTED only for documentation/status mismatch, confirmed Flutter CI and no new source correctness defect. This follow-up needs new-HEAD formal re-review.
**Implementation ownership state:** Active on #568 gate docs only; [#641](https://github.com/im-tnyx/tio-world/pull/641) merged independently as `main@9e2956209e986054f6b92fdf633106cbaba0f277`. Both touched separate `.ai/tasks/README.md` rows; preserve #641 content and verify merge compatibility against advanced main before merging #642.
**Ownership transition:** Previous #568 helper PRs #637/#638/#639 are merged, so this uses protected main, not their stale branches.
**Repository state last verified:** GitHub `main@9e2956209e986054f6b92fdf633106cbaba0f277` after #641 squash; #642 still based on earlier `da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79`. GitHub currently describes #642 as mergeable without conflict; fresh post-#641 comparison/approval must precede merge.
**Branch:** `tnyx/issue-568-programless-pending-gate-20261021`.
**HEAD SHA:** Exact pre-handoff-correction reviewed/validated PR HEAD `48793678c79a87289f4d756fec7b4af1407becd6`. This documentation update creates a successor commit: resolve its full SHA from GitHub and independently validate that successor before merge. Historical `31af4081f31c69159987b1561de49c72645c01f8` is the original source+test HEAD.
**Observed working-tree state:** GitHub changes remote only. Owner independently ran read-only PowerShell validation from `G:\projects\Tio-World`; branch and porcelain status before/after were unchanged. Connector did not inspect untracked content, modify the local checkout, or run local Flutter/Dart.
**PR / tracker:** This branch under #568 / TNYX-78; no new issue.
**Current implementation state:** Dormant owner-scoped programless reservation and positive verifier added to existing gate. Existing Program-scoped gate and app runtime entry untouched.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/routines/routine_pending_create_gate.dart`; `apps/features/workout/test/presentation/routine_pending_my_program_create_gate_test.dart`; this task brief and task index.
**Verified validation snapshot (PR HEAD `48793678c79a87289f4d756fec7b4af1407becd6` before this docs correction):** [Flutter CI run `39543902111`](https://github.com/im-tnyx/tio-world/actions/runs/39543902111) completed **SUCCESS, all five jobs** (Analyze Flutter and Dart/test Dart, nutrition-onboarding, app-workout, core-wear, aggregate Analyze and test). [Commit attribution run `39543899467`](https://github.com/im-tnyx/tio-world/actions/runs/39543899467) completed **SUCCESS**. Owner independently ran guarded read-only Windows PowerShell from `G:\projects\Tio-World`: pinned base `da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79`, exact HEAD `48793678c79a87289f4d756fec7b4af1407becd6`, base ancestry and exact four-file allowlist, `git diff --check` **PASS/exit 0**, branch and porcelain working-tree status preserved. The owner supplied this receipt; `im-tio` independently verified GitHub CI metadata but did **not** execute Windows git. Earlier source/test HEAD `31af4081` also passed Flutter CI `39487767044` and attribution `39487766869`. No local Flutter build/test is claimed.
**Validation remaining:** Only **successor documentation commit** current-HEAD CI/checks, scope/whitespace inspection, independent `im-tio` formal APPROVED disposition and current advanced-`main` merge compatibility remain before the owner-controlled merge. Current 48793678 validation is already complete; do not label it pending. Separately scoped first-Routine UI/RPC grant/physical-device release QA remains unauthorized.
**Current blocker:** At PR HEAD `48793678`, [review #5595048802](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595048802) CHANGES_REQUESTED for outdated handoff claims alone (addressed by this checkpoint). A new formal disposition on the successor commit is required. Hosted `create_user_workout_routine_in_my_program` client `EXECUTE=false` and no app callback consumes this gate; no release activation.
**Next exact action:** Verify successor docs commit HEAD and GitHub workflow results; recheck overlap with `main@9e295620`, request independent review of this corrected evidence and merge only after `im-tio` APPROVED and protected gates clear. Check post-merge main and post-merge sync before any new #568 implementation. Do not change client grants or activate feature.

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
- [x] At reviewed PR HEAD `48793678`: [Flutter CI `39543902111`](https://github.com/im-tnyx/tio-world/actions/runs/39543902111) **5/5 SUCCESS**, [attribution `39543899467`](https://github.com/im-tnyx/tio-world/actions/runs/39543899467) **SUCCESS**, owner-provided current-HEAD guarded `git diff --check` **PASS/exit 0** and exact four-file scope; independent [review #5595048802](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595048802) completed (CHANGES_REQUESTED on this stale documentation alone).
- [ ] Successor documentation-only commit: independently confirm its exact-HEAD CI, scope and formal `im-tio` approval before merge.
- [ ] Explicit owner-controlled normal merge after gate closure.

## 5. Quality Review and release guard

**Evidence provenance:** GitHub connector independently verified CI/attribution at original source SHA `31af4081` and subsequently at reviewed PR HEAD `48793678`. Owner separately supplied exact-base/HEAD guarded Windows `git diff --check` **PASS/exit 0** for both snapshots; neither connector nor reviewer ran local git. New commits must be identified and independently checked rather than inheriting a pass; formal independent approval is **not** implied by completed review with CHANGES_REQUESTED.

This slice writes no health or owner data and introduces no client permission. It cannot establish end-to-end RPC behavior, physical-device UX or future five-second Undo. Subsequent programless composer/app-shell integration must use the same session-bound reservation before dispatch and still needs separate grant/release QA.

## 6. Final Handoff

**Current status:** IN REVIEW / DOCUMENTATION P2 RECONCILED IN THIS FOLLOW-UP, NOT MERGED OR RELEASED. At reviewed PR HEAD `48793678`, Flutter CI 5/5 SUCCESS, attribution SUCCESS, and owner-local diff-check PASS; `im-tio` [review #5595048802](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595048802) remained CHANGES_REQUESTED solely on out-of-date task/index statements. Successor docs commit awaits its own CI/independent APPROVED review and advanced-main merge gate. Production Move and direct My Program RPC client permissions remain OFF.
