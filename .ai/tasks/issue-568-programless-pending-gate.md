# #568 — Dormant programless first-Routine pending/UNKNOWN gate

**Status:** In Review — verified checkpoint 2026-10-21. At independently reviewed HEAD `e601f4a1c2c55d123e4aadd59137b4b1b08496a2`, Flutter CI 5/5 SUCCESS, attribution SUCCESS, and owner-run guarded `git diff --check` PASS. Independent `im-tio` [review #5595169992](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595169992) found no code defect but requested correction of stale handoff assertions. This dated checkpoint fixes those assertions; consult the live PR for any subsequent commit's exact-head checks and review disposition. Formal APPROVED is a distinct merge gate; production activation stays OFF.
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
**Review owner:** `im-tio`; [review #5595169992](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595169992) at HEAD `e601f4a1` CHANGES_REQUESTED solely for previously stale handoff statements. CI, local receipt and dormant source correctness accepted. This dated evidence fix does not constitute a formal APPROVED review.
**Implementation ownership state:** Active on #568 handoff only; [#641](https://github.com/im-tnyx/tio-world/pull/641) independently merged as `main@9e2956209e986054f6b92fdf633106cbaba0f277`. Separate `.ai/tasks/README.md` rows preserved; #642 remained GitHub mergeable CLEAN when compared to advanced main. Validate live merge status again before merge.
**Ownership transition:** Previous #568 helper PRs #637/#638/#639 are merged, so this uses protected main, not their stale branches.
**Repository state last verified (2026-10-21):** GitHub `main@9e2956209e986054f6b92fdf633106cbaba0f277` after #641 squash. #642 was 8 commits ahead/1 behind this main, mergeable CLEAN, with exact four-file scope; owner synced local main fast-forward and reported clean working tree. Recheck live PR status before merge.
**Branch:** `tnyx/issue-568-programless-pending-gate-20261021`.
**Last independently reviewed/validated PR HEAD snapshot:** `e601f4a1c2c55d123e4aadd59137b4b1b08496a2` (not a timeless live-branch HEAD assertion). Source/tests were originally committed at `31af4081f31c69159987b1561de49c72645c01f8`. For the **actual current** PR HEAD and checks after documentation commits, read [PR #642](https://github.com/im-tnyx/tio-world/pull/642) and its checks; never inherit validation across SHAs.
**Observed working-tree state:** GitHub changes remote only. Owner independently ran read-only PowerShell validation from `G:\projects\Tio-World`; branch and porcelain status before/after were unchanged. Connector did not inspect untracked content, modify the local checkout, or run local Flutter/Dart.
**PR / tracker:** This branch under #568 / TNYX-78; no new issue.
**Current implementation state:** Dormant owner-scoped programless reservation and positive verifier added to existing gate. Existing Program-scoped gate and app runtime entry untouched.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/routines/routine_pending_create_gate.dart`; `apps/features/workout/test/presentation/routine_pending_my_program_create_gate_test.dart`; this task brief and task index.
**Verified dated evidence at reviewed HEAD `e601f4a1c2c55d123e4aadd59137b4b1b08496a2`:** [Flutter CI #39545979334](https://github.com/im-tnyx/tio-world/actions/runs/39545979334) completed **SUCCESS, all five jobs** (analyzer/test Dart, app-workout, nutrition-onboarding, core-wear, aggregate Analyze and test); [attribution #39545979327](https://github.com/im-tnyx/tio-world/actions/runs/39545979327) **SUCCESS**. Owner executed guarded Windows PowerShell in `G:\projects\Tio-World`: clean `main`, fast-forward to exact `9e2956209e986054f6b92fdf633106cbaba0f277`, fetched PR HEAD `e601f4a1c2c55d123e4aadd59137b4b1b08496a2`, checked exact four changed paths and `git diff --check` **PASS/exit 0** against updated main, final working tree clean. This is **owner-provided local evidence**, not a command run by reviewer/connector; `im-tio` independently verified the GitHub CI. Original source/test HEAD `31af4081` and prior docs HEAD `48793678` also have separate historical success receipts. No local Flutter run claimed.
**Validation/merge requirements:** Evidence at `e601f4a1` is **complete**; no CI, attribution or diff-check is marked pending for that reviewed SHA. At merge time, inspect live PR HEAD/checks and advanced-main compatibility, then require `im-tio` formal APPROVED and applicable repository rules. A later documentation commit is a different SHA and must be checked via the live PR, not by silently reusing this historical receipt. Separately scoped first-Routine UI/RPC grant/physical-device QA remains unauthorized.
**Current blocker (at this 2026-10-21 checkpoint):** Independent [review #5595169992](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595169992) CHANGES_REQUESTED only because this task brief still referenced outdated CI/HEAD work. Statements are reconciled here; an independent GitHub APPROVED review is not yet claimed. Hosted `create_user_workout_routine_in_my_program` client `EXECUTE=false` and no app callback uses the gate; no release activation.
**Next exact action:** Use GitHub [PR #642](https://github.com/im-tnyx/tio-world/pull/642) as live evidence for exact current HEAD, CI/attribution, independent reviewer disposition and mergeability. Merge only after formal `im-tio` APPROVED, applicable head validation and rules; verify resulting main/post-merge sync separately. Do not modify client grants or activate the feature.

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
- [x] At independently reviewed HEAD `e601f4a1`, [Flutter CI #39545979334](https://github.com/im-tnyx/tio-world/actions/runs/39545979334) **5/5 SUCCESS**, [attribution #39545979327](https://github.com/im-tnyx/tio-world/actions/runs/39545979327) **SUCCESS**, owner-supplied guarded exact-HEAD/updated-main `git diff --check` **PASS/exit 0**, exact four-file scope. `im-tio` [review #5595169992](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595169992) completed with **CHANGES_REQUESTED solely for stale handoff**, now reconciled as this dated checkpoint.
- [ ] Formal `im-tio` APPROVED for live PR HEAD and applicable merge gates; use the live PR checks for newer commits, rather than declaring checked historical evidence pending.
- [ ] Explicit owner-controlled normal merge after gate closure.

## 5. Quality Review and release guard

**Evidence provenance:** GitHub connector independently verified CI/attribution at source `31af4081`, earlier docs `48793678`, and later reviewed HEAD `e601f4a1`. Owner separately supplied guarded Windows `git diff --check` **PASS/exit 0** for each corresponding snapshot (at `e601f4a1`, against updated main `9e295620`); neither connector nor reviewer executed local git. The current PR HEAD must always be fetched live after additional commits. Historical CHANGES_REQUESTED review is **not** a formal approval.

This slice writes no health or owner data and introduces no client permission. It cannot establish end-to-end RPC behavior, physical-device UX or future five-second Undo. Subsequent programless composer/app-shell integration must use the same session-bound reservation before dispatch and still needs separate grant/release QA.

## 6. Final Handoff

**Current status (2026-10-21 checkpoint):** IN REVIEW, NOT MERGED/NOT RELEASED. Latest independently reviewed snapshot `e601f4a1` has Flutter CI 5/5 SUCCESS, attribution SUCCESS and owner-local exact-HEAD diff-check PASS against updated main. [Review #5595169992](https://github.com/im-tnyx/tio-world/pull/642#pullrequestreview-5595169992) CHANGES_REQUESTED for stale handoff text fixed here; no source issue reported. Refer to live PR for later commits and approval/merge state, rather than treating this dated handoff as a live status service. Production Move and direct My Program RPC permissions remain OFF.
