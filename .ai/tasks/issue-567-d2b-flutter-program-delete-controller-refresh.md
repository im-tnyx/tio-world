# GitHub #567 D2B — Flutter Program Delete controller/session/refresh

**Status:** In progress
**Primary owner:** Codex
**Affected platforms:** Flutter `apps/features/workout` controller/data orchestration only

## Owner Approval and Scope Boundary

**Trigger:** Internal implementation subtask of the approved #567 lifecycle slice
**Approval status:** Approved by the user-provided D2B task scope
**Approval evidence:** D1 PR #678 and D2A PR #681 are merged; this slice is source-only and remains dormant.
**Approved boundaries:** Add the minimum owner/login-cycle-safe controller orchestration around the merged D2A repository, using the existing versioned Routine read, process-scoped attempt gate, Programs/Routines controllers and refresh signal patterns.
**Explicit non-changes:** No Delete Program UI or confirmation sheet, no production provider/caller activation, no public flag, no migration, GRANT, hosted write, direct table DELETE, schema change, #569/#675 status change, #567 D3, or unrelated refactor.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Independent reviewer after PR creation
**Implementation ownership state:** Source implementation complete; validation/review handoff
**Repository state last verified:** Git root `G:/projects/Tio-World`; clean fresh branch from `origin/main@9e994b29b13e242ebcd6399cc32fecfd5ebe98ac`
**Branch:** `tnyx/567-d2b-flutter-program-delete-controller-refresh`
**HEAD SHA:** `4395fa7e` (`fix(flutter): harden Program Delete dispatch lifecycle`); branch is pushed and PR #688 is open for review
**Observed working-tree state:** Clean; source, handoff and P2-remediation commits are pushed to the tracked branch
**PR / tracker:** GitHub #567 OPEN; D1 #678 merged; D2A #681 merged; D2B PR #688 OPEN; Linear TNYX-81 and TNYX-267 remain Backlog/dependency trackers
**Current implementation state:** D2A repository is merged and dormant. D2B controller, focused tests, feature export and dormant owner/session provider composition are implemented; Codex P2 findings for dispatch-time arbitration, recoverable in-flight conflict and Program-scoped lifecycle are fixed; no production surface injects the controller.
**Next exact action:** Complete independent review of PR #688 at the current exact head; merge only after owner authorization and a clean review gate

## 1. Discovery and Codebase Evidence

- `ProgramDeleteTarget.fromVersionedRoutines` already requires one complete source-Program Routine snapshot, stable `ProgramId`, owner and login cycle, and rejects wrong Program/cycle/duplicate IDs.
- `SupabaseProgramDeleteRepository` already owns the D1 RPC contract, typed definite rejection/UNKNOWN outcomes, session binding and sticky `ProgramDeleteAttemptGate` behavior. D2B must not duplicate those checks or infer success from a missing Program.
- `SupabaseRoutineRepository` implements `RoutineVersionedRenameRepository` and exposes `listVersioned(programId)` with `RoutineMetadataRevision` rows bound to the active login cycle and owner.
- `ProgramsController` owns canonical Program list loading; `ProgramRoutinesController` owns one Program's Routine list and revision snapshots. `ProgramsSurface`/`ProgramDetailPage` already reload through these controllers and `RoutineMoveRefreshSignal` only invalidates reads.
- `RoutinePendingCreateGate` and `RoutineMoveDeleteAttemptGate` provide existing pending-operation and cross-operation arbitration. D2B will consume them as read-only safety evidence and will not create a second gate.
- `apps/app` is the composition root. No D2B production provider/caller is added while the hosted Delete RPC and client EXECUTE permission are absent.

## 2. Architecture Decision

Use a feature-owned `ProgramDeleteController` that:

1. Reads the complete source-Program Routine snapshot through the canonical versioned repository.
2. Captures owner/login cycle and stable source `ProgramId`, rejects `isDefault`, pending/conflicting local operations, incomplete/stale snapshots and session changes.
3. Requires an explicit future caller to pass a confirmed invocation; it never dispatches automatically.
4. Reserves the existing process-scoped `ProgramDeleteAttemptGate` before the D2A repository call and maps preparing/in-flight/confirmed/definitely-rejected/UNKNOWN state explicitly.
5. Reloads canonical Programs and source/destination Routines only after a still-owned, same-cycle attempted write; a refresh is never a success receipt.
6. Leaves the capability unexposed from production composition/UI.

Rejected alternative: extending `ProgramRepository` or making `ProgramsController` own destructive RPC/session state would duplicate Program metadata ownership and blur the existing D2A safety boundary.

## 3. Tests and Validation Plan

- Deterministic controller tests for non-default multi-Routine, empty, renamed default, wrong owner, logout/account switch, pending Create/Move/Edit, stale snapshot, concurrent invocation, definite rejection followed by fresh confirmation, `40003`, timeout/lost ACK/UNKNOWN, success refresh, UNKNOWN refresh without success, and dormant/no-production-caller behavior.
- Run Dart format, Workout/App analyze, focused D2B tests, changed-area regressions, future protected-API compatibility review, and `git diff --check`.
- Record exact branch/head, changed files, review findings, CI and merge readiness only after actual validation.

## 4. Validation Evidence

- Dart format check for the new controller, focused tests and feature export: PASS, no changes.
- Workout package `analyze --no-pub`: PASS, `No issues found!`, exit `0`.
- App package `analyze --no-pub`: PASS, `No issues found!`, exit `0`.
- Focused D2B plus changed-area regression tests (`program_delete_controller_test.dart`, Program/Routine controllers, Program Detail, Library, and D2A repository tests): PASS, `136` tests.
- `git diff --check`: PASS before the P2-remediation commit; changed-area scope remains limited to the six approved paths.
- Focused D2B-only regression suite after P2 remediation: PASS, `15` tests.
- Focused D2B plus changed-area regression tests after P2 remediation: PASS, `139` tests.
- Exact-head Flutter CI run `40191214904`: PASS at `4395fa7e`; app-workout, core-wear, nutrition-onboarding, Dart analysis/tests and the aggregate gate passed.
- Existing `uses-material-design` package warning appeared during Flutter tests; it predates this slice and did not fail the suite.
- Hosted migration, EXECUTE grant, Supabase write QA, Docker-backed local DB tests and device QA: not run; explicitly out of scope.

## 5. Review and Final Handoff

Source commit: `10806e55`; handoff commit: `3cd18faa`; P2-remediation commit/final source head: `4395fa7e`; PR: `https://github.com/im-tnyx/tio-world/pull/688`.

Changed source paths are limited to `apps/app/lib/app/composition/workout_providers.dart`, `apps/features/workout/lib/src/presentation/library/programs/program_delete_controller.dart`, `apps/features/workout/lib/src/presentation/library/programs/programs.dart`, and `apps/features/workout/test/presentation/program_delete_controller_test.dart`. The controller requires a complete versioned owner snapshot, stable non-default `ProgramId`, live owner/login-cycle match, pending-operation clearance, explicit confirmation and a caller-supplied mutation UUID. D2A owns RPC classification and sticky UNKNOWN; D2B never infers success from a missing source and only emits owner/cycle-scoped refresh invalidation.

Production Delete Program remains dormant: no Program UI, confirmation action, shell caller, public flag, hosted migration, client `EXECUTE`, direct table DELETE or #569/#675 change. Exact-head CI is passing. Codex P2 findings are fixed and independently re-reviewable; `im-tio` approval and explicit merge authorization remain pending.

## 6. Handoff Risks

- Hosted Delete RPC is absent and client EXECUTE is not available; any provider/wiring that can dispatch it would violate the dormant boundary.
- A missing source after UNKNOWN cannot prove this request committed; controller refresh must preserve UNKNOWN and sticky retry blocking.
- Existing controller reloads are read authority only; no optimistic Program/Routine deletion or identity reconstruction is permitted.

## 7. Final Handoff

Implementation, P2 remediation and exact-head validation are complete for this slice; review/owner merge gate is pending. #569 hosted R5 QA and #675 human security review remain separate and untouched.
