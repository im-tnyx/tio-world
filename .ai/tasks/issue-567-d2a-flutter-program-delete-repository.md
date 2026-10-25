# GitHub #567 D2A — Flutter protected Program Delete repository

**Status:** In progress
**Primary owner:** Codex
**Affected platforms:** Flutter `apps/features/workout` data/domain boundary only

## Owner Approval and Scope Boundary

**Trigger:** None — internal implementation subtask of the approved #567 lifecycle slice
**Approval status:** Not required
**Approval evidence:** D1 protected SQL RPC is merged in PR #678; this slice is source-only and remains dormant.
**Approved product/UI/data-shape boundaries:** Add a typed, owner/login-cycle-bound Flutter repository capability for the already-defined D1 RPC.
**Explicit non-changes:** No Program UI, controller/provider wiring, public feature flag activation, hosted migration, GRANT, direct table DELETE, schema change, #569 QA, or production caller.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Independent reviewer after PR creation
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** Git root `G:/projects/Tio-World`; clean `main` before branch creation; base `main@86fd082515c8cb8cc1ded93fb1a59d360c2f4582`
**Branch:** `tnyx/567-d2a-flutter-program-delete-repository`
**HEAD SHA:** `065ca306aa83cab84730c430bec5dcf13aa65ea6`
**Observed working-tree state:** Clean after commit/push; fsmonitor IPC warning only
**Observed uncommitted/dirty files:** None
**PR / tracker:** GitHub #567 OPEN; D1 PR #678 merged; D2A PR #681 OPEN; Linear TNYX-81 and TNYX-267 remain backlog/dependency trackers
**Current implementation state:** Dormant typed repository, gateway, exports and focused tests implemented; D1 brief reconciled
**Relevant execution surface:** `apps/features/workout` repository contracts, Supabase gateway adapter, focused mock-gateway tests, package exports
**Validation completed at SHA:** D2A local formatter, Flutter package analyzer, focused 11-test suite, and `git diff --check` passed at `065ca306aa83cab84730c430bec5dcf13aa65ea6`
**Validation remaining:** GitHub PR #681 checks and independent review; hosted migration/EXECUTE and production/UI gates remain intentionally out of scope
**Current blocker:** None for source-only work; hosted EXECUTE remains intentionally unavailable
**Open review finding IDs:** None yet
**Next exact action:** Await independent review and current PR checks; do not merge or activate production capability.

## 1. Discovery

### User Outcome

Provide the smallest client-side protected repository boundary for the merged D1 RPC while preserving owner/session safety and keeping the capability dormant.

### Success Criteria

- Exact RPC name and parameters are sent once with a complete explicit Routine-ID snapshot and mutation UUID.
- Only the validated JSONB success shape is confirmed.
- Wrong owner, logout/login-cycle change, ACL rejection, stale membership, default protection, malformed response, repeated request, and ambiguous outcomes are typed and tested.
- No UI or production caller can dispatch the capability.

### Scope

Domain contract, Supabase gateway/adapter, exports, focused unit/mock tests, and this task handoff only.

### Non-Goals

No hosted deployment, permission grant, schema/migration edit, Program UI, confirmation flow, controller wiring, feature flag, direct table mutation, or #569 QA.

## 2. Codebase Exploration

### Verified Evidence

- Existing `SupabaseRoutineMoveRepository` and `SupabaseRoutineDeleteRepository` bind frozen owner/login-cycle state, use injected gateways, disable SDK retry for writes, consume one-use targets, and distinguish definite failures from `UNKNOWN` outcomes.
- Existing `ProgramRepository` remains the metadata list/create/rename source; D2A will not extend it with destructive lifecycle semantics.
- `ProgramId` and `RoutineId` validate canonical UUIDs and normalize to lowercase.
- Merged D1 RPC accepts `p_source_program_id`, `p_expected_routine_ids`, `p_client_mutation_id` and returns `deleted_program_id`, nullable `destination_program_id`, and nonnegative `moved_routine_count`.
- D1 migration revokes all client `EXECUTE`; source merge is not hosted activation.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use a separate Program Delete repository capability | Made | Avoids creating a second Program metadata source of truth or widening `ProgramRepository` | Codex |
| Require an immutable complete Routine-ID snapshot | Made | Matches D1 exact-membership CAS and prevents name-based authority | Codex |
| Treat missing/ambiguous source state as `UNKNOWN` | Made | D1 has no durable client receipt; absence cannot prove this request committed | Codex |
| Keep adapter un-wired and dormant | Made | Hosted migration and client EXECUTE grant are absent | Codex |

## 4. Architecture Design

### Chosen Approach

Add a public domain `ProgramDeleteRepository` contract and a data `SupabaseProgramDeleteRepository` backed by an injectable `ProgramDeleteGateway`. A prepared target captures source Program ID, complete Routine snapshot, owner, and login cycle. The gateway sends exactly one non-retrying RPC. Success validates all response fields; definite SQL/Auth/ACL/request rejections map to typed failures; timeout/transport/ambiguous or session-changed outcomes remain `UNKNOWN`.

### Ownership and Data Flow

```text
future approved caller -> ProgramDeleteRepository -> SupabaseProgramDeleteGateway -> dormant D1 RPC
```

No current caller/provider is added in D2A.

### Alternative Rejected

Extending `ProgramRepository` or inferring authority from Program name/list state is rejected because it would blur metadata and destructive lifecycle ownership.

### Failure and Accessibility States

This is a non-UI capability. `unauthorized`, `forbidden`, `notFound`, `defaultProtected`, `staleMembership`, `invalidRequest`, `unavailable`, `malformedData`, `inProgress`, and `UNKNOWN` remain typed for a later approved presentation layer.

## 5. Implementation Plan

- [x] Add typed domain target/result/failure/UNKNOWN contract.
- [x] Add non-retrying Supabase RPC gateway and owner/login-cycle adapter.
- [x] Keep capability absent from production composition and feature activation paths.
- [x] Add focused mock-gateway and SDK-shape tests.
- [x] Run formatter, analyzer, focused tests, and diff checks.
- [x] Update this handoff with exact validation SHA and review state.

## 6. Quality Review

### Validation Run

```text
`G:\dev\flutter-sdk\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed ...` — PASS.

Flutter tool `analyze` for `apps/features/workout` — PASS, `No issues found!`.

Focused Flutter test `test/data/supabase_program_delete_repository_test.dart` — PASS, 11/11.

`git diff --check origin/main...HEAD` — PASS.

Parent-to-head audit — PASS: `origin/main` is an ancestor; one task commit; eight owned files.
```

### Review Provenance

**Review source / link:** Not available yet
**Reviewer / relation to implementer:** Independent review requested through bounded PR handoff
**Diff or commit SHA actually reviewed:** Not available yet
**Independent review?:** Unknown / unavailable
**Limitations and unmet required gates:** Hosted migration/EXECUTE and device/UI gates remain intentionally unmet.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/issue-567-d1-atomic-program-delete.md`
- `.ai/tasks/issue-567-d2a-flutter-program-delete-repository.md`
- `apps/features/workout/lib/src/data/data.dart`
- `apps/features/workout/lib/src/data/repositories/supabase_program_delete_repository.dart`
- `apps/features/workout/lib/src/domain/repositories/program_delete_repository.dart`
- `apps/features/workout/lib/src/domain/repositories/repositories.dart`
- `apps/features/workout/test/data/supabase_program_delete_repository_test.dart`

### Actual Behavior

The repository accepts only an explicit owner/login-cycle-bound Program target and complete Routine-ID snapshot, sends the exact D1 RPC once with SDK retry disabled, validates the three-field JSONB receipt, maps known rejection/permission errors, and freezes definite/ambiguous attempts. A timeout, session change, or malformed success response remains `UNKNOWN`; no source read is treated as proof and no destructive retry is issued.

### Known Limitations

The repository capability is source-only and dormant. It cannot establish hosted permission or production activation.

### Final Status

`REVIEW` — source-only PR #681 is open for independent review and merge-gate evaluation; no merge or production activation.
